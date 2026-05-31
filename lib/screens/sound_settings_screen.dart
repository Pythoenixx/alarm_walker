import 'dart:io';

import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/sound_settings.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:alarm_walker/widgets/app_switch_tile.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class SoundSettingsScreen extends StatefulWidget {
  final SoundSettings initial;
  const SoundSettingsScreen({super.key, required this.initial});

  @override
  State<SoundSettingsScreen> createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends State<SoundSettingsScreen> {
  late SoundSettings _settings;

  // Preset sounds bundled with the app.
  // Keep only assets that actually exist in the project.
  // Custom audio from the user's device is handled by _pickFromDevice().
  static const _presets = <String, String?>{
    'Alarm 1': 'assets/sounds/alarm_1.mp3',
    'Samsung Alarm': 'assets/sounds/alarm_samsung.mp3',
    'Smooth Alarm': 'assets/sounds/smooth_alarm.mp3',
    'Rooster Alarm': 'assets/sounds/rooster_alarm.mp3',
    'Birds': 'assets/sounds/birds.mp3',
    'System Default': null,
  };

  static const _allowedAudioExtensions = <String>{
    'mp3',
    'wav',
    'm4a',
    'aac',
    'ogg',
  };

  @override
  void initState() {
    super.initState();
    _settings = widget.initial;
  }

  void _save() => Navigator.of(context).pop(_settings);

  bool _isSupportedAudioFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return _allowedAudioExtensions.contains(extension);
  }

  Future<String> _copyCustomSoundToAppStorage({
    required PlatformFile file,
    required String sourcePath,
  }) async {
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw const FileSystemException('Selected audio file does not exist.');
    }

    final appDir = await getApplicationDocumentsDirectory();
    final customSoundDir = Directory(path.join(appDir.path, 'custom_sounds'));

    if (!await customSoundDir.exists()) {
      await customSoundDir.create(recursive: true);
    }

    final safeName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final destinationPath = path.join(
      customSoundDir.path,
      '$timestamp-$safeName',
    );

    final copiedFile = await sourceFile.copy(destinationPath);
    return copiedFile.path;
  }

  Future<void> _pickFromDevice() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (!mounted || result == null) return;

    final file = result.files.single;
    final sourcePath = file.path;

    if (sourcePath == null || sourcePath.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to read the selected audio file path.'),
        ),
      );
      return;
    }

    if (!_isSupportedAudioFile(file.name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an MP3, WAV, M4A, AAC, or OGG file.'),
        ),
      );
      return;
    }

    try {
      final savedPath = await _copyCustomSoundToAppStorage(
        file: file,
        sourcePath: sourcePath,
      );

      if (!mounted) return;

      setState(() {
        _settings = _settings.copyWith(
          soundPath: savedPath,
          soundName: file.name,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected ${file.name}')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save the selected audio file.'),
        ),
      );
    }
  }

  void _clearCustomSound() {
    setState(() {
      _settings = _settings.copyWith(clearSound: true);
    });
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
    final isCustomSound =
        s.soundPath != null && !_presets.values.contains(s.soundPath);

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
              ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(s.soundName ?? 'Default'),
                subtitle: Text(
                  isCustomSound
                      ? 'Saved custom audio from device'
                      : 'Bundled alarm sound',
                ),
                trailing:
                    isCustomSound
                        ? IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Remove custom sound',
                          onPressed: _clearCustomSound,
                        )
                        : null,
              ),
              const Divider(height: 1, indent: 16),
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
                subtitle: const Text('Choose MP3, WAV, M4A, AAC, or OGG'),
                onTap: _pickFromDevice,
              ),
            ], isDark),

            // ── Volume ─────────────────────────────────────────────────────
            _buildSection('Volume', [
              AppSwitchTile(
                icon: Icons.volume_up_outlined,
                title: 'Override phone volume', // TODO: localize
                subtitle: 'Alarm uses its own volume level',
                value: s.overrideVolume,
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
                                  label: '${(s.volume * 100).round()}%',
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
              AppSwitchTile(
                icon: Icons.tune_outlined,
                title: 'Allow volume changes mid-alarm', // TODO: localize
                subtitle: 'Let hardware buttons adjust alarm volume',
                value: s.allowMidAlarmVolumeChange,
                onChanged:
                    (v) => setState(
                      () =>
                          _settings = s.copyWith(allowMidAlarmVolumeChange: v),
                    ),
              ),
            ], isDark),

            // ── Fade in ────────────────────────────────────────────────────
            _buildSection('Fade in', [
              AppSwitchTile(
                icon: Icons.trending_up_outlined,
                title: 'Gradually increase volume', // TODO: localize
                subtitle: 'Starts quiet and builds up over time',
                value: s.gradualVolumeIncrease,
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
              AppSwitchTile(
                icon: Icons.vibration,
                title: 'Vibrate', // TODO: localize
                value: s.vibrate,
                onChanged:
                    (v) => setState(() => _settings = s.copyWith(vibrate: v)),
              ),
            ], isDark),

            // ── Flashlight ─────────────────────────────────────────────────
            _buildSection('Flashlight', [
              AppSwitchTile(
                icon: Icons.flashlight_on_outlined,
                title: 'Flash torch on alarm', // TODO: localize
                subtitle: 'Blinks the rear flashlight when alarm fires',
                value: s.flashlight,
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
