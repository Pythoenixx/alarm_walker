import 'package:alarm/alarm.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/screens/add_alarm_screen.dart';
import 'package:alarm_walker/screens/alarm_ringing_screen.dart';
import 'package:alarm_walker/screens/home.dart';
import 'package:alarm_walker/screens/math_alarm_screen.dart';
import 'package:alarm_walker/screens/qr_alarm_screen.dart';
import 'package:alarm_walker/screens/settings_screen.dart';
import 'package:alarm_walker/screens/shake_alarm_screen.dart';
import 'package:alarm_walker/screens/tap_alarm_screen.dart';
import 'package:go_router/go_router.dart';

enum AppRoute {
  home,
  addAlarm,
  settings,
  alarmRinging,
  mathAlarm,
  shakeAlarm,
  qrAlarm,
  tapAlarm,
}

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: AppRoute.home.name,
        builder: (context, state) => const Home(),
        routes: [
          GoRoute(
            path: AppRoute.addAlarm.name,
            name: AppRoute.addAlarm.name,
            builder: (context, state) {
              final alarmModel = state.extra as AlarmModel?;
              return AddAlarmScreen(alarmModel: alarmModel);
            },
          ),
          GoRoute(
            path: AppRoute.settings.name,
            name: AppRoute.settings.name,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoute.alarmRinging.name,
            name: AppRoute.alarmRinging.name,
            builder:
                (context, state) => AlarmRingingScreen(
                  alarmSettings: state.extra! as AlarmSettings,
                ),
          ),
          GoRoute(
            path: AppRoute.mathAlarm.name,
            name: AppRoute.mathAlarm.name,
            builder:
                (context, state) => MathAlarmScreen(
                  alarmSettings: state.extra! as AlarmSettings,
                ),
          ),
          GoRoute(
            path: AppRoute.shakeAlarm.name,
            name: AppRoute.shakeAlarm.name,
            builder:
                (context, state) => ShakeAlarmScreen(
                  alarmSettings: state.extra! as AlarmSettings,
                ),
          ),
          GoRoute(
            path: AppRoute.qrAlarm.name,
            name: AppRoute.qrAlarm.name,
            builder:
                (context, state) =>
                    QrAlarmScreen(alarmSettings: state.extra! as AlarmSettings),
          ),
          GoRoute(
            path: AppRoute.tapAlarm.name,
            name: AppRoute.tapAlarm.name,
            builder:
                (context, state) => TapAlarmScreen(
                  alarmSettings: state.extra! as AlarmSettings,
                ),
          ),
        ],
      ),
    ],
  );
}
