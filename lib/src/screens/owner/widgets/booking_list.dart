import 'package:flutter/material.dart';

import '../../../models/booking.dart';
import '../../../theme/app_theme.dart';

class BookingList extends StatelessWidget {
  const BookingList({super.key, required this.bookings, required this.onStatusChanged});

  final List<OwnerBooking> bookings;
  final void Function(String id, BookingStatus status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming bookings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (bookings.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.beige,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('No bookings yet. Confirmed reservations will appear here.'),
          )
        else
          ...bookings.map((booking) => _BookingCard(
                booking: booking,
                onStatusChanged: onStatusChanged,
              )),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onStatusChanged});

  final OwnerBooking booking;
  final void Function(String id, BookingStatus status) onStatusChanged;

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return AppColors.yellow;
      case BookingStatus.confirmed:
        return AppColors.green;
      case BookingStatus.cancelled:
        return AppColors.red;
      case BookingStatus.checkedIn:
        return AppColors.softBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(booking.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.guestName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(booking.status.name),
                  backgroundColor: color.withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${booking.partySize} guests • Table ${booking.tableLabel}'),
            const SizedBox(height: 4),
            Text(
              _formatTime(booking.time),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (booking.status == BookingStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onStatusChanged(booking.id, BookingStatus.cancelled),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onStatusChanged(booking.id, BookingStatus.confirmed),
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '${time.month}/${time.day} • $hour:$minute $period';
  }
}