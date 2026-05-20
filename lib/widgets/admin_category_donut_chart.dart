import 'dart:math' as math;

import 'package:alarm_walker/models/profile_category.dart';
import 'package:flutter/material.dart';

class AdminCategoryDonutChart extends StatelessWidget {
  final Map<ProfileCategory, int> counts;
  final int total;
  final double size;
  final double strokeWidth;
  final bool showCenterLabel;

  const AdminCategoryDonutChart({
    super.key,
    required this.counts,
    required this.total,
    this.size = 170,
    this.strokeWidth = 18,
    this.showCenterLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final segments =
        ProfileCategory.values
            .map(
              (category) => AdminCategoryDonutSegment(
                category: category,
                value: counts[category] ?? 0,
                color: _categoryColor(category),
              ),
            )
            .toList();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _AdminCategoryDonutPainter(
                  segments: segments,
                  total: total,
                  strokeWidth: strokeWidth,
                  animationProgress: progress,
                  emptyColor: Theme.of(context).dividerColor.withValues(alpha: 0.18),
                ),
              ),
              if (showCenterLabel)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      total.toString(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Users',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class AdminCategoryDonutSegment {
  final ProfileCategory category;
  final int value;
  final Color color;

  const AdminCategoryDonutSegment({
    required this.category,
    required this.value,
    required this.color,
  });
}

class _AdminCategoryDonutPainter extends CustomPainter {
  final List<AdminCategoryDonutSegment> segments;
  final int total;
  final double strokeWidth;
  final double animationProgress;
  final Color emptyColor;

  const _AdminCategoryDonutPainter({
    required this.segments,
    required this.total,
    required this.strokeWidth,
    required this.animationProgress,
    required this.emptyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final basePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = emptyColor;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, basePaint);

    if (total <= 0) return;

    var startAngle = -math.pi / 2;
    final gap = segments.where((segment) => segment.value > 0).length > 1 ? 0.035 : 0.0;

    for (final segment in segments) {
      if (segment.value <= 0) continue;

      final sweep = ((segment.value / total) * math.pi * 2 * animationProgress) - gap;
      if (sweep <= 0) continue;

      final paint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round
            ..color = segment.color;

      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += (segment.value / total) * math.pi * 2 * animationProgress;
    }
  }

  @override
  bool shouldRepaint(covariant _AdminCategoryDonutPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.total != total ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.emptyColor != emptyColor;
  }
}

Color _categoryColor(ProfileCategory category) {
  return switch (category) {
    ProfileCategory.child => Colors.purple,
    ProfileCategory.adult => Colors.blue,
    ProfileCategory.senior => Colors.teal,
  };
}
