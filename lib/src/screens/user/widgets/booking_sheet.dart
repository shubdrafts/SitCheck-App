import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../controllers/restaurant_controller.dart';
import '../../../models/table_slot.dart';
import '../../../services/booking_service.dart';
import '../../../theme/app_colors.dart';
import '../widgets/occupancy_chart.dart';

class BookingSheet extends StatefulWidget {
  const BookingSheet({
    super.key,
    required this.tables,
    required this.restaurantId,
    this.userId,
  });

  final List<TableSlot> tables;
  final String restaurantId;
  final String? userId;

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _bookingService = BookingService();
  late List<TableSlot> _tables;
  final Set<String> _selectedIds = {};

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _guestController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  int _currentStep = 0;
  final DateFormat _dateLabel = DateFormat('EEE, MMM d');

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tables = List.from(widget.tables);
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _guestController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _selectedCount => _selectedIds.length;
  int get _availableCount =>
      _tables.where((t) => t.status == TableStatus.available).length;
  int get _occupiedCount =>
      _tables.where((t) => t.status == TableStatus.occupied).length;
  int get _totalReservedDisplay =>
      _tables.where((t) => t.status == TableStatus.reserved).length +
      _selectedCount;

  void _toggleSelection(TableSlot table) {
    if (table.status != TableStatus.available) return;

    setState(() {
      if (_selectedIds.contains(table.id)) {
        _selectedIds.remove(table.id);
      } else {
        _selectedIds.add(table.id);
      }
    });
  }

  Future<void> _confirmSelection() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one table to continue.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final bookingDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      for (final tableId in _selectedIds) {
        try {
          await _bookingService.createBooking(
            userId: widget.userId,
            restaurantId: widget.restaurantId,
            tableId: tableId,
            guestName: _nameController.text.trim(),
            guestPhone: _phoneController.text.trim(),
            partySize: int.parse(_guestController.text.trim()),
            bookingDateTime: bookingDateTime,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
        } catch (e) {
          // If it's already reserved locally, we assume it's a sync retry and proceed
          // to update the server status.
          if (e.toString().contains('already reserved')) {
            debugPrint('Booking locally exists, proceeding to sync: $e');
            continue;
          }
          rethrow;
        }
      }

      final updatedTables = _tables
          .map(
            (table) => _selectedIds.contains(table.id)
                ? table.copyWith(
                    status: TableStatus.reserved,
                    lastUpdated: DateTime.now(),
                  )
                : table,
          )
          .toList();

      // 3. Refresh restaurant data to reflect changes
      await context.read<RestaurantController>().refreshRestaurant(widget.restaurantId);

      setState(() {
        _tables = updatedTables;
        _selectedIds.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking confirmed and saved successfully')),
        );
        Navigator.of(context).pop({'tables': updatedTables});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  String _formattedTime() {
    final hour =
        _selectedTime.hourOfPeriod == 0 ? 12 : _selectedTime.hourOfPeriod;
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _currentStep == 0
                    ? _buildDetailsStep()
                    : _buildTableSelectionStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Book a table',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    decoration: const InputDecoration(labelText: 'Full name *'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    decoration: const InputDecoration(labelText: 'Phone number *'),
                    validator: (value) {
                      if (value == null || value.trim().length < 10) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _guestController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    decoration: const InputDecoration(labelText: 'Guests *'),
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Enter number of guests';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SelectionTile(
                          label: 'Date',
                          value: _dateLabel.format(_selectedDate),
                          icon: Icons.calendar_month,
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SelectionTile(
                          label: 'Time',
                          value: _formattedTime(),
                          icon: Icons.schedule,
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (_formKey.currentState!.validate()) {
                        setState(() => _currentStep = 1);
                      }
                    },
                    decoration:
                        const InputDecoration(labelText: 'Notes (optional)'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() => _currentStep = 1);
              }
            },
            child: const Text('Select tables'),
          ),
        ),
      ],
    );
  }

  Widget _buildTableSelectionStep() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _currentStep = 0),
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                'Select Tables',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              _StatusCounters(
                available: _availableCount,
                reserved: _totalReservedDisplay,
                occupied: _occupiedCount,
              ),
              const SizedBox(height: 16),
              OccupancyChart(
                available: _availableCount,
                reserved: _totalReservedDisplay,
                occupied: _occupiedCount,
              ),
              const SizedBox(height: 16),
              Text(
                'Tap a table to select it.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: _tables.length,
                  itemBuilder: (context, index) {
                    final table = _tables[index];
                    final isSelected = _selectedIds.contains(table.id);
                    return _TableCell(
                      table: table,
                      isSelected: isSelected,
                      onTap: () => _toggleSelection(table),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  _LegendSwatch(color: AppColors.green, label: 'Available'),
                  _LegendSwatch(
                    color: AppColors.yellow,
                    label: 'Selected / Reserved',
                    darkText: true,
                  ),
                  _LegendSwatch(color: AppColors.red, label: 'Occupied'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _confirmSelection,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.event_available),
            label: Text(
              _isProcessing
                  ? 'Processing...'
                  : _selectedCount == 0
                      ? 'Select tables'
                      : 'Confirm booking ($_selectedCount selected)',
            ),
          ),
        ),
      ],
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    required this.table,
    required this.isSelected,
    required this.onTap,
  });

  final TableSlot table;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    if (isSelected) {
      bgColor = AppColors.yellow;
      textColor = Colors.black87;
    } else {
      switch (table.status) {
        case TableStatus.available:
          bgColor = AppColors.green;
          textColor = Colors.white;
          break;
        case TableStatus.reserved:
          bgColor = AppColors.yellow;
          textColor = Colors.black87;
          break;
        case TableStatus.occupied:
          bgColor = AppColors.red;
          textColor = Colors.white;
          break;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              table.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${table.seats} seats',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textColor.withOpacity(0.9),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({
    required this.color,
    required this.label,
    this.darkText = false,
  });

  final Color color;
  final String label;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: darkText ? Colors.black87 : Colors.white,
              ),
        ),
      ],
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            Icon(icon),
          ],
        ),
      ),
    );
  }
}

class _StatusCounters extends StatelessWidget {
  const _StatusCounters({
    required this.available,
    required this.reserved,
    required this.occupied,
  });

  final int available;
  final int reserved;
  final int occupied;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusBadge(
            label: 'Green',
            value: available,
            color: AppColors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatusBadge(
            label: 'Yellow',
            value: reserved,
            color: AppColors.yellow,
            textColor: Colors.black87,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatusBadge(
            label: 'Red',
            value: occupied,
            color: AppColors.red,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.value,
    required this.color,
    this.textColor = Colors.white,
  });

  final String label;
  final int value;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
