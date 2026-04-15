import 'package:alarm_walker/widgets/stat_card.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      // mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Dashboard', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),

        const Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            StatCard(title: 'Users', value: 'N/A'),
            StatCard(title: 'Logs', value: 'N/A'),
            StatCard(title: 'Issues', value: 'N/A'),
          ],
        ),
      ],
    );
  }
}
