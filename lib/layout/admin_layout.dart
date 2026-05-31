import 'package:alarm_walker/pages/analytics_page.dart';
import 'package:alarm_walker/pages/dashboard_page.dart';
import 'package:alarm_walker/pages/issue_logs_page.dart';
import 'package:alarm_walker/pages/support_tickets_page.dart';
import 'package:alarm_walker/pages/users_table.dart';
import 'package:alarm_walker/widgets/app_sidebar.dart';
import 'package:flutter/material.dart';

class AdminLayout extends StatefulWidget {
  final String adminEmail;
  final Future<void> Function() onLogout;

  const AdminLayout({
    super.key,
    required this.adminEmail,
    required this.onLogout,
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int selectedIndex = 0;

  final pages = const [
    DashboardPage(),
    UsersTable(),
    AnalyticsPage(),
    IssueLogsPage(),
    SupportTicketsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            selectedIndex: selectedIndex,
            adminEmail: widget.adminEmail,
            onLogout: widget.onLogout,
            onSelect: (index) {
              setState(() => selectedIndex = index);
            },
          ),
          Expanded(
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: pages[selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
