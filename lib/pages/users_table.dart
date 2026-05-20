import 'package:alarm_walker/models/profile_category.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsersTable extends StatefulWidget {
  const UsersTable({super.key});

  @override
  State<UsersTable> createState() => _UsersTableState();
}

class _UsersTableState extends State<UsersTable> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Management',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'View registered user records and profile-category information.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Search by name, email, or user ID',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final allDocs = snapshot.data?.docs ?? [];
              final filteredDocs =
                  allDocs.where((doc) {
                    final data = doc.data();
                    final name = _readText(data, 'name').toLowerCase();
                    final email = _readText(data, 'email').toLowerCase();
                    final userId = _readText(data, 'userId', fallback: doc.id).toLowerCase();
                    return name.contains(_searchQuery) ||
                        email.contains(_searchQuery) ||
                        userId.contains(_searchQuery);
                  }).toList();

              if (filteredDocs.isEmpty) {
                return const Center(child: Text('No matching users found.'));
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: DataTable(
                              columnSpacing: 28,
                              headingRowColor: WidgetStateProperty.all(
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                              ),
                              columns: const [
                                DataColumn(label: Text('Name')),
                                DataColumn(label: Text('Email')),
                                DataColumn(label: Text('User ID')),
                                DataColumn(label: Text('Category')),
                                DataColumn(label: Text('Language')),
                                DataColumn(label: Text('Theme')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows:
                                  filteredDocs.map((doc) {
                                    final data = doc.data();
                                    final name = _readText(data, 'name', fallback: 'Unnamed User');
                                    final email = _readText(data, 'email', fallback: 'N/A');
                                    final userId = _readText(data, 'userId', fallback: doc.id);
                                    final language = _readText(data, 'language', fallback: 'en');
                                    final theme = _readText(data, 'theme', fallback: 'system');
                                    final category = ProfileCategory.fromName(
                                      _readText(data, 'profileCategory', fallback: 'adult'),
                                    );

                                    return DataRow(
                                      cells: [
                                        DataCell(Text(name)),
                                        DataCell(Text(email)),
                                        DataCell(SelectableText(userId)),
                                        DataCell(Chip(label: Text(category.label))),
                                        DataCell(Text(language.toUpperCase())),
                                        DataCell(Text(theme)),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'View details',
                                                icon: const Icon(Icons.visibility_outlined),
                                                onPressed: () => _showUserDetails(context, doc.id, data),
                                              ),
                                              IconButton(
                                                tooltip: 'Remove user record',
                                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                onPressed: () => _confirmDelete(context, name, doc.id),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showUserDetails(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final category = ProfileCategory.fromName(
      _readText(data, 'profileCategory', fallback: 'adult'),
    );

    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('User Details'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(label: 'Document ID', value: docId),
                  _DetailRow(label: 'User ID', value: _readText(data, 'userId', fallback: docId)),
                  _DetailRow(label: 'Name', value: _readText(data, 'name', fallback: 'Unnamed User')),
                  _DetailRow(label: 'Email', value: _readText(data, 'email', fallback: 'N/A')),
                  _DetailRow(label: 'Profile Category', value: category.label),
                  _DetailRow(label: 'Language', value: _readText(data, 'language', fallback: 'en').toUpperCase()),
                  _DetailRow(label: 'Theme', value: _readText(data, 'theme', fallback: 'system')),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String name,
    String docId,
  ) async {
    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Remove user record'),
            content: Text(
              'Remove the Firestore record for $name? This does not delete the Firebase Authentication account.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('users').doc(docId).delete();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove record'),
              ),
            ],
          ),
    );
  }

  static String _readText(
    Map<String, dynamic> data,
    String key, {
    String fallback = 'N/A',
  }) {
    final value = data[key];
    if (value == null) return fallback;

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
