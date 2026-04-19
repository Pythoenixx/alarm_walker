import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:alarm_walker/models/alarm_repository.dart';

class DatabaseScreen extends StatefulWidget {
  final AlarmRepository repository;
  const DatabaseScreen({super.key, required this.repository});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  String? _selectedTable;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(title: const Text('Database Admin')),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isDark
                    ? [AppColors.darkScaffold1, AppColors.darkScaffold2]
                    : [AppColors.lightScaffold1, AppColors.lightScaffold2],
          ),
        ),
        child: FutureBuilder<List<String>>(
          future: widget.repository.getUserTables(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final tables = snapshot.data!;
            _selectedTable ??= tables.first;

            return Column(
              children: [
                _tableSelector(tables),
                const Divider(),
                Expanded(child: _tableView()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tableSelector(List<String> tables) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: DropdownButton<String>(
        value: _selectedTable,
        items:
            tables
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
        onChanged: (v) => setState(() => _selectedTable = v),
      ),
    );
  }

  Widget _tableView() {
    return FutureBuilder(
      future: Future.wait([
        widget.repository.getTableColumns(_selectedTable!),
        widget.repository.getTableRows(_selectedTable!),
        widget.repository.getPrimaryKeyColumn(_selectedTable!),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final columns = snapshot.data![0] as List<Map<String, dynamic>>;
        final rows = snapshot.data![1] as List<Map<String, dynamic>>;
        final pkColumn = snapshot.data![2] as String?;

        final columnNames = columns.map((c) => c['name'] as String).toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              context.isDarkMode
                  ? AppColors.darkGradient1
                  : AppColors.lightGradient1,
            ),
            columns: [
              ...columnNames.map(
                (c) => DataColumn(
                  label: Text(
                    c,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const DataColumn(label: Text('Actions')),
            ],
            rows:
                rows.map((row) {
                  final pkValue = pkColumn == null ? null : row[pkColumn];

                  return DataRow(
                    cells: [
                      ...columnNames.map(
                        (c) => DataCell(Text('${row[c] ?? 'NULL'}')),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed:
                              pkValue == null
                                  ? null
                                  : () => _confirmDelete(pkColumn!, pkValue),
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(String pkColumn, dynamic pkValue) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete row'),
            content: Text('Delete where $pkColumn = $pkValue ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await widget.repository.deleteByPrimaryKey(
        table: _selectedTable!,
        pkColumn: pkColumn,
        pkValue: pkValue,
      );
      setState(() {});
    }
  }
}
