import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class OccupancyChart extends StatelessWidget {
  const OccupancyChart({
    super.key,
    required this.available,
    required this.reserved,
    required this.occupied,
  });

  final int available;
  final int reserved;
  final int occupied;

  int get total => available + reserved + occupied;

  @override
  Widget build(BuildContext context) {
    final segments = [
      _Segment(value: available.toDouble(), color: AppColors.green, label: 'Available'),
      _Segment(value: reserved.toDouble(), color: AppColors.yellow, label: 'Reserved'),
      _Segment(value: occupied.toDouble(), color: AppColors.red, label: 'Occupied'),
    ];

    return Card(
      color: Colors.white,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(160),
                    painter: _PieChartPainter(segments),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text('Total tables', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: segments
                  .map(
                    (segment) => _LegendEntry(
                      color: segment.color,
                      label: segment.label,
                      value: segment.value.toInt(),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text('$value tables', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ],
    );
  }
}

class _Segment {
  const _Segment({required this.value, required this.color, required this.label});
  final double value;
  final Color color;
  final String label;
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter(this.segments);

  final List<_Segment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.butt;
    final rect = Offset.zero & size;
    final total = segments.fold<double>(0, (sum, seg) => sum + seg.value);
    var startAngle = -math.pi / 2;

    for (final segment in segments) {
      if (segment.value == 0 || total == 0) {
        continue;
      }
      final sweep = (segment.value / total) * 2 * math.pi;
      paint.color = segment.color;
      canvas.drawArc(rect.deflate(14), startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}