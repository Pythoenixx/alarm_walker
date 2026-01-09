import 'package:flutter/material.dart';
import 'package:alarm_walker/models/alarm_repository.dart';

class DatabaseScreen extends StatefulWidget {
  final AlarmRepository repository;

  const DatabaseScreen({super.key, required this.repository});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  late Future<List<String>> _tablesFuture;
  String? _selectedTable;

  @override
  void initState() {
    super.initState();
    _tablesFuture = widget.repository.getTables();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Database Admin View')),
      body: FutureBuilder<List<String>>(
        future: _tablesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tables found.'));
          }

          final tables = snapshot.data!;
          _selectedTable ??= tables.first;

          return Column(
            children: [
              _buildTableSelector(tables),
              const Divider(height: 1),
              Expanded(child: _buildTableViewer()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTableSelector(List<String> tables) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          const Text('Table:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selectedTable,
            items:
                tables
                    .map(
                      (table) =>
                          DropdownMenuItem(value: table, child: Text(table)),
                    )
                    .toList(),
            onChanged: (value) {
              setState(() => _selectedTable = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableViewer() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        widget.repository.getTableColumns(_selectedTable!),
        widget.repository.getTableRows(_selectedTable!),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final columns = snapshot.data![0] as List<Map<String, dynamic>>;
        final rows = snapshot.data![1] as List<Map<String, dynamic>>;

        if (columns.isEmpty) {
          return const Center(child: Text('No columns.'));
        }

        return _buildDataTable(columns, rows);
      },
    );
  }

  Widget _buildDataTable(
    List<Map<String, dynamic>> columns,
    List<Map<String, dynamic>> rows,
  ) {
    final columnNames = columns.map((c) => c['name'] as String).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns:
              columnNames
                  .map(
                    (name) => DataColumn(
                      label: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                  .toList(),
          rows:
              rows.map((row) {
                return DataRow(
                  cells:
                      columnNames.map((col) {
                        final value = row[col];
                        return DataCell(Text(value?.toString() ?? 'NULL'));
                      }).toList(),
                );
              }).toList(),
        ),
      ),
    );
  }
}
