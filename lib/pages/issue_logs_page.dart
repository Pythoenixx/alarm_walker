import 'dart:async';

import 'package:alarm_walker/services/app_issue_log_service.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class IssueLogsPage extends StatefulWidget {
  const IssueLogsPage({super.key});

  @override
  State<IssueLogsPage> createState() => _IssueLogsPageState();
}

class _IssueLogsPageState extends State<IssueLogsPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final Set<String> _selectedLogIds = {};
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _issueLogsStream;
  bool _isSelectionMode = false;
  String _statusFilter = 'open';
  String _severityFilter = 'all';
  String _searchQuery = '';

  Stream<QuerySnapshot<Map<String, dynamic>>> _issueLogStream() {
    return FirebaseFirestore.instance
        .collection(AppIssueLogService.collectionName)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _issueLogsStream = _issueLogStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _issueLogsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _IssueLogErrorState(message: snapshot.error.toString());
        }

        final docs = snapshot.data?.docs ?? [];
        final filteredDocs = _filterDocs(docs);
        final filteredIds = filteredDocs.map((doc) => doc.id).toSet();
        _selectedLogIds.removeWhere((id) => !filteredIds.contains(id));

        final openCount = docs.where((doc) => _readText(doc.data(), 'status') != 'resolved').length;
        final resolvedCount = docs.where((doc) => _readText(doc.data(), 'status') == 'resolved').length;
        final crashCount = docs.where((doc) => _readText(doc.data(), 'severity') == 'crash').length;
        final selectedDocs = filteredDocs.where((doc) => _selectedLogIds.contains(doc.id)).toList();

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _IssueLogsHeader(
              openCount: openCount,
              resolvedCount: resolvedCount,
              crashCount: crashCount,
            ),
            const SizedBox(height: 18),
            _IssueLogFilters(
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              searchQuery: _searchQuery,
              statusFilter: _statusFilter,
              severityFilter: _severityFilter,
              isSelectionMode: _isSelectionMode,
              selectedCount: _selectedLogIds.length,
              hasLogs: filteredDocs.isNotEmpty,
              allSelected: filteredDocs.isNotEmpty && _selectedLogIds.length == filteredDocs.length,
              onStatusChanged: (value) => setState(() => _statusFilter = value),
              onSeverityChanged: (value) => setState(() => _severityFilter = value),
              onSearchChanged: (value) {
                setState(() => _searchQuery = value.trim().toLowerCase());
              },
              onEnterSelectionMode: _enterSelectionMode,
              onExitSelectionMode: _exitSelectionMode,
              onSelectAll: () => _selectAll(filteredDocs),
              onClearSelection: () => setState(_selectedLogIds.clear),
              onCopySelected: selectedDocs.isEmpty ? null : () => _copySelectedSummaries(selectedDocs),
              onMarkResolved: selectedDocs.isEmpty ? null : () => _bulkUpdateStatus(selectedDocs, 'resolved'),
              onReopen: selectedDocs.isEmpty ? null : () => _bulkUpdateStatus(selectedDocs, 'open'),
              onDelete: selectedDocs.isEmpty ? null : () => _confirmBulkDelete(selectedDocs),
            ),
            const SizedBox(height: 14),
            if (filteredDocs.isEmpty)
              const _EmptyIssueLogsCard()
            else
              ...filteredDocs.map(
                (doc) => _IssueLogCard(
                  doc: doc,
                  isSelectionMode: _isSelectionMode,
                  isSelected: _isSelectionMode && _selectedLogIds.contains(doc.id),
                  onSelectionChanged: (isSelected) => _toggleSelection(doc.id, isSelected),
                  onCopySummary: () => _copyText(_buildIssueSummary(doc), 'Issue summary copied.'),
                  onCopyFullDebug: () => _copyText(_buildFullDebugReport(doc), 'Full debug report copied.'),
                ),
              ),
          ],
        );
      },
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.where((doc) {
      final data = doc.data();
      final status = _readText(data, 'status', fallback: 'open');
      final severity = _readText(data, 'severity', fallback: 'problem');
      final searchableText = [
        _readText(data, 'message'),
        _readText(data, 'error'),
        _readText(data, 'source'),
        _readText(data, 'screen'),
        _readText(data, 'appArea'),
        _readText(data, 'userEmail'),
        _readText(data, 'userId'),
        _readText(data, 'platform'),
        _readText(data, 'appVersion'),
        _readText(data, 'buildNumber'),
        _readText(data, 'buildLabel'),
        _readDetail(data, 'possibleSourceLocation'),
        _readDetail(data, 'relevantWidget'),
        _readDetail(data, 'flutterContext'),
      ].join(' ').toLowerCase();

      final matchesStatus = _statusFilter == 'all' || status == _statusFilter;
      final matchesSeverity = _severityFilter == 'all' || severity == _severityFilter;
      final matchesSearch = _searchQuery.isEmpty || searchableText.contains(_searchQuery);

      return matchesStatus && matchesSeverity && matchesSearch;
    }).toList();
  }

  void _enterSelectionMode() {
    setState(() => _isSelectionMode = true);
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedLogIds.clear();
    });
  }

  void _toggleSelection(String docId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedLogIds.add(docId);
      } else {
        _selectedLogIds.remove(docId);
      }
    });
  }

  void _selectAll(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    setState(() {
      if (_selectedLogIds.length == docs.length) {
        _selectedLogIds.clear();
      } else {
        _selectedLogIds
          ..clear()
          ..addAll(docs.map((doc) => doc.id));
      }
    });
  }

  Future<void> _bulkUpdateStatus(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String status,
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in docs) {
        batch.update(doc.reference, {
          'status': status,
          'resolvedAt': status == 'resolved' ? FieldValue.serverTimestamp() : null,
        });
      }
      await batch.commit();
      setState(() {
        _selectedLogIds.clear();
        _isSelectionMode = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${docs.length} issue log(s) updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update selected logs: $error')),
      );
    }
  }

  Future<void> _confirmBulkDelete(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete selected issue logs'),
        content: Text('Delete ${docs.length} selected issue log(s) from Firestore?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      setState(() {
        _selectedLogIds.clear();
        _isSelectionMode = false;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete selected logs: $error')),
      );
    }
  }

  Future<void> _copySelectedSummaries(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final text = docs.map(_buildIssueSummary).join('\n\n---\n\n');
    await _copyText(text, '${docs.length} issue summary/summaries copied.');
  }

  Future<void> _copyText(String value, String successMessage) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }
}

class _IssueLogsHeader extends StatelessWidget {
  final int openCount;
  final int resolvedCount;
  final int crashCount;

  const _IssueLogsHeader({
    required this.openCount,
    required this.resolvedCount,
    required this.crashCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Problem & Crash Logs',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Review app issues, copy debug summaries, and resolve repeated logs faster.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        _HeaderCounter(
          icon: Icons.report_gmailerrorred_outlined,
          label: 'Open',
          value: openCount.toString(),
          color: Colors.orange,
        ),
        const SizedBox(width: 12),
        _HeaderCounter(
          icon: Icons.check_circle_outline,
          label: 'Resolved',
          value: resolvedCount.toString(),
          color: Colors.green,
        ),
        const SizedBox(width: 12),
        _HeaderCounter(
          icon: Icons.warning_amber_rounded,
          label: 'Crashes',
          value: crashCount.toString(),
          color: Colors.redAccent,
        ),
      ],
    );
  }
}

class _HeaderCounter extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HeaderCounter({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueLogFilters extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String searchQuery;
  final String statusFilter;
  final String severityFilter;
  final bool isSelectionMode;
  final int selectedCount;
  final bool hasLogs;
  final bool allSelected;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onSeverityChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onEnterSelectionMode;
  final VoidCallback onExitSelectionMode;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback? onCopySelected;
  final VoidCallback? onMarkResolved;
  final VoidCallback? onReopen;
  final VoidCallback? onDelete;

  const _IssueLogFilters({
    required this.searchController,
    required this.searchFocusNode,
    required this.searchQuery,
    required this.statusFilter,
    required this.severityFilter,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.hasLogs,
    required this.allSelected,
    required this.onStatusChanged,
    required this.onSeverityChanged,
    required this.onSearchChanged,
    required this.onEnterSelectionMode,
    required this.onExitSelectionMode,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onCopySelected,
    required this.onMarkResolved,
    required this.onReopen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Search logs',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged('');
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onChanged: onSearchChanged,
              ),
            ),
            _FilterDropdown(
              label: 'Status',
              value: statusFilter,
              items: const {
                'all': 'All',
                'open': 'Open',
                'resolved': 'Resolved',
              },
              onChanged: onStatusChanged,
            ),
            _FilterDropdown(
              label: 'Severity',
              value: severityFilter,
              items: const {
                'all': 'All',
                'problem': 'Problem',
                'crash': 'Crash',
              },
              onChanged: onSeverityChanged,
            ),
            _IssueSelectionActions(
              isSelectionMode: isSelectionMode,
              selectedCount: selectedCount,
              hasLogs: hasLogs,
              allSelected: allSelected,
              onEnterSelectionMode: onEnterSelectionMode,
              onExitSelectionMode: onExitSelectionMode,
              onSelectAll: onSelectAll,
              onClearSelection: onClearSelection,
              onCopySelected: onCopySelected,
              onMarkResolved: onMarkResolved,
              onReopen: onReopen,
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}


class _IssueSelectionActions extends StatelessWidget {
  final bool isSelectionMode;
  final int selectedCount;
  final bool hasLogs;
  final bool allSelected;
  final VoidCallback onEnterSelectionMode;
  final VoidCallback onExitSelectionMode;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback? onCopySelected;
  final VoidCallback? onMarkResolved;
  final VoidCallback? onReopen;
  final VoidCallback? onDelete;

  const _IssueSelectionActions({
    required this.isSelectionMode,
    required this.selectedCount,
    required this.hasLogs,
    required this.allSelected,
    required this.onEnterSelectionMode,
    required this.onExitSelectionMode,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onCopySelected,
    required this.onMarkResolved,
    required this.onReopen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    if (!isSelectionMode) {
      return Tooltip(
        message: hasLogs ? 'Select issue logs' : 'No logs to select',
        child: IconButton.filledTonal(
          onPressed: hasLogs ? onEnterSelectionMode : null,
          icon: const Icon(Icons.checklist_rounded),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              selectedCount == 0 ? 'Select' : '$selectedCount',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          _SelectionIconButton(
            tooltip: allSelected ? 'Unselect all visible logs' : 'Select all visible logs',
            icon: allSelected ? Icons.remove_done_outlined : Icons.done_all_outlined,
            color: mutedColor,
            onPressed: onSelectAll,
          ),
          _SelectionIconButton(
            tooltip: 'Clear selection',
            icon: Icons.clear_all_rounded,
            color: mutedColor,
            onPressed: selectedCount == 0 ? null : onClearSelection,
          ),
          _SelectionIconButton(
            tooltip: 'Copy selected summaries',
            icon: Icons.copy_rounded,
            color: mutedColor,
            onPressed: onCopySelected,
          ),
          _SelectionIconButton(
            tooltip: 'Mark selected resolved',
            icon: Icons.check_circle_outline,
            color: Colors.green,
            onPressed: onMarkResolved,
          ),
          _SelectionIconButton(
            tooltip: 'Reopen selected',
            icon: Icons.replay_outlined,
            color: Colors.orange,
            onPressed: onReopen,
          ),
          _SelectionIconButton(
            tooltip: 'Delete selected',
            icon: Icons.delete_outline,
            color: Colors.redAccent,
            onPressed: onDelete,
          ),
          _SelectionIconButton(
            tooltip: 'Done selecting',
            icon: Icons.done_rounded,
            color: AppColors.primary,
            onPressed: onExitSelectionMode,
          ),
        ],
      ),
    );
  }
}

class _SelectionIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _SelectionIconButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: tooltip,
        icon: Icon(icon, size: 20, color: onPressed == null ? null : color),
        onPressed: onPressed,
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        selectedItemBuilder: (context) {
          return items.values.map((label) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList();
        },
        items:
            items.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(
                  entry.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _IssueLogCard extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onCopySummary;
  final VoidCallback onCopyFullDebug;

  const _IssueLogCard({
    required this.doc,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onCopySummary,
    required this.onCopyFullDebug,
  });

  @override
  State<_IssueLogCard> createState() => _IssueLogCardState();
}

class _IssueLogCardState extends State<_IssueLogCard> {
  bool _showStackTrace = false;
  bool _isExpanded = false;
  bool _detailsReady = false;
  Timer? _detailsTimer;

  @override
  void dispose() {
    _detailsTimer?.cancel();
    super.dispose();
  }

  void _handleExpansionChanged(bool expanded) {
    _detailsTimer?.cancel();
    if (!expanded) {
      setState(() {
        _isExpanded = false;
        _detailsReady = false;
        _showStackTrace = false;
      });
      return;
    }

    setState(() {
      _isExpanded = true;
      _detailsReady = false;
    });
    _detailsTimer = Timer(const Duration(milliseconds: 90), () {
      if (!mounted || !_isExpanded) return;
      setState(() => _detailsReady = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data();
    final status = _readText(data, 'status', fallback: 'open');
    final severity = _readText(data, 'severity', fallback: 'problem');
    final message = _readText(data, 'message', fallback: 'No message provided');
    final source = _readText(data, 'source', fallback: 'unknown');
    final appArea = _readText(data, 'appArea', fallback: 'unknown');
    final platform = _readText(data, 'platform', fallback: 'unknown');
    final screen = _readText(data, 'screen', fallback: '');
    final userLabel = _userLabel(data);
    final stackTrace = _readText(data, 'stackTrace', fallback: 'No stack trace saved.');
    final sourceLocation = _readDetail(data, 'possibleSourceLocation');
    final relevantWidget = _readDetail(data, 'relevantWidget');
    final createdAt = _formatCreatedAt(data);
    final buildLabel = _readText(data, 'buildLabel', fallback: '');
    final isResolved = status == 'resolved';
    final severityColor = severity == 'crash' ? Colors.redAccent : Colors.orange;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      color: widget.isSelectionMode && widget.isSelected
          ? AppColors.primary.withValues(alpha: 0.08)
          : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: widget.isSelectionMode && widget.isSelected
              ? AppColors.primary.withValues(alpha: 0.42)
              : Colors.transparent,
        ),
      ),
      child: ExpansionTile(
        maintainState: true,
        onExpansionChanged: _handleExpansionChanged,
        tilePadding: const EdgeInsets.fromLTRB(12, 12, 18, 12),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isSelectionMode) ...[
              Checkbox(
                value: widget.isSelected,
                onChanged: (value) => widget.onSelectionChanged(value ?? false),
              ),
              const SizedBox(width: 2),
            ],
            CircleAvatar(
              backgroundColor: severityColor.withValues(alpha: 0.12),
              child: Icon(
                severity == 'crash'
                    ? Icons.warning_amber_rounded
                    : Icons.report_problem_outlined,
                color: severityColor,
              ),
            ),
          ],
        ),
        title: Text(
          message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LogChip(label: severity.toUpperCase(), color: severityColor),
              _LogChip(
                label: isResolved ? 'RESOLVED' : 'OPEN',
                color: isResolved ? Colors.green : AppColors.primary,
              ),
              _LogChip(label: appArea, color: Colors.blueGrey),
              _LogChip(label: platform, color: Colors.indigo),
              if (buildLabel.trim().isNotEmpty)
                _LogChip(label: 'v$buildLabel', color: Colors.blueGrey),
              if (sourceLocation.isNotEmpty)
                _LogChip(label: 'SOURCE HINT', color: Colors.deepPurple),
            ],
          ),
        ),
        trailing: Text(createdAt, style: Theme.of(context).textTheme.bodySmall),
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: !_detailsReady
                ? const _IssueDetailsLoading()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _IssueDetailGrid(
                        details: {
                          'Issue ID': widget.doc.id,
                          'Source': source,
                          'Screen': screen.isEmpty ? '-' : screen,
                          'Possible File / Line': sourceLocation.isEmpty ? '-' : sourceLocation,
                          'Relevant Widget': relevantWidget.isEmpty ? '-' : relevantWidget,
                          'User': userLabel,
                          'App Build': buildLabel.trim().isEmpty ? '-' : buildLabel,
                          'Created': createdAt,
                        },
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: widget.onCopySummary,
                            icon: const Icon(Icons.content_copy_rounded),
                            label: const Text('Copy Summary'),
                          ),
                          OutlinedButton.icon(
                            onPressed: widget.onCopyFullDebug,
                            icon: const Icon(Icons.bug_report_outlined),
                            label: const Text('Copy Full Debug'),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() => _showStackTrace = !_showStackTrace),
                            icon: Icon(_showStackTrace ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            label: Text(_showStackTrace ? 'Hide Stack Trace' : 'Show Stack Trace'),
                          ),
                          TextButton.icon(
                            onPressed: () => _toggleStatus(context, isResolved),
                            icon: Icon(isResolved ? Icons.replay_outlined : Icons.check_circle_outline),
                            label: Text(isResolved ? 'Reopen' : 'Mark Resolved'),
                          ),
                          TextButton.icon(
                            onPressed: () => _confirmDelete(context),
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            label: const Text('Delete'),
                          ),
                        ],
                      ),
                      if (_showStackTrace) ...[
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Stack Trace',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 360),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              stackTrace,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(BuildContext context, bool isResolved) async {
    try {
      await widget.doc.reference.update({
        'status': isResolved ? 'open' : 'resolved',
        'resolvedAt': isResolved ? null : FieldValue.serverTimestamp(),
      });
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update log status: $error')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete issue log'),
            content: const Text('Delete this issue log from Firestore?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (shouldDelete != true) return;

    try {
      await widget.doc.reference.delete();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete issue log: $error')),
      );
    }
  }
}


class _IssueDetailsLoading extends StatelessWidget {
  const _IssueDetailsLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('issue-details-loading'),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Preparing issue details...',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _IssueDetailGrid extends StatelessWidget {
  final Map<String, String> details;

  const _IssueDetailGrid({required this.details});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children:
          details.entries.map((entry) {
            return Container(
              width: 260,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  SelectableText(entry.value, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }).toList(),
    );
  }
}

class _LogChip extends StatelessWidget {
  final String label;
  final Color color;

  const _LogChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

class _EmptyIssueLogsCard extends StatelessWidget {
  const _EmptyIssueLogsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.verified_outlined, size: 42, color: Colors.green),
              SizedBox(height: 12),
              Text('No matching open issue logs found.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _IssueLogErrorState extends StatelessWidget {
  final String message;

  const _IssueLogErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 42, color: Colors.orange),
              const SizedBox(height: 12),
              Text(
                'Unable to load issue logs',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

String _buildIssueSummary(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data();
  final message = _readText(data, 'message', fallback: 'No message provided');
  final severity = _readText(data, 'severity', fallback: 'problem');
  final source = _readText(data, 'source', fallback: 'unknown');
  final screen = _readText(data, 'screen', fallback: '-');
  final platform = _readText(data, 'platform', fallback: 'unknown');
  final appArea = _readText(data, 'appArea', fallback: 'unknown');
  final status = _readText(data, 'status', fallback: 'open');
  final buildLabel = _readText(data, 'buildLabel', fallback: '');
  final sourceLocation = _readDetail(data, 'possibleSourceLocation');
  final relevantWidget = _readDetail(data, 'relevantWidget');
  final user = _userLabel(data);
  final created = _formatCreatedAt(data);
  final hint = _issueHint(message, screen, source, sourceLocation, relevantWidget);

  return [
    'Alarm Walker Issue Log',
    'Issue ID: ${doc.id}',
    'Severity: $severity',
    'Status: $status',
    'Source: $source',
    'Screen/Context: $screen',
    if (sourceLocation.isNotEmpty) 'Possible Source: $sourceLocation',
    if (relevantWidget.isNotEmpty) 'Relevant Widget: $relevantWidget',
    'Platform: $platform',
    if (buildLabel.trim().isNotEmpty) 'App Build: $buildLabel',
    'App Area: $appArea',
    'User: $user',
    'Created: $created',
    'Message: $message',
    if (hint.isNotEmpty) 'Possible Hint: $hint',
  ].join('\n');
}

String _buildFullDebugReport(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data();
  final error = _readText(data, 'error', fallback: '-');
  final stackTrace = _readText(data, 'stackTrace', fallback: 'No stack trace saved.');
  final diagnostics = _readDetail(data, 'flutterDiagnostics', fallback: '-');
  final details = _detailsText(data['details']);

  return [
    _buildIssueSummary(doc),
    '',
    'Error:',
    error,
    '',
    'Details:',
    details,
    '',
    'Flutter Diagnostics:',
    diagnostics,
    '',
    'Stack Trace:',
    stackTrace,
  ].join('\n');
}

String _issueHint(
  String message,
  String screen,
  String source,
  String sourceLocation,
  String relevantWidget,
) {
  final lower = '$message $screen $source $sourceLocation $relevantWidget'.toLowerCase();
  if (sourceLocation.isNotEmpty) {
    return 'Start by checking $sourceLocation. Use the relevant widget/context above, then test on small screens and large font sizes.';
  }
  if (lower.contains('renderflex overflowed')) {
    return 'Flutter layout overflow. Check small-screen height, large font scale, Row/Column spacing, or missing scroll/flexible widget.';
  }
  if (lower.contains('permission')) {
    return 'Permission-related failure. Check location, notification, storage, or sensor permission flow.';
  }
  if (lower.contains('network') || lower.contains('socket') || lower.contains('timeout')) {
    return 'Network/API failure. Check internet connection, weather API, or Firestore availability.';
  }
  if (lower.contains('sound') || lower.contains('audio') || lower.contains('file')) {
    return 'Audio/file failure. Check custom sound path, deleted files, or asset availability.';
  }
  return '';
}


String _readDetail(
  Map<String, dynamic> data,
  String key, {
  String fallback = '',
}) {
  final details = data['details'];
  if (details is Map) {
    final value = details[key];
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
  return fallback;
}

String _detailsText(Object? details) {
  if (details == null) return '-';
  if (details is Map) {
    if (details.isEmpty) return '-';
    return details.entries.map((entry) => '${entry.key}: ${entry.value}').join('\n');
  }
  return details.toString();
}

String _readText(
  Map<String, dynamic> data,
  String key, {
  String fallback = '',
}) {
  final value = data[key];
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String _userLabel(Map<String, dynamic> data) {
  final email = _readText(data, 'userEmail');
  if (email.isNotEmpty) return email;

  final userId = _readText(data, 'userId');
  if (userId.isNotEmpty) return userId;

  return 'Guest / local user';
}

String _formatCreatedAt(Map<String, dynamic> data) {
  final createdAt = data['createdAt'];
  DateTime? dateTime;

  if (createdAt is Timestamp) {
    dateTime = createdAt.toDate();
  } else {
    final clientCreatedAt = _readText(data, 'clientCreatedAt');
    dateTime = DateTime.tryParse(clientCreatedAt)?.toLocal();
  }

  if (dateTime == null) return '-';
  return DateFormat('dd MMM yyyy, h:mm a').format(dateTime);
}
