import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/alarm_repository.dart';
import 'package:alarm_walker/services/admin_auth_service.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class DatabaseScreen extends StatefulWidget {
  final AlarmRepository repository;
  const DatabaseScreen({super.key, required this.repository});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  late final Future<bool> _adminCheck;
  String? _selectedTable;

  @override
  void initState() {
    super.initState();
    _adminCheck = _isAuthorizedAdmin();
  }

  Future<bool> _isAuthorizedAdmin() async {
    final service = AdminAuthService();
    final user = service.currentUser;
    if (user == null) return false;
    return service.isAuthorizedAdmin(user);
  }

  Future<_TableData> _loadTableData(String table) async {
    final columns = await widget.repository.getTableColumns(table);
    final rows = await widget.repository.getTableRows(table);
    final pkColumn = await widget.repository.getPrimaryKeyColumn(table);
    return _TableData(columns: columns, rows: rows, pkColumn: pkColumn);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBorder : Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor:
            isDark ? AppColors.darkScaffold1 : AppColors.lightScaffold1,
        title: Text(context.tr('Database Admin')),
        titleTextStyle: AppTextStyles.heading(context),
        centerTitle: true,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark
                    ? [AppColors.darkScaffold1, AppColors.darkScaffold2]
                    : [AppColors.lightContainer1, AppColors.lightContainer2],
          ),
        ),
        child: FutureBuilder<bool>(
          future: _adminCheck,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data != true) {
              return _AccessRequiredCard(isDark: isDark);
            }

            return FutureBuilder<List<String>>(
              future: widget.repository.getUserTables(),
              builder: (context, tableSnapshot) {
                if (!tableSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tables = tableSnapshot.data!;
                if (tables.isEmpty) {
                  return _EmptyDatabaseCard(isDark: isDark);
                }

                if (_selectedTable == null || !tables.contains(_selectedTable)) {
                  _selectedTable = tables.first;
                }

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    12,
                    12,
                    12 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderCard(
                        isDark: isDark,
                        tableCount: tables.length,
                      ),
                      const SizedBox(height: 12),
                      _TableSelectorCard(
                        isDark: isDark,
                        tables: tables,
                        selectedTable: _selectedTable!,
                        onChanged:
                            (value) => setState(() => _selectedTable = value),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: FutureBuilder<_TableData>(
                          future: _loadTableData(_selectedTable!),
                          builder: (context, dataSnapshot) {
                            if (!dataSnapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            return _TableViewerCard(
                              isDark: isDark,
                              tableName: _selectedTable!,
                              data: dataSnapshot.data!,
                              onDelete: _confirmDelete,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String pkColumn, dynamic pkValue) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(context.tr('Delete row?')),
            content: Text(
              context.tr(
                'This will permanently delete the selected database row. Use this only for admin testing or cleanup.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr('Cancel')),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.delete_outline),
                label: Text(context.tr('Delete')),
              ),
            ],
          ),
    );

    if (confirmed != true || _selectedTable == null) return;

    await widget.repository.deleteByPrimaryKey(
      table: _selectedTable!,
      pkColumn: pkColumn,
      pkValue: pkValue,
    );
    if (!mounted) return;
    setState(() {});
  }
}

class _TableData {
  final List<Map<String, dynamic>> columns;
  final List<Map<String, dynamic>> rows;
  final String? pkColumn;

  const _TableData({
    required this.columns,
    required this.rows,
    required this.pkColumn,
  });
}

class _HeaderCard extends StatelessWidget {
  final bool isDark;
  final int tableCount;

  const _HeaderCard({required this.isDark, required this.tableCount});

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? AppColors.darkBackgroundText : AppColors.lightBackgroundText;

    return _SoftCard(
      isDark: isDark,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('Local Database Viewer'),
                  style: AppTextStyles.heading(context).copyWith(fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr(
                    'Admin-only view for checking local alarm, settings, and wake log records.',
                  ),
                  style: AppTextStyles.caption(context).copyWith(color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _MetricPill(
            label: context.tr('Tables'),
            value: '$tableCount',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _TableSelectorCard extends StatelessWidget {
  final bool isDark;
  final List<String> tables;
  final String selectedTable;
  final ValueChanged<String?> onChanged;

  const _TableSelectorCard({
    required this.isDark,
    required this.tables,
    required this.selectedTable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      isDark: isDark,
      child: DropdownButtonFormField<String>(
        value: selectedTable,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: context.tr('Select table'),
          prefixIcon: const Icon(Icons.table_chart_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        items:
            tables
                .map(
                  (table) => DropdownMenuItem(
                    value: table,
                    child: Text(table, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _TableViewerCard extends StatelessWidget {
  final bool isDark;
  final String tableName;
  final _TableData data;
  final Future<void> Function(String pkColumn, dynamic pkValue) onDelete;

  const _TableViewerCard({
    required this.isDark,
    required this.tableName,
    required this.data,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final columnNames = data.columns.map((c) => c['name'] as String).toList();
    final muted =
        isDark ? AppColors.darkBackgroundText : AppColors.lightBackgroundText;

    return _SoftCard(
      isDark: isDark,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tableName,
                        style: AppTextStyles.body(context).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr(
                          '{rows} rows · {columns} columns',
                          {
                            'rows': data.rows.length,
                            'columns': columnNames.length,
                          },
                        ),
                        style: AppTextStyles.caption(context).copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (data.pkColumn == null)
                  _WarningPill(label: context.tr('No primary key'))
                else
                  _MetricPill(
                    label: context.tr('PK'),
                    value: data.pkColumn!,
                    isDark: isDark,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child:
                data.rows.isEmpty
                    ? Center(
                      child: Text(
                        context.tr('No rows in this table yet.'),
                        style: AppTextStyles.caption(context).copyWith(
                          color: muted,
                        ),
                      ),
                    )
                    : SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(12),
                        child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                AppColors.primary.withValues(alpha: 0.10),
                              ),
                              columns: [
                                ...columnNames.map(
                                  (column) => DataColumn(
                                    label: Text(
                                      column,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataColumn(label: Text(context.tr('Actions'))),
                              ],
                              rows:
                                  data.rows.map((row) {
                                    final pkValue =
                                        data.pkColumn == null
                                            ? null
                                            : row[data.pkColumn];

                                    return DataRow(
                                      cells: [
                                        ...columnNames.map(
                                          (column) => DataCell(
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 220,
                                              ),
                                              child: SelectableText(
                                                '${row[column] ?? 'NULL'}',
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          IconButton.filledTonal(
                                            tooltip: context.tr('Delete row'),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            onPressed:
                                                pkValue == null ||
                                                        data.pkColumn == null
                                                    ? null
                                                    : () => onDelete(
                                                      data.pkColumn!,
                                                      pkValue,
                                                    ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SoftCard({
    required this.isDark,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [AppColors.darkClock1, AppColors.darkScaffold1]
                  : [AppColors.lightScaffold1, AppColors.lightGradient2],
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(8, 10),
            blurRadius: 18,
            spreadRadius: -10,
            color:
                isDark
                    ? AppColors.shadowDark.withValues(alpha: 0.65)
                    : AppColors.shadowLight.withValues(alpha: 0.50),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.caption(context).copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(value, style: AppTextStyles.caption(context)),
        ],
      ),
    );
  }
}

class _WarningPill extends StatelessWidget {
  final String label;

  const _WarningPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(context).copyWith(
          color: Colors.orange.shade800,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AccessRequiredCard extends StatelessWidget {
  final bool isDark;

  const _AccessRequiredCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _SoftCard(
          isDark: isDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                color: AppColors.primary,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('Admin access required'),
                style: AppTextStyles.heading(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(
                  'This local database viewer is only shown to accounts with the admin role.',
                ),
                style: AppTextStyles.caption(context),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDatabaseCard extends StatelessWidget {
  final bool isDark;

  const _EmptyDatabaseCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _SoftCard(
          isDark: isDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.table_rows_outlined,
                color: AppColors.primary,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('No local database tables found'),
                style: AppTextStyles.heading(context),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
