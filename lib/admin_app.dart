import 'package:alarm_walker/layout/admin_layout.dart';
import 'package:alarm_walker/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Panel',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const AdminLayout(),
      debugShowCheckedModeBanner: false,
    );
  }
}
