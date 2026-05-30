import 'dart:math' as math;

import 'package:alarm_walker/models/alarm_model.dart';
import 'package:flutter/material.dart';

class AdminDisarmModeDonutChart extends StatelessWidget {
  final Map<AlarmDisarmMode, int> counts;
  final int total;
  final double size;
  final double strokeWidth;
  final bool showCenterLabel;
  final String centerLabel;

  const AdminDisarmModeDonutChart({
    super.key,
    required this.counts,
    required this.total,
    this.size = 170,
    this.strokeWidth = 18,
    this.showCenterLabel = true,
    this.centerLabel = 'Selections',
  });

  @override
  Widget build(BuildContext context) {
    final segments =
        AlarmDisarmMode.values
            .map(
              (mode) => AdminDisarmModeDonutSegment(
                mode: mode,
                value: counts[mode] ?? 0,
                color: adminDisarmModeColor(mode),
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
                painter: _AdminDisarmModeDonutPainter(
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
                      centerLabel,
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

class AdminDisarmModeDonutSegment {
  final AlarmDisarmMode mode;
  final int value;
  final Color color;

  const AdminDisarmModeDonutSegment({
    required this.mode,
    required this.value,
    required this.color,
  });
}

class _AdminDisarmModeDonutPainter extends CustomPainter {
  final List<AdminDisarmModeDonutSegment> segments;
  final int total;
  final double strokeWidth;
  final double animationProgress;
  final Color emptyColor;

  const _AdminDisarmModeDonutPainter({
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
    final visibleSegments = segments.where((segment) => segment.value > 0).length;
    final gap = visibleSegments > 1 ? 0.035 : 0.0;

    for (final segment in segments) {
      if (segment.value <= 0) continue;

      final fullSweep = (segment.value / total) * math.pi * 2;
      final sweep = (fullSweep * animationProgress) - gap;
      if (sweep <= 0) continue;

      final paint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round
            ..color = segment.color;

      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += fullSweep * animationProgress;
    }
  }

  @override
  bool shouldRepaint(covariant _AdminDisarmModeDonutPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.total != total ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.emptyColor != emptyColor;
  }
}

Color adminDisarmModeColor(AlarmDisarmMode mode) {
  return switch (mode) {
    AlarmDisarmMode.math => Colors.blue,
    AlarmDisarmMode.retype => Colors.purple,
    AlarmDisarmMode.shake => Colors.orange,
    AlarmDisarmMode.walk => Colors.green,
    AlarmDisarmMode.normal => Colors.grey,
  };
}

IconData adminDisarmModeIcon(AlarmDisarmMode mode) {
  return switch (mode) {
    AlarmDisarmMode.math => Icons.calculate_outlined,
    AlarmDisarmMode.retype => Icons.keyboard_alt_outlined,
    AlarmDisarmMode.shake => Icons.vibration_outlined,
    AlarmDisarmMode.walk => Icons.directions_walk_outlined,
    AlarmDisarmMode.normal => Icons.touch_app_outlined,
  };
}
