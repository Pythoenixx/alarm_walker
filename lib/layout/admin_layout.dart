import 'package:flutter/material.dart';
import '../pages/dashboard_page.dart';
import '../pages/users_table.dart';
import '../pages/analytics_page.dart';
import '../widgets/app_sidebar.dart';

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
