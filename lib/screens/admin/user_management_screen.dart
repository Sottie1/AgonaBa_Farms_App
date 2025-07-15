import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.green[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (val) => setState(() => _search = val.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found'));
                }
                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  return _search.isEmpty || name.contains(_search) || email.contains(_search);
                }).toList();
                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = users[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Icon(Icons.person, color: Colors.green[900]),
                      ),
                      title: Text(data['name'] ?? 'No Name'),
                      subtitle: Text('${data['email'] ?? ''}\nRole: ${data['userType'] ?? 'customer'}'),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) => _handleAction(value, doc.id, data),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                            value: data['userType'] == 'admin' ? 'revoke_admin' : 'make_admin',
                            child: Text(data['userType'] == 'admin' ? 'Revoke Admin' : 'Make Admin'),
                          ),
                          const PopupMenuItem(value: 'suspend', child: Text('Suspend')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(String action, String userId, Map<String, dynamic> data) async {
    if (action == 'edit') {
      // TODO: Implement edit user
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit user coming soon')));
    } else if (action == 'make_admin' || action == 'revoke_admin') {
      final newRole = action == 'make_admin' ? 'admin' : 'customer';
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'userType': newRole});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User role updated to $newRole')));
    } else if (action == 'suspend') {
      // TODO: Implement suspend (e.g., add a 'suspended' field)
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'suspended': true});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User suspended')));
    } else if (action == 'delete') {
      // TODO: Confirm before deleting
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted')));
    }
  }
} 