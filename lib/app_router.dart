import 'package:alarm/alarm.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/screens/add_alarm_screen.dart';
import 'package:alarm_walker/screens/alarm_ringing_screen.dart';
import 'package:alarm_walker/screens/authenticate.dart';
import 'package:alarm_walker/screens/database_screen.dart';
import 'package:alarm_walker/screens/home.dart';
import 'package:alarm_walker/screens/math_alarm_screen.dart';
import 'package:alarm_walker/screens/retype_alarm_screen.dart';
import 'package:alarm_walker/screens/settings_screen.dart';
import 'package:alarm_walker/screens/shake_alarm_screen.dart';
import 'package:alarm_walker/screens/wrapper.dart';
import 'package:go_router/go_router.dart';

enum AppRoute {
  wrapper,
  authenticate,
  home,
  addAlarm,
  settings,
  alarmRinging,
  mathAlarm,
  shakeAlarm,
  retypeAlarm,
  database,
}

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: AppRoute.wrapper.name,
        builder: (context, state) => const Wrapper(),
        routes: [
          GoRoute(
            path: AppRoute.authenticate.name,
            name: AppRoute.authenticate.name,
            builder: (context, state) => const Authenticate(),
          ),
          GoRoute(
            path: AppRoute.home.name,
            name: AppRoute.home.name,
            builder: (context, state) => const Home(),
          ),
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
            path: AppRoute.retypeAlarm.name,
            name: AppRoute.retypeAlarm.name,
            builder:
                (context, state) => RetypeAlarmScreen(
                  alarmSettings: state.extra! as AlarmSettings,
                ),
          ),
          GoRoute(
            path: AppRoute.database.name,
            name: AppRoute.database.name,
            builder: (context, state) => const DatabaseScreen(),
          ),
        ],
      ),
    ],
  );
}
