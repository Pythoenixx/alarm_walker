import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/dismiss_settings.dart';
import 'package:alarm_walker/screens/dismiss_mode_config_screen.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class DismissSettingsScreen extends StatefulWidget {
  final DismissSettings initial;
  const DismissSettingsScreen({super.key, required this.initial});

  @override
  State<DismissSettingsScreen> createState() => _DismissSettingsScreenState();
}

class _DismissSettingsScreenState extends State<DismissSettingsScreen> {
  late DismissSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initial;
  }

  void _save() => Navigator.of(context).pop(_settings);

  Future<void> _configure() async {
    final result = await Navigator.of(context).push<DismissSettings>(
      MaterialPageRoute(
        builder: (_) => DismissModeConfigScreen(initial: _settings),
      ),
    );
    if (result != null) setState(() => _settings = result);
  }

  static const _modeInfo =
      <AlarmDisarmMode, ({IconData icon, String label, String description})>{
        AlarmDisarmMode.normal: (
          icon: Icons.alarm_off_outlined,
          label: 'Normal', // TODO: localize all
          description: 'Tap to dismiss',
        ),
        AlarmDisarmMode.walk: (
          icon: Icons.directions_walk_outlined,
          label: 'Walk',
          description: 'Take steps to dismiss',
        ),
        AlarmDisarmMode.math: (
          icon: Icons.calculate_outlined,
          label: 'Math',
          description: 'Solve equations to dismiss',
        ),
        AlarmDisarmMode.shake: (
          icon: Icons.vibration,
          label: 'Shake',
          description: 'Shake phone to dismiss',
        ),
        AlarmDisarmMode.retype: (
          icon: Icons.keyboard_outlined,
          label: 'Retype',
          description: 'Type a phrase to dismiss',
        ),
      };

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final selected = _settings.mode;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkScaffold1 : AppColors.lightScaffold1,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkScaffold1 : AppColors.lightScaffold1,
        title: Text(context.tr('Dismiss')),
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
              style: const TextStyle(color: AppColors.primary),
            ), // TODO: localize
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode grid
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
                children:
                    AlarmDisarmMode.values.map((mode) {
                      final info = _modeInfo[mode]!;
                      final isSelected = mode == selected;
                      return GestureDetector(
                        onTap:
                            () => setState(
                              () => _settings = _settings.copyWith(mode: mode),
                            ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : isDark
                                    ? AppColors.darkScaffold1.withOpacity(0.6)
                                    : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBlueGrey,
                              width: isSelected ? 0 : 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                info.icon,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : isDark
                                        ? AppColors.darkBackgroundText
                                        : AppColors.lightBackgroundText,
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.tr(info.label),
                                style: AppTextStyles.caption(context).copyWith(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : isDark
                                          ? AppColors.darkBackgroundText
                                          : AppColors.lightBackgroundText,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),

            // Description of selected mode
            if (_modeInfo[selected] != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  context.tr(_modeInfo[selected]!.description),
                  style: AppTextStyles.caption(context),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 16),

            // Configure button (hidden for Normal)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child:
                  selected != AlarmDisarmMode.normal
                      ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: OutlinedButton.icon(
                          onPressed: _configure,
                          icon: const Icon(Icons.tune),
                          label: Text(context.tr('Configure')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
