import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/dismiss_settings.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:alarm_walker/widgets/app_switch_tile.dart';
import 'package:flutter/material.dart';

class DismissModeConfigScreen extends StatefulWidget {
  final DismissSettings initial;
  const DismissModeConfigScreen({super.key, required this.initial});

  @override
  State<DismissModeConfigScreen> createState() =>
      _DismissModeConfigScreenState();
}

class _DismissModeConfigScreenState extends State<DismissModeConfigScreen> {
  late DismissSettings _s;
  final _reTypeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _s = widget.initial;
    _reTypeController.text = _s.reTypeText;
  }

  @override
  void dispose() {
    _reTypeController.dispose();
    super.dispose();
  }

  void _save() {
    // Capture retype text before popping
    final updated = _s.copyWith(reTypeText: _reTypeController.text.trim());
    Navigator.of(context).pop(updated);
  }

  Widget _buildSection(String title, List<Widget> children, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
          child: Text(
            title.toUpperCase(),
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

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) display,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.caption(context)),
              Text(
                display(value),
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyPicker(int current) {
    final labels = [context.tr('Easy'), context.tr('Medium'), context.tr('Hard')];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: List.generate(3, (i) {
          final v = i + 1;
          final selected = current == v;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _s = _s.copyWith(mathDifficulty: v)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        selected ? AppColors.primary : AppColors.lightBlueGrey,
                  ),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption(context).copyWith(
                    color: selected ? Colors.white : null,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Mode-specific sections ─────────────────────────────────────────────────

  List<Widget> _buildWalkConfig(bool isDark) => [
    _buildSection(context.tr('Walk settings'), [
      _sliderRow(
        label: context.tr('Steps required'),
        value: _s.walkSteps.toDouble(),
        min: 10,
        max: 200,
        divisions: 19,
        display: (v) => context.tr('{count} steps', {'count': v.round()}),
        onChanged:
            (v) => setState(() => _s = _s.copyWith(walkSteps: v.round())),
      ),
    ], isDark),
  ];

  List<Widget> _buildMathConfig(bool isDark) => [
    _buildSection(context.tr('Math settings'), [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          context.tr('Difficulty'),
          style: AppTextStyles.caption(context),
        ),
      ),
      _buildDifficultyPicker(_s.mathDifficulty),
      const Divider(height: 1, indent: 16),
      _sliderRow(
        label: context.tr('Number of problems'),
        value: _s.mathProblemCount.toDouble(),
        min: 1,
        max: 10,
        divisions: 9,
        display: (v) => '${v.round()}',
        onChanged:
            (v) =>
                setState(() => _s = _s.copyWith(mathProblemCount: v.round())),
      ),
      const Divider(height: 1, indent: 16),
      AppSwitchTile(
        title: context.tr('Allow skipping problems'),
        subtitle: context.tr('Can skip a hard problem at a small time penalty'),
        value: _s.mathAllowSkip,
        onChanged: (v) => setState(() => _s = _s.copyWith(mathAllowSkip: v)),
      ),
    ], isDark),
  ];

  List<Widget> _buildShakeConfig(bool isDark) => [
    _buildSection(context.tr('Shake settings'), [
      _sliderRow(
        label: context.tr('Shakes required'),
        value: _s.shakeCount.toDouble(),
        min: 1,
        max: 100,
        divisions: 99,
        display: (v) => '${v.round()}×',
        onChanged:
            (v) => setState(() => _s = _s.copyWith(shakeCount: v.round())),
      ),
      const Divider(height: 1, indent: 16),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('Intensity threshold'),
              style: AppTextStyles.caption(context),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(3, (i) {
                final v = i + 1;
                final labels = [
                  context.tr('Light'),
                  context.tr('Normal'),
                  context.tr('Vigorous'),
                ];
                final selected = _s.shakeIntensity == v;
                return Expanded(
                  child: GestureDetector(
                    onTap:
                        () =>
                            setState(() => _s = _s.copyWith(shakeIntensity: v)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color:
                            selected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              selected
                                  ? AppColors.primary
                                  : AppColors.lightBlueGrey,
                        ),
                      ),
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption(context).copyWith(
                          color: selected ? Colors.white : null,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    ], isDark),
  ];

  List<Widget> _buildReTypeConfig(bool isDark) => [
    _buildSection(context.tr('Retype settings'), [
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _reTypeController,
          decoration: InputDecoration(
            labelText: context.tr('Phrase to retype'),
            hintText: context.tr('e.g. "I am awake"'),
          ),
          maxLength: 60,
        ),
      ),
      const Divider(height: 1, indent: 16),
      AppSwitchTile(
        title: context.tr('Case sensitive'),
        value: _s.reTypeCaseSensitive,
        onChanged:
            (v) => setState(() => _s = _s.copyWith(reTypeCaseSensitive: v)),
      ),
    ], isDark),
  ];

  // ── General (task timer) ───────────────────────────────────────────────────

  List<Widget> _buildGeneralConfig(bool isDark) {
    final hasTimer = _s.taskTimerSeconds != null;
    return [
      _buildSection(context.tr('Task timer'), [
        AppSwitchTile(
          title: context.tr('Limit time per task'),
          subtitle: context.tr('Auto-fails a task if not completed in time'),
          value: hasTimer,
          onChanged:
              (v) => setState(
                () =>
                    _s =
                        v
                            ? _s.copyWith(taskTimerSeconds: 30)
                            : _s.copyWith(clearTaskTimer: true),
              ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child:
              hasTimer
                  ? _sliderRow(
                    label: context.tr('Seconds per task'),
                    value: (_s.taskTimerSeconds ?? 30).toDouble(),
                    min: 10,
                    max: 120,
                    divisions: 22,
                    display: (v) => '${v.round()}s',
                    onChanged:
                        (v) => setState(
                          () => _s = _s.copyWith(taskTimerSeconds: v.round()),
                        ),
                  )
                  : const SizedBox.shrink(),
        ),
      ], isDark),
    ];
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    final modeTitle = switch (_s.mode) {
      AlarmDisarmMode.walk => 'Walk',
      AlarmDisarmMode.math => 'Math',
      AlarmDisarmMode.shake => 'Shake',
      AlarmDisarmMode.retype => 'Retype',
      AlarmDisarmMode.normal => 'Normal',
    };

    final modeConfig = switch (_s.mode) {
      AlarmDisarmMode.walk => _buildWalkConfig(isDark),
      AlarmDisarmMode.math => _buildMathConfig(isDark),
      AlarmDisarmMode.shake => _buildShakeConfig(isDark),
      AlarmDisarmMode.retype => _buildReTypeConfig(isDark),
      AlarmDisarmMode.normal => <Widget>[],
    };

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkScaffold1 : AppColors.lightScaffold1,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkScaffold1 : AppColors.lightScaffold1,
        title: Text(context.tr('Configure {mode}', {'mode': context.tr(modeTitle)})),
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
            ...modeConfig,
            // Task timer applies to all challenge modes
            ..._buildGeneralConfig(isDark),
          ],
        ),
      ),
    );
  }
}
