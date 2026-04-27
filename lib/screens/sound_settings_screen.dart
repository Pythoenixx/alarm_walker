import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/sound_settings.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

// TODO: add `file_picker` package for device audio selection
// TODO: add `just_audio` (or similar) package for sound preview

class SoundSettingsScreen extends StatefulWidget {
  final SoundSettings initial;
  const SoundSettingsScreen({super.key, required this.initial});

  @override
  State<SoundSettingsScreen> createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends State<SoundSettingsScreen> {
  late SoundSettings _settings;

  // Preset sounds bundled with the app.
  // Key = display name, value = asset path (null = system default).
  static const _presets = <String, String?>{
    'Default': null,
    'Gentle Rise': 'assets/sounds/gentle_rise.mp3',
    'Digital': 'assets/sounds/digital.mp3',
    'Chime': 'assets/sounds/chime.mp3',
    'Radar': 'assets/sounds/radar.mp3',
  };

  @override
  void initState() {
    super.initState();
    _settings = widget.initial;
  }

  void _save() => Navigator.of(context).pop(_settings);

  Future<void> _pickFromDevice() async {
    // TODO: use file_picker to pick an audio file from device
    // Example:
    //   final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    //   if (result != null) {
    //     final path = result.files.single.path!;
    //     final name = result.files.single.name;
    //     setState(() => _settings = _settings.copyWith(soundPath: path, soundName: name));
    //   }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File picker not yet integrated')),
    );
  }

  Future<void> _previewSound() async {
    // TODO: play _settings.soundPath (or default) for ~3 seconds
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Preview not yet integrated')));
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
        title: const Text('Sound'), // TODO: localize
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
              'Save', // TODO: localize
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
            // ── Sound picker ───────────────────────────────────────────────
            _buildSection('Sound', [
              // TODO: localize
              // Current selection + preview
              ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(s.soundName ?? 'Default'),
                trailing: IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: _previewSound,
                  tooltip: 'Preview',
                ),
              ),
              const Divider(height: 1, indent: 16),
              // Presets
              ..._presets.entries.map(
                (e) => RadioListTile<String?>(
                  title: Text(e.key),
                  value: e.value,
                  groupValue: s.soundPath,
                  activeColor: AppColors.primary,
                  onChanged:
                      (v) => setState(
                        () =>
                            _settings = s.copyWith(
                              soundPath: v,
                              soundName: e.key,
                              clearSound: v == null,
                            ),
                      ),
                ),
              ),
              const Divider(height: 1, indent: 16),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text('From device…'), // TODO: localize
                onTap: _pickFromDevice,
              ),
            ], isDark),

            // ── Volume ─────────────────────────────────────────────────────
            _buildSection('Volume', [
              // TODO: localize
              SwitchListTile(
                secondary: const Icon(Icons.volume_up_outlined),
                title: const Text('Override phone volume'), // TODO: localize
                subtitle: const Text('Alarm uses its own volume level'),
                value: s.overrideVolume,
                activeColor: AppColors.primary,
                onChanged:
                    (v) => setState(
                      () => _settings = s.copyWith(overrideVolume: v),
                    ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child:
                    s.overrideVolume
                        ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            children: [
                              const Icon(Icons.volume_mute, size: 20),
                              Expanded(
                                child: Slider(
                                  value: s.volume,
                                  min: 0,
                                  max: 1,
                                  divisions: 10,
                                  activeColor: AppColors.primary,
                                  onChanged:
                                      (v) => setState(
                                        () => _settings = s.copyWith(volume: v),
                                      ),
                                ),
                              ),
                              const Icon(Icons.volume_up, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${(s.volume * 100).round()}%',
                                style: AppTextStyles.caption(context),
                              ),
                            ],
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
              const Divider(height: 1, indent: 16),
              SwitchListTile(
                secondary: const Icon(Icons.tune_outlined),
                title: const Text(
                  'Allow volume changes mid-alarm',
                ), // TODO: localize
                subtitle: const Text(
                  'Let hardware buttons adjust alarm volume',
                ),
                value: s.allowMidAlarmVolumeChange,
                activeColor: AppColors.primary,
                onChanged:
                    (v) => setState(
                      () =>
                          _settings = s.copyWith(allowMidAlarmVolumeChange: v),
                    ),
              ),
            ], isDark),

            // ── Fade in ────────────────────────────────────────────────────
            _buildSection('Fade in', [
              // TODO: localize
              SwitchListTile(
                secondary: const Icon(Icons.trending_up_outlined),
                title: const Text(
                  'Gradually increase volume',
                ), // TODO: localize
                subtitle: const Text('Starts quiet and builds up over time'),
                value: s.gradualVolumeIncrease,
                activeColor: AppColors.primary,
                onChanged:
                    (v) => setState(
                      () => _settings = s.copyWith(gradualVolumeIncrease: v),
                    ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child:
                    s.gradualVolumeIncrease
                        ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Increase over ${s.gradualIncreaseDurationSeconds}s',
                                style: AppTextStyles.caption(context),
                              ),
                              Slider(
                                value:
                                    s.gradualIncreaseDurationSeconds.toDouble(),
                                min: 5,
                                max: 120,
                                divisions: 23,
                                activeColor: AppColors.primary,
                                label: '${s.gradualIncreaseDurationSeconds}s',
                                onChanged:
                                    (v) => setState(
                                      () =>
                                          _settings = s.copyWith(
                                            gradualIncreaseDurationSeconds:
                                                v.round(),
                                          ),
                                    ),
                              ),
                            ],
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
            ], isDark),

            // ── Haptics ────────────────────────────────────────────────────
            _buildSection('Haptics', [
              // TODO: localize
              SwitchListTile(
                secondary: const Icon(Icons.vibration),
                title: const Text('Vibrate'), // TODO: localize
                value: s.vibrate,
                activeColor: AppColors.primary,
                onChanged:
                    (v) => setState(() => _settings = s.copyWith(vibrate: v)),
              ),
            ], isDark),

            // ── Flashlight ─────────────────────────────────────────────────
            _buildSection('Flashlight', [
              // TODO: localize
              SwitchListTile(
                secondary: const Icon(Icons.flashlight_on_outlined),
                title: const Text('Flash torch on alarm'), // TODO: localize
                subtitle: const Text(
                  'Blinks the rear flashlight when alarm fires',
                ),
                value: s.flashlight,
                activeColor: AppColors.primary,
                onChanged:
                    (v) =>
                        setState(() => _settings = s.copyWith(flashlight: v)),
              ),
            ], isDark),
          ],
        ),
      ),
    );
  }
}
