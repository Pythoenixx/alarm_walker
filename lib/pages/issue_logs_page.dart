import 'package:alarm_walker/services/app_issue_log_service.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IssueLogsPage extends StatefulWidget {
  const IssueLogsPage({super.key});

  @override
  State<IssueLogsPage> createState() => _IssueLogsPageState();
}

class _IssueLogsPageState extends State<IssueLogsPage> {
  String _statusFilter = 'all';
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
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _issueLogStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _IssueLogErrorState(message: snapshot.error.toString());
        }

        final docs = snapshot.data?.docs ?? [];
        final filteredDocs = _filterDocs(docs);
        final openCount = docs.where((doc) => _readText(doc.data(), 'status') != 'resolved').length;
        final crashCount = docs.where((doc) => _readText(doc.data(), 'severity') == 'crash').length;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _IssueLogsHeader(openCount: openCount, crashCount: crashCount),
            const SizedBox(height: 18),
            _IssueLogFilters(
              statusFilter: _statusFilter,
              severityFilter: _severityFilter,
              onStatusChanged: (value) => setState(() => _statusFilter = value),
              onSeverityChanged: (value) => setState(() => _severityFilter = value),
              onSearchChanged: (value) {
                setState(() => _searchQuery = value.trim().toLowerCase());
              },
            ),
            const SizedBox(height: 18),
            if (filteredDocs.isEmpty)
              const _EmptyIssueLogsCard()
            else
              ...filteredDocs.map((doc) => _IssueLogCard(doc: doc)),
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
      ].join(' ').toLowerCase();

      final matchesStatus = _statusFilter == 'all' || status == _statusFilter;
      final matchesSeverity = _severityFilter == 'all' || severity == _severityFilter;
      final matchesSearch = _searchQuery.isEmpty || searchableText.contains(_searchQuery);

      return matchesStatus && matchesSeverity && matchesSearch;
    }).toList();
  }
}

class _IssueLogsHeader extends StatelessWidget {
  final int openCount;
  final int crashCount;

  const _IssueLogsHeader({required this.openCount, required this.crashCount});

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
                'Monitor Flutter errors, app crashes, and unexpected problems reported by the user app and admin panel.',
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
  final String statusFilter;
  final String severityFilter;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onSeverityChanged;
  final ValueChanged<String> onSearchChanged;

  const _IssueLogFilters({
    required this.statusFilter,
    required this.severityFilter,
    required this.onStatusChanged,
    required this.onSeverityChanged,
    required this.onSearchChanged,
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
                decoration: InputDecoration(
                  labelText: 'Search logs',
                  prefixIcon: const Icon(Icons.search),
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
          ],
        ),
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
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        items:
            items.entries.map((entry) {
              return DropdownMenuItem(value: entry.key, child: Text(entry.value));
            }).toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _IssueLogCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  const _IssueLogCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final status = _readText(data, 'status', fallback: 'open');
    final severity = _readText(data, 'severity', fallback: 'problem');
    final message = _readText(data, 'message', fallback: 'No message provided');
    final source = _readText(data, 'source', fallback: 'unknown');
    final appArea = _readText(data, 'appArea', fallback: 'unknown');
    final platform = _readText(data, 'platform', fallback: 'unknown');
    final screen = _readText(data, 'screen', fallback: '');
    final userLabel = _userLabel(data);
    final stackTrace = _readText(data, 'stackTrace', fallback: 'No stack trace saved.');
    final createdAt = _formatCreatedAt(data);
    final isResolved = status == 'resolved';
    final severityColor = severity == 'crash' ? Colors.redAccent : Colors.orange;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        leading: CircleAvatar(
          backgroundColor: severityColor.withValues(alpha: 0.12),
          child: Icon(
            severity == 'crash'
                ? Icons.warning_amber_rounded
                : Icons.report_problem_outlined,
            color: severityColor,
          ),
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
            ],
          ),
        ),
        trailing: Text(createdAt, style: Theme.of(context).textTheme.bodySmall),
        children: [
          _IssueDetailGrid(
            details: {
              'Source': source,
              'Screen': screen.isEmpty ? '-' : screen,
              'User': userLabel,
              'Created': createdAt,
            },
          ),
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            ),
            child: SelectableText(
              stackTrace,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _toggleStatus(context, isResolved),
                icon: Icon(isResolved ? Icons.replay_outlined : Icons.check_circle_outline),
                label: Text(isResolved ? 'Reopen' : 'Mark Resolved'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(BuildContext context, bool isResolved) async {
    try {
      await doc.reference.update({
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
      await doc.reference.delete();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete issue log: $error')),
      );
    }
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
              Text('No matching issue logs found.'),
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
