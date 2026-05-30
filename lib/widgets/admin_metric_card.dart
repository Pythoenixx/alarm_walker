import 'package:flutter/material.dart';

class AdminAnimatedCard extends StatefulWidget {
  final int index;
  final Widget child;
  final int delayMs;

  const AdminAnimatedCard({
    super.key,
    required this.index,
    required this.child,
    this.delayMs = 80,
  });

  @override
  State<AdminAnimatedCard> createState() => _AdminAnimatedCardState();
}

class _AdminAnimatedCardState extends State<AdminAnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.94, end: 1).animate(curve);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

class AdminMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String note;
  final Color color;
  final double width;
  final bool embedded;

  const AdminMetricCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.note,
    required this.color,
    this.width = 230,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(note, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );

    if (embedded) {
      return SizedBox(
        width: width,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.35)),
          ),
          child: content,
        ),
      );
    }

    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: content,
      ),
    );
  }
}
