import 'package:alarm_walker/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelect;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.35)),
        ),
      ),
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
        ],
      ),
    );
  }
}
