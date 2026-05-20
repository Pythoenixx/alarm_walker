import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm_walker/app_router.dart';
import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/firebase_options.dart';
import 'package:alarm_walker/l10n/generated/app_localizations.dart';
import 'package:alarm_walker/models/alarm_repository.dart';
import 'package:alarm_walker/models/app_language.dart';
import 'package:alarm_walker/models/user_profile_repository.dart';
import 'package:alarm_walker/models/wake_log_repository.dart';
import 'package:alarm_walker/services/alarm_cubit.dart';
import 'package:alarm_walker/services/alarm_database.dart';
import 'package:alarm_walker/services/custom_sounds_cubit.dart';
import 'package:alarm_walker/services/profile_cubit.dart';
import 'package:alarm_walker/services/settings_cubit.dart';
import 'package:alarm_walker/services/shared_prefs_with_cache.dart';
import 'package:alarm_walker/theme/app_theme.dart';
import 'package:device_preview_plus/device_preview_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SharedPreferencesWithCache.initialize();
  await AlarmDatabase.initialize();
  await Alarm.init();

  if (appFlavor == "development") {
    runApp(DevicePreview(builder: (context) => const MyApp()));
  } else {
    runApp(const MyApp());
  }
}

Locale? _resolveLocale(
  AppLanguage language,
  BuildContext context,
  bool previewEnabled,
) {
  if (language != AppLanguage.system) return language.locale;
  return previewEnabled ? DevicePreview.locale(context) : null;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final alarmRepo = AlarmRepository(AlarmDatabase.database);
  static final profileRepo = UserProfileRepository(AlarmDatabase.database);
  static final wakeRepo = WakeLogRepository(AlarmDatabase.database);

  static final GoRouter _router = createRouterWithStream(
    alarmRepo,
    profileRepo,
    wakeRepo,
  );

  @override
  Widget build(BuildContext context) {
    final bool previewEnabled = DevicePreview.isEnabled(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create:
              (_) => AlarmCubit(
                alarmRepo: alarmRepo,
                wakeLogRepo: wakeRepo,
                userRepo: profileRepo,
              ),
        ),
        BlocProvider(
          create: (_) {
            final cubit = ProfileCubit(profileRepo);
            unawaited(
              cubit.loadProfile('local'),
            ); // Call it without the cascade
            return cubit; // Return the actual Cubit instance
          },
        ),
        BlocProvider(create: (_) => SettingsCubit()),
        BlocProvider(create: (_) => CustomSoundsCubit()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) => context.localization.appTitle,
            themeMode: state.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            routerConfig: _router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: _resolveLocale(state.appLanguage, context, previewEnabled),
            builder: previewEnabled ? DevicePreview.appBuilder : null,
          );
        },
      ),
    );
  }
}
