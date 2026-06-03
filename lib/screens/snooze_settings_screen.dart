import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/snooze_settings.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:alarm_walker/widgets/app_switch_tile.dart';
import 'package:flutter/material.dart';

class SnoozeSettingsScreen extends StatefulWidget {
  final SnoozeSettings initial;
  const SnoozeSettingsScreen({super.key, required this.initial});

  @override
  State<SnoozeSettingsScreen> createState() => _SnoozeSettingsScreenState();
}

class _SnoozeSettingsScreenState extends State<SnoozeSettingsScreen> {
  late SnoozeSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initial;
  }

  void _save() => Navigator.of(context).pop(_settings);

  Widget _buildSection(String title, List<Widget> children, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
          child: Text(
            context.tr(title).toUpperCase(),
            style: AppTextStyles.caption(context).copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color:
                isDark
                    ? AppColors.darkScaffold1.withOpacity(0.6)
                    : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _chipRow({
    required List<int> options,
    required int selected,
    required String Function(int) labelBuilder,
    required ValueChanged<int> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            options
                .map(
                  (v) => ChoiceChip(
                    label: Text(labelBuilder(v)),
                    selected: selected == v,
                    onSelected: (_) => onSelected(v),
                    selectedColor: AppColors.primary,
                    labelStyle: AppTextStyles.caption(
                      context,
                    ).copyWith(color: selected == v ? Colors.white : null),
                  ),
                )
                .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final s = _settings;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkScaffold1 : AppColors.lightScaffold1,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkScaffold1 : AppColors.lightScaffold1,
        title: Text(context.tr('Snooze')),
        titleTextStyle: AppTextStyles.heading(context),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              context.tr('Save'),
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark
                    ? [AppColors.darkScaffold1, AppColors.darkScaffold2]
                    : [AppColors.lightContainer1, AppColors.lightContainer2],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // ── Enable toggle ──────────────────────────────────────────────
            _buildSection('Snooze', [
              AppSwitchTile(
                icon: Icons.snooze,
                title: context.tr('Enable snooze'),
                value: s.enabled,
                onChanged:
                    (v) => setState(() => _settings = s.copyWith(enabled: v)),
              ),
            ], isDark),

            // ── Duration + max count (hidden when disabled) ───────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child:
                  s.enabled
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Duration
                          _buildSection('Duration', [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Text(
                                context.tr('How long each snooze lasts'),
                                style: AppTextStyles.caption(context),
                              ),
                            ),
                            _chipRow(
                              options: const [1, 2, 3, 5, 10, 15, 20, 30],
                              selected: s.durationMinutes,
                              labelBuilder: (v) => '${v}m',
                              onSelected:
                                  (v) => setState(
                                    () =>
                                        _settings = s.copyWith(
                                          durationMinutes: v,
                                        ),
                                  ),
                            ),
                          ], isDark),

                          // Max count
                          _buildSection('Max snoozes', [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Text(
                                context.tr('How many times the alarm can be snoozed'),
                                style: AppTextStyles.caption(context),
                              ),
                            ),
                            _chipRow(
                              options: const [1, 2, 3, 5, 10, 0],
                              selected: s.maxCount,
                              labelBuilder: (v) => v == 0 ? '∞' : '${v}×',
                              onSelected:
                                  (v) => setState(
                                    () => _settings = s.copyWith(maxCount: v),
                                  ),
                            ),
                          ], isDark),
                        ],
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
