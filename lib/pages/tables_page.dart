import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TablesPage extends StatelessWidget {
  const TablesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. The DefaultTabController wraps the whole page to handle the tabs
    return const DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // The visual tabs at the top
          TabBar(
            labelColor:
                Colors.blue, // Added color so it's visible on a light theme
            unselectedLabelColor: Colors.grey,
            tabs: [Tab(text: 'Users'), Tab(text: 'Alarms'), Tab(text: 'Logs')],
          ),
          // 2. The Expanded widget ensures the Tab views take up the rest of the screen
          Expanded(
            child: TabBarView(
              children: [
                // Placeholders for the first two tabs
                _UsersTable(),
                Center(child: Text('Alarms Table (Coming Soon)')),
                Center(child: Text('Log Table (Coming Soon)')),

                // 3. The Logs tab calls a separate widget we created below
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 4. We moved the StreamBuilder into its own widget to keep the code clean
class _UsersTable extends StatefulWidget {
  const _UsersTable();

  @override
  State<_UsersTable> createState() => _UsersTableState();
}

class _UsersTableState extends State<_UsersTable> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Search Bar at the Top
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search Users by Name or ID',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              // 2. Filter Logic
              final allDocs = snapshot.data?.docs ?? [];
              final filteredDocs =
                  allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name']?.toString().toLowerCase() ?? '';
                    final userId =
                        data['userId']?.toString().toLowerCase() ?? '';
                    return name.contains(_searchQuery) ||
                        userId.contains(_searchQuery);
                  }).toList();

              if (filteredDocs.isEmpty) {
                return const Center(child: Text('No matching users found.'));
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: DataTable(
                          // 3. Header Styling
                          headingRowColor: MaterialStateProperty.all(
                            const Color.fromARGB(255, 74, 66, 66),
                          ),
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Name',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'User ID',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Language',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Theme',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Actions',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows:
                              filteredDocs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final name = data['name']?.toString() ?? 'N/A';
                                final userId =
                                    data['userId']?.toString() ?? 'N/A';
                                final language =
                                    data['language']?.toString() ?? 'N/A';
                                final theme =
                                    data['theme']?.toString() ?? 'N/A';

                                return DataRow(
                                  cells: [
                                    DataCell(Text(name)),
                                    DataCell(SelectableText(userId)),
                                    DataCell(Text(language.toUpperCase())),
                                    DataCell(Text(theme)),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => _confirmDelete(
                                              context,
                                              name,
                                              doc.id,
                                            ),
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
              );
            },
          ),
        ),
      ],
    );
  }

  // 4. Delete Confirmation Dialog
  void _confirmDelete(BuildContext context, String name, String docId) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete User'),
            content: Text('Are you sure you want to delete $name?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(docId)
                      .delete();
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
