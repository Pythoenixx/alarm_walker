import 'package:alarm_walker/models/support_ticket_model.dart';
import 'package:alarm_walker/services/support_ticket_service.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SupportTicketsPage extends StatefulWidget {
  const SupportTicketsPage({super.key});

  @override
  State<SupportTicketsPage> createState() => _SupportTicketsPageState();
}

class _SupportTicketsPageState extends State<SupportTicketsPage> {
  final _service = SupportTicketService();
  String _statusFilter = 'all';
  String _categoryFilter = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.watchLatestTickets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _SupportErrorState(message: snapshot.error.toString());
        }

        final allTickets =
            (snapshot.data?.docs ?? []).map(SupportTicket.fromDoc).toList();
        final tickets = allTickets.where(_matchesFilters).toList();
        final openCount = allTickets.where((ticket) => !ticket.isResolved).length;
        final resolvedCount = allTickets.where((ticket) => ticket.isResolved).length;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _SupportHeader(openCount: openCount, resolvedCount: resolvedCount),
            const SizedBox(height: 18),
            _SupportFilters(
              statusFilter: _statusFilter,
              categoryFilter: _categoryFilter,
              onStatusChanged: (value) => setState(() => _statusFilter = value),
              onCategoryChanged: (value) => setState(() => _categoryFilter = value),
              onSearchChanged: (value) {
                setState(() => _searchQuery = value.trim().toLowerCase());
              },
            ),
            const SizedBox(height: 18),
            if (tickets.isEmpty)
              const _EmptySupportCard()
            else
              ...tickets.map(
                (ticket) => _SupportTicketCard(
                  ticket: ticket,
                  service: _service,
                ),
              ),
          ],
        );
      },
    );
  }

  bool _matchesFilters(SupportTicket ticket) {
    final matchesStatus =
        _statusFilter == 'all' ||
        (_statusFilter == 'open' && !ticket.isResolved) ||
        (_statusFilter == 'resolved' && ticket.isResolved);
    final matchesCategory =
        _categoryFilter == 'all' || ticket.category == _categoryFilter;
    final searchableText = [
      ticket.message,
      ticket.categoryLabel,
      ticket.status,
      ticket.userName,
      ticket.userEmail,
      ticket.userId,
    ].join(' ').toLowerCase();
    final matchesSearch =
        _searchQuery.isEmpty || searchableText.contains(_searchQuery);

    return matchesStatus && matchesCategory && matchesSearch;
  }
}

class _SupportHeader extends StatelessWidget {
  final int openCount;
  final int resolvedCount;

  const _SupportHeader({required this.openCount, required this.resolvedCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Support Tickets',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Review user-submitted help requests, alarm problems, and feedback from the mobile app.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        _HeaderCounter(
          icon: Icons.support_agent_outlined,
          label: 'Open',
          value: openCount.toString(),
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _HeaderCounter(
          icon: Icons.check_circle_outline,
          label: 'Resolved',
          value: resolvedCount.toString(),
          color: Colors.green,
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

class _SupportFilters extends StatelessWidget {
  final String statusFilter;
  final String categoryFilter;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSearchChanged;

  const _SupportFilters({
    required this.statusFilter,
    required this.categoryFilter,
    required this.onStatusChanged,
    required this.onCategoryChanged,
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
                  labelText: 'Search tickets',
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
              label: 'Type',
              value: categoryFilter,
              items: {
                'all': 'All',
                for (final category in SupportTicketCategory.values)
                  category: SupportTicketCategory.labelFor(category),
              },
              onChanged: onCategoryChanged,
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

class _SupportTicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final SupportTicketService service;

  const _SupportTicketCard({required this.ticket, required this.service});

  @override
  Widget build(BuildContext context) {
    final statusColor = ticket.isResolved ? Colors.green : AppColors.primary;
    final createdAt = _formatDate(ticket.createdAt);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          child: Icon(_categoryIcon(ticket.category), color: statusColor),
        ),
        title: Text(
          ticket.message,
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
              _TicketChip(label: ticket.categoryLabel, color: Colors.indigo),
              _TicketChip(label: ticket.statusLabel, color: statusColor),
              if (ticket.rating > 0)
                _TicketChip(label: '${ticket.rating}/5 rating', color: Colors.orange),
            ],
          ),
        ),
        trailing: Text(createdAt, style: Theme.of(context).textTheme.bodySmall),
        children: [
          _TicketDetailGrid(
            details: {
              'User': ticket.userLabel,
              'Type': ticket.categoryLabel,
              'Status': ticket.statusLabel,
              'Created': createdAt,
            },
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Full Message',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
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
            child: SelectableText(ticket.message),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _toggleStatus(context),
                icon: Icon(
                  ticket.isResolved
                      ? Icons.replay_outlined
                      : Icons.check_circle_outline,
                ),
                label: Text(ticket.isResolved ? 'Reopen' : 'Mark Resolved'),
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

  Future<void> _toggleStatus(BuildContext context) async {
    try {
      await service.updateStatus(
        ticketId: ticket.id,
        status: ticket.isResolved ? 'open' : 'resolved',
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update ticket status: $error')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete support ticket'),
            content: const Text('Delete this support ticket from Firestore?'),
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
      await service.deleteTicket(ticket.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete support ticket: $error')),
      );
    }
  }
}

class _TicketDetailGrid extends StatelessWidget {
  final Map<String, String> details;

  const _TicketDetailGrid({required this.details});

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
                  SelectableText(
                    entry.value,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}

class _TicketChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TicketChip({required this.label, required this.color});

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

class _EmptySupportCard extends StatelessWidget {
  const _EmptySupportCard();

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
              Icon(Icons.mark_chat_read_outlined, size: 42, color: Colors.green),
              SizedBox(height: 12),
              Text('No matching support tickets found.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportErrorState extends StatelessWidget {
  final String message;

  const _SupportErrorState({required this.message});

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
                'Unable to load support tickets',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
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

IconData _categoryIcon(String category) {
  return switch (category) {
    SupportTicketCategory.alarmProblem => Icons.alarm_off_outlined,
    SupportTicketCategory.accountProblem => Icons.person_off_outlined,
    SupportTicketCategory.backupRestore => Icons.backup_outlined,
    SupportTicketCategory.suggestion => Icons.lightbulb_outline,
    _ => Icons.feedback_outlined,
  };
}

String _formatDate(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('MMM d, HH:mm').format(value);
}
