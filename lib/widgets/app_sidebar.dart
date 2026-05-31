import 'package:alarm_walker/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final String adminEmail;
  final Future<void> Function() onLogout;
  final Function(int) onSelect;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.adminEmail,
    required this.onLogout,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: NavigationRail(
              backgroundColor: Colors.transparent,
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelect,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: AppColors.primary),
              selectedLabelTextStyle: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_alt_outlined),
                  selectedIcon: Icon(Icons.people_alt),
                  label: Text('Users'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.assessment_outlined),
                  selectedIcon: Icon(Icons.assessment),
                  label: Text('Reports'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.report_gmailerrorred_outlined),
                  selectedIcon: Icon(Icons.report_gmailerrorred),
                  label: Text('Issues'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.support_agent_outlined),
                  selectedIcon: Icon(Icons.support_agent),
                  label: Text('Support'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _AdminAccountFooter(adminEmail: adminEmail, onLogout: onLogout),
        ],
      ),
    );
  }
}

class _AdminAccountFooter extends StatelessWidget {
  final String adminEmail;
  final Future<void> Function() onLogout;

  const _AdminAccountFooter({
    required this.adminEmail,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final email = adminEmail.trim().isEmpty ? 'Admin' : adminEmail.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.45)),
          const SizedBox(height: 8),
          Tooltip(
            message: email,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: const Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _shortEmail(email),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          IconButton.filledTonal(
            tooltip: 'Log out admin',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: const Text('Log out admin?'),
                      content: const Text(
                        'You will need to log in again to access the admin panel.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton.icon(
                          onPressed: () => Navigator.pop(ctx, true),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Log out'),
                        ),
                      ],
                    ),
              );

              if (confirmed == true) {
                await onLogout();
              }
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
    );
  }

  String _shortEmail(String email) {
    if (email.length <= 18) return email;
    final atIndex = email.indexOf('@');
    if (atIndex <= 0) return '${email.substring(0, 15)}...';
    return '${email.substring(0, atIndex)}@...';
  }
}
