import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({super.key});

  @override
  State<NotificationManagementScreen> createState() =>
      _NotificationManagementScreenState();
}

class _NotificationManagementScreenState
    extends State<NotificationManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _target = 'all';
  final List<String> _targets = ['all', 'admin', 'farmer', 'customer'];
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.green[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Send Notification',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bodyController,
                    decoration: const InputDecoration(labelText: 'Message'),
                    maxLines: 2,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _target,
                    items: _targets
                        .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t == 'all'
                                ? 'All Users'
                                : t[0].toUpperCase() + t.substring(1))))
                        .toList(),
                    onChanged: (val) => setState(() => _target = val!),
                    decoration: const InputDecoration(labelText: 'Target'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendNotification,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700]),
                      child: _isSending
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Send Notification'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('Sent Notifications',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('admin_notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No notifications sent'));
                }
                final notifications = snapshot.data!.docs;
                return ListView.separated(
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data =
                        notifications[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading:
                          Icon(Icons.notifications, color: Colors.green[700]),
                      title: Text(data['title'] ?? ''),
                      subtitle: Text(
                          '${data['body'] ?? ''}\nTarget: ${data['target'] ?? 'all'} • ${data['recipientCount'] ?? 0} recipients'),
                      isThreeLine: true,
                      trailing: Text(
                        data['timestamp'] != null
                            ? DateTime.fromMillisecondsSinceEpoch(
                                    (data['timestamp'] as Timestamp)
                                        .millisecondsSinceEpoch)
                                .toLocal()
                                .toString()
                                .substring(0, 16)
                            : '',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
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

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    try {
      // Get users based on target
      QuerySnapshot usersQuery;
      if (_target == 'all') {
        usersQuery = await FirebaseFirestore.instance.collection('users').get();
      } else {
        usersQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('userType', isEqualTo: _target)
            .get();
      }

      if (usersQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No users found for the selected target')),
        );
        return;
      }

      // Create individual notifications for each user
      final batch = FirebaseFirestore.instance.batch();
      final timestamp = FieldValue.serverTimestamp();

      for (final userDoc in usersQuery.docs) {
        final notificationRef =
            FirebaseFirestore.instance.collection('notifications').doc();
        final notification = {
          'userId': userDoc.id,
          'title': _titleController.text.trim(),
          'body': _bodyController.text.trim(),
          'type': 'system',
          'data': {
            'target': _target,
            'sentBy': 'admin',
          },
          'read': false,
          'timestamp': timestamp,
        };
        batch.set(notificationRef, notification);
      }

      // Also save a record of the admin-sent notification
      final adminNotificationRef =
          FirebaseFirestore.instance.collection('admin_notifications').doc();
      final adminNotification = {
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'target': _target,
        'timestamp': timestamp,
        'recipientCount': usersQuery.docs.length,
      };
      batch.set(adminNotificationRef, adminNotification);

      await batch.commit();

      _titleController.clear();
      _bodyController.clear();
      setState(() => _target = 'all');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Notification sent to ${usersQuery.docs.length} users')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send notification: $e')));
    } finally {
      setState(() => _isSending = false);
    }
  }
}
