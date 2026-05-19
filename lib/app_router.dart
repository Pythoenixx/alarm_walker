import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/alarm_repository.dart';
import 'package:alarm_walker/models/user_profile_repository.dart';
import 'package:alarm_walker/models/wake_log_repository.dart';
import 'package:alarm_walker/screens/add_alarm_screen.dart';
import 'package:alarm_walker/screens/alarm_gate_screen.dart';
import 'package:alarm_walker/screens/database_screen.dart';
import 'package:alarm_walker/screens/home.dart';
import 'package:alarm_walker/screens/login_screen.dart';
import 'package:alarm_walker/screens/math_alarm_screen.dart';
import 'package:alarm_walker/screens/profile_screen.dart';
import 'package:alarm_walker/screens/retype_alarm_screen.dart';
import 'package:alarm_walker/screens/settings_screen.dart';
import 'package:alarm_walker/screens/shake_alarm_screen.dart';
import 'package:alarm_walker/screens/sign_up_screen.dart';
import 'package:alarm_walker/screens/wake_analytics_screen.dart';
import 'package:alarm_walker/screens/walk_alarm_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum AppRoute {
  wrapper,
  signUp,
  login,
  authenticate,
  home,
  addAlarm,
  manageProfile,
  wakeAnalytics,
  settings,
  normal,
  mathAlarm,
  shakeAlarm,
  retypeAlarm,
  walkAlarm,
  database,
  alarmGate,
}

GoRouter createRouterWithStream(
  AlarmRepository alarmRepo,
  UserProfileRepository userRepo,
  WakeLogRepository wakeRepo,
) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final requiresAuth =
          state.matchedLocation == '/manageProfile' ||
          state.matchedLocation == '/wakeAnalytics';
      if (requiresAuth && user == null) return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: AppRoute.wrapper.name,
        redirect: (_, __) => '/home',
      ),

      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: AppRoute.login.name,
        builder: (context, state) => LoginScreen(userRepo: userRepo),
      ),
      GoRoute(
        path: '/signUp',
        name: AppRoute.signUp.name,
        builder: (_, __) => const SignUpScreen(),
      ),

      // ── Main ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/home',
        name: AppRoute.home.name,
        builder: (_, __) => const Home(),
      ),
      GoRoute(
        path: '/addAlarm',
        name: AppRoute.addAlarm.name,
        builder:
            (context, state) =>
                AddAlarmScreen(alarmModel: state.extra as AlarmModel?),
      ),
      GoRoute(
        path: '/wakeAnalytics',
        name: AppRoute.wakeAnalytics.name,
        builder: (_, __) => WakeAnalyticsScreen(wakeRepo: wakeRepo),
      ),
      GoRoute(
        path: '/manageProfile',
        name: AppRoute.manageProfile.name,
        builder: (_, __) => ProfileScreen(userRepo: userRepo),
      ),
      GoRoute(
        path: '/settings',
        name: AppRoute.settings.name,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/database',
        name: AppRoute.database.name,
        builder: (_, __) => DatabaseScreen(repository: alarmRepo),
      ),

      // ── Alarm screens ─────────────────────────────────────────────────────
      GoRoute(
        path: '/alarmGate',
        name: AppRoute.alarmGate.name,
        builder: (context, state) {
          final (alarm, model) = state.extra! as (AlarmSettings, AlarmModel);

          return AlarmGateScreen(alarmSettings: alarm, alarmModel: model);
        },
      ),
      GoRoute(
        path: '/mathAlarm',
        name: AppRoute.mathAlarm.name,
        builder: (context, state) {
          final (alarm, model) = state.extra! as (AlarmSettings, AlarmModel);

          return MathAlarmScreen(alarmSettings: alarm, alarmModel: model);
        },
      ),
      GoRoute(
        path: '/shakeAlarm',
        name: AppRoute.shakeAlarm.name,
        builder: (context, state) {
          final (alarm, model) = state.extra! as (AlarmSettings, AlarmModel);

          return ShakeAlarmScreen(alarmSettings: alarm, alarmModel: model);
        },
      ),
      GoRoute(
        path: '/retypeAlarm',
        name: AppRoute.retypeAlarm.name,
        builder: (context, state) {
          final (alarm, model) = state.extra! as (AlarmSettings, AlarmModel);

          return RetypeAlarmScreen(alarmSettings: alarm, alarmModel: model);
        },
      ),
      GoRoute(
        path: '/walkAlarm',
        name: AppRoute.walkAlarm.name,
        builder: (context, state) {
          final (alarm, model) = state.extra! as (AlarmSettings, AlarmModel);

          return WalkAlarmScreen(alarmSettings: alarm, alarmModel: model);
        },
      ),
    ],
  );
}

// Helper class to convert Stream to Listenable
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
// import 'package:alarm/alarm.dart';
// import 'package:alarm_walker/models/alarm_model.dart';
// import 'package:alarm_walker/screens/add_alarm_screen.dart';
// import 'package:alarm_walker/screens/alarm_ringing_screen.dart';
// import 'package:alarm_walker/screens/authenticate.dart';
// import 'package:alarm_walker/screens/database_screen.dart';
// import 'package:alarm_walker/screens/home.dart';
// import 'package:alarm_walker/screens/login_screen.dart';
// import 'package:alarm_walker/screens/math_alarm_screen.dart';
// import 'package:alarm_walker/screens/retype_alarm_screen.dart';
// import 'package:alarm_walker/screens/settings_screen.dart';
// import 'package:alarm_walker/screens/shake_alarm_screen.dart';
// import 'package:alarm_walker/screens/sign_up_screen.dart';
// import 'package:alarm_walker/screens/wrapper.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// enum AppRoute {
//   wrapper,
//   signUp,
//   login,
//   authenticate,
//   home,
//   addAlarm,
//   settings,
//   alarmRinging,
//   mathAlarm,
//   shakeAlarm,
//   retypeAlarm,
//   database,
// }

// GoRouter createRouter() {
//   return GoRouter(
//     initialLocation: '/',
//     redirect: (context, state) {
//       // Get current auth state
//       final user = FirebaseAuth.instance.currentUser;
//       final isLoggedIn = user != null;

//       // Get current location
//       final isAuthRoute =
//           state.matchedLocation == '/login' ||
//           state.matchedLocation == '/signUp' ||
//           state.matchedLocation == '/authenticate';

//       // If not logged in and trying to access protected route, redirect to login
//       if (!isLoggedIn && !isAuthRoute) {
//         return '/authenticate';
//       }

//       // If logged in and trying to access auth routes, redirect to home
//       if (isLoggedIn && isAuthRoute) {
//         return '/';
//       }

//       // No redirect needed
//       return null;
//     },
//     refreshListenable: _AuthStateNotifier(),
//     routes: [
//       // Auth routes (public)
//       GoRoute(
//         path: '/authenticate',
//         name: AppRoute.authenticate.name,
//         builder: (context, state) => const Authenticate(),
//       ),
//       GoRoute(
//         path: '/login',
//         name: AppRoute.login.name,
//         builder: (context, state) => const LoginScreen(),
//       ),
//       GoRoute(
//         path: '/signUp',
//         name: AppRoute.signUp.name,
//         builder: (context, state) => const SignUpScreen(),
//       ),

//       // Protected routes (require authentication)
//       GoRoute(
//         path: '/',
//         name: AppRoute.home.name,
//         builder: (context, state) => const Home(),
//       ),
//       GoRoute(
//         path: '/addAlarm',
//         name: AppRoute.addAlarm.name,
//         builder: (context, state) {
//           final alarmModel = state.extra as AlarmModel?;
//           return AddAlarmScreen(alarmModel: alarmModel);
//         },
//       ),
//       GoRoute(
//         path: '/settings',
//         name: AppRoute.settings.name,
//         builder: (context, state) => const SettingsScreen(),
//       ),
//       GoRoute(
//         path: '/database',
//         name: AppRoute.database.name,
//         builder: (context, state) => const DatabaseScreen(),
//       ),

//       // Alarm screens (special - might need to work even when locked)
//       GoRoute(
//         path: '/alarmRinging',
//         name: AppRoute.alarmRinging.name,
//         builder:
//             (context, state) => AlarmRingingScreen(
//               alarmSettings: state.extra! as AlarmSettings,
//             ),
//       ),
//       GoRoute(
//         path: '/mathAlarm',
//         name: AppRoute.mathAlarm.name,
//         builder:
//             (context, state) =>
//                 MathAlarmScreen(alarmSettings: state.extra! as AlarmSettings),
//       ),
//       GoRoute(
//         path: '/shakeAlarm',
//         name: AppRoute.shakeAlarm.name,
//         builder:
//             (context, state) =>
//                 ShakeAlarmScreen(alarmSettings: state.extra! as AlarmSettings),
//       ),
//       GoRoute(
//         path: '/retypeAlarm',
//         name: AppRoute.retypeAlarm.name,
//         builder:
//             (context, state) =>
//                 RetypeAlarmScreen(alarmSettings: state.extra! as AlarmSettings),
//       ),
//     ],
//   );
