import 'package:alarm_walker/models/support_ticket_model.dart';
import 'package:alarm_walker/services/support_ticket_service.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class SupportTicketsPage extends StatefulWidget {
  const SupportTicketsPage({super.key});

  @override
  State<SupportTicketsPage> createState() => _SupportTicketsPageState();
}

class _SupportTicketsPageState extends State<SupportTicketsPage> {
  final _service = SupportTicketService();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final Set<String> _selectedTicketIds = {};
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _ticketsStream;
  bool _isSelectionMode = false;
  String _statusFilter = 'open';
  String _categoryFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _ticketsStream = _service.watchLatestTickets();
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
      stream: _ticketsStream,
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
        final filteredIds = tickets.map((ticket) => ticket.id).toSet();
        _selectedTicketIds.removeWhere((id) => !filteredIds.contains(id));

        final openCount = allTickets.where((ticket) => !ticket.isResolved).length;
        final resolvedCount = allTickets.where((ticket) => ticket.isResolved).length;
        final selectedTickets = tickets
            .where((ticket) => _selectedTicketIds.contains(ticket.id))
            .toList();

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _SupportHeader(openCount: openCount, resolvedCount: resolvedCount),
            const SizedBox(height: 18),
            _SupportFilters(
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              searchQuery: _searchQuery,
              statusFilter: _statusFilter,
              categoryFilter: _categoryFilter,
              isSelectionMode: _isSelectionMode,
              selectedCount: _selectedTicketIds.length,
              hasTickets: tickets.isNotEmpty,
              allSelected: tickets.isNotEmpty && _selectedTicketIds.length == tickets.length,
              onStatusChanged: (value) => setState(() => _statusFilter = value),
              onCategoryChanged: (value) => setState(() => _categoryFilter = value),
              onSearchChanged: (value) {
                setState(() => _searchQuery = value.trim().toLowerCase());
              },
              onEnterSelectionMode: _enterSelectionMode,
              onExitSelectionMode: _exitSelectionMode,
              onSelectAll: () => _selectAll(tickets),
              onClearSelection: () => setState(_selectedTicketIds.clear),
              onCopySelected: selectedTickets.isEmpty ? null : () => _copySelectedSummaries(selectedTickets),
              onMarkResolved: selectedTickets.isEmpty ? null : () => _bulkUpdateStatus(selectedTickets, 'resolved'),
              onReopen: selectedTickets.isEmpty ? null : () => _bulkUpdateStatus(selectedTickets, 'open'),
              onDelete: selectedTickets.isEmpty ? null : () => _confirmBulkDelete(selectedTickets),
            ),
            const SizedBox(height: 18),
            if (tickets.isEmpty)
              const _EmptySupportCard()
            else
              ...tickets.map(
                (ticket) => _SupportTicketCard(
                  ticket: ticket,
                  service: _service,
                  isSelectionMode: _isSelectionMode,
                  isSelected: _isSelectionMode && _selectedTicketIds.contains(ticket.id),
                  onSelectionChanged: (isSelected) => _toggleSelection(ticket.id, isSelected),
                  onCopySummary: () => _copyText(_buildSupportTicketSummary(ticket), 'Support ticket summary copied.'),
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
      ticket.appVersion,
      ticket.buildNumber,
      ticket.buildLabel,
    ].join(' ').toLowerCase();
    final matchesSearch =
        _searchQuery.isEmpty || searchableText.contains(_searchQuery);

    return matchesStatus && matchesCategory && matchesSearch;
  }

  void _enterSelectionMode() {
    setState(() => _isSelectionMode = true);
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedTicketIds.clear();
    });
  }

  void _toggleSelection(String ticketId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedTicketIds.add(ticketId);
      } else {
        _selectedTicketIds.remove(ticketId);
      }
    });
  }

  void _selectAll(List<SupportTicket> tickets) {
    setState(() {
      if (_selectedTicketIds.length == tickets.length) {
        _selectedTicketIds.clear();
      } else {
        _selectedTicketIds
          ..clear()
          ..addAll(tickets.map((ticket) => ticket.id));
      }
    });
  }

  Future<void> _copySelectedSummaries(List<SupportTicket> tickets) async {
    final text = tickets.map(_buildSupportTicketSummary).join('\n\n---\n\n');
    await _copyText(text, '${tickets.length} support ticket summary(s) copied.');
  }

  Future<void> _copyText(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _bulkUpdateStatus(
    List<SupportTicket> tickets,
    String status,
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final ticket in tickets) {
        batch.update(
          FirebaseFirestore.instance
              .collection(SupportTicketService.collectionName)
              .doc(ticket.id),
          {
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
            'resolvedAt': status == 'resolved' ? FieldValue.serverTimestamp() : null,
          },
        );
      }
      await batch.commit();
      setState(() {
        _selectedTicketIds.clear();
        _isSelectionMode = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tickets.length} support ticket(s) updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update selected tickets: $error')),
      );
    }
  }

  Future<void> _confirmBulkDelete(List<SupportTicket> tickets) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete selected support tickets'),
        content: Text('Delete ${tickets.length} selected support ticket(s) from Firestore?'),
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
      for (final ticket in tickets) {
        batch.delete(
          FirebaseFirestore.instance
              .collection(SupportTicketService.collectionName)
              .doc(ticket.id),
        );
      }
      await batch.commit();
      setState(() {
        _selectedTicketIds.clear();
        _isSelectionMode = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tickets.length} support ticket(s) deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete selected tickets: $error')),
      );
    }
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
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String searchQuery;
  final String statusFilter;
  final String categoryFilter;
  final bool isSelectionMode;
  final int selectedCount;
  final bool hasTickets;
  final bool allSelected;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onEnterSelectionMode;
  final VoidCallback onExitSelectionMode;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback? onCopySelected;
  final VoidCallback? onMarkResolved;
  final VoidCallback? onReopen;
  final VoidCallback? onDelete;

  const _SupportFilters({
    required this.searchController,
    required this.searchFocusNode,
    required this.searchQuery,
    required this.statusFilter,
    required this.categoryFilter,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.hasTickets,
    required this.allSelected,
    required this.onStatusChanged,
    required this.onCategoryChanged,
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
                  labelText: 'Search tickets',
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
              label: 'Type',
              value: categoryFilter,
              items: {
                'all': 'All',
                for (final category in SupportTicketCategory.values)
                  category: SupportTicketCategory.labelFor(category),
              },
              onChanged: onCategoryChanged,
            ),
            _SupportSelectionActions(
              isSelectionMode: isSelectionMode,
              selectedCount: selectedCount,
              hasTickets: hasTickets,
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

class _SupportSelectionActions extends StatelessWidget {
  final bool isSelectionMode;
  final int selectedCount;
  final bool hasTickets;
  final bool allSelected;
  final VoidCallback onEnterSelectionMode;
  final VoidCallback onExitSelectionMode;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback? onCopySelected;
  final VoidCallback? onMarkResolved;
  final VoidCallback? onReopen;
  final VoidCallback? onDelete;

  const _SupportSelectionActions({
    required this.isSelectionMode,
    required this.selectedCount,
    required this.hasTickets,
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
        message: hasTickets ? 'Select support tickets' : 'No tickets to select',
        child: IconButton.filledTonal(
          onPressed: hasTickets ? onEnterSelectionMode : null,
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
            tooltip: allSelected ? 'Unselect all visible tickets' : 'Select all visible tickets',
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

class _SupportTicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final SupportTicketService service;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onCopySummary;

  const _SupportTicketCard({
    required this.ticket,
    required this.service,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onCopySummary,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = ticket.isResolved ? Colors.green : AppColors.primary;
    final createdAt = _formatDate(ticket.createdAt);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      color: isSelectionMode && isSelected
          ? AppColors.primary.withValues(alpha: 0.08)
          : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: isSelectionMode && isSelected
              ? AppColors.primary.withValues(alpha: 0.42)
              : Colors.transparent,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(12, 12, 18, 12),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelectionMode) ...[
              Checkbox(
                value: isSelected,
                onChanged: (value) => onSelectionChanged(value ?? false),
              ),
              const SizedBox(width: 2),
            ],
            CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.12),
              child: Icon(_categoryIcon(ticket.category), color: statusColor),
            ),
          ],
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
              if (ticket.buildLabel.trim().isNotEmpty)
                _TicketChip(label: 'v${ticket.buildLabel}', color: Colors.blueGrey),
            ],
          ),
        ),
        trailing: Text(createdAt, style: Theme.of(context).textTheme.bodySmall),
        children: [
          _TicketDetailGrid(
            details: {
              'Ticket ID': ticket.id,
              'User': ticket.userLabel,
              'Type': ticket.categoryLabel,
              'Status': ticket.statusLabel,
              'App Build': ticket.buildLabel.trim().isEmpty ? '-' : ticket.buildLabel,
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: onCopySummary,
                icon: const Icon(Icons.content_copy_rounded),
                label: const Text('Copy Summary'),
              ),
              TextButton.icon(
                onPressed: () => _toggleStatus(context),
                icon: Icon(
                  ticket.isResolved
                      ? Icons.replay_outlined
                      : Icons.check_circle_outline,
                ),
                label: Text(ticket.isResolved ? 'Reopen' : 'Mark Resolved'),
              ),
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
              Text('No matching open support tickets found.'),
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

String _buildSupportTicketSummary(SupportTicket ticket) {
  return [
    'Alarm Walker Support Ticket',
    'Ticket ID: ${ticket.id}',
    'Status: ${ticket.statusLabel}',
    'Type: ${ticket.categoryLabel}',
    if (ticket.rating > 0) 'Rating: ${ticket.rating}/5',
    'User: ${ticket.userLabel}',
    'App Build: ${ticket.buildLabel.trim().isEmpty ? '-' : ticket.buildLabel}',
    'Created: ${_formatDate(ticket.createdAt)}',
    'Message: ${ticket.message}',
  ].join('\n');
}

String _formatDate(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('MMM d, HH:mm').format(value);
}
