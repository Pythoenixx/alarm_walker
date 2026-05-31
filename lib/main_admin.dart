import 'dart:async';

import 'package:alarm_walker/admin_app.dart';
import 'package:alarm_walker/firebase_options.dart';
import 'package:alarm_walker/services/app_issue_log_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // This 'options' argument is what tells the Web build
      // how to talk to your Firebase project.
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppIssueLogService.initialize(appArea: 'admin_panel');
      runApp(const AdminApp());
    },
    (error, stackTrace) {
      unawaited(
        AppIssueLogService.recordError(
          error,
          stackTrace,
          source: 'admin_panel_zone',
        ),
      );
    },
  );
}
