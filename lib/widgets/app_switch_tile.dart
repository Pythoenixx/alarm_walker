import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:alarm_walker/widgets/gradient_switch.dart';
import 'package:flutter/material.dart';

class AppSwitchTile extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final EdgeInsetsGeometry padding;

  const AppSwitchTile({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedText = theme.colorScheme.onSurface.withValues(alpha: 0.68);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.caption(context).copyWith(
                        color: mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            GradientSwitch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
