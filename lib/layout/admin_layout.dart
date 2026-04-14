import 'package:alarm_walker/pages/analytics_page.dart';
import 'package:alarm_walker/pages/dashboard_page.dart';
import 'package:alarm_walker/pages/users_table.dart';
import 'package:alarm_walker/widgets/app_sidebar.dart';
import 'package:flutter/material.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int selectedIndex = 0;

  final pages = const [DashboardPage(), UsersTable(), AnalyticsPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            selectedIndex: selectedIndex,
            onSelect: (index) {
              setState(() => selectedIndex = index);
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: pages[selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
