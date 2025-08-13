import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'category_management_screen.dart';
import 'product_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color blueAccent = Colors.blue[400]!;
    final Color orangeAccent = Colors.orange[400]!;
    final Color purpleAccent = Colors.purple[400]!;
    final Color tealAccent = Colors.teal[400]!;
    final today = DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard',
            style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green[800],
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.green[800]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, Admin!',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(today, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 28),
            // Stat cards in 2x2 grid, each with a unique color
            Row(
              children: [
                _FirestoreCountStatCard(
                    title: 'Users',
                    icon: Icons.people,
                    color: blueAccent,
                    collection: 'users'),
                const SizedBox(width: 16),
                _FirestoreCountStatCard(
                    title: 'Products',
                    icon: Icons.shopping_basket,
                    color: orangeAccent,
                    collection: 'products'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _FirestoreCountStatCard(
                    title: 'Orders',
                    icon: Icons.receipt_long,
                    color: purpleAccent,
                    collection: 'orders'),
                const SizedBox(width: 16),
                _FirestoreCountStatCard(
                    title: 'Categories',
                    icon: Icons.category,
                    color: tealAccent,
                    collection: 'categories'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _FirestoreSumStatCard(
                    title: 'Sales',
                    icon: Icons.attach_money,
                    color: Colors.indigo[400]!,
                    collection: 'orders',
                    field: 'totalAmount'),
                const SizedBox(width: 16),
                Container(
                  width: 16,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Divider(thickness: 1, color: Colors.grey[200]),
            const SizedBox(height: 24),
            const Text('Recent Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _RecentOrdersList(),
            const SizedBox(height: 32),
            Divider(thickness: 1, color: Colors.grey[200]),
            const SizedBox(height: 24),
            const Text('Recent Activities',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _RecentActivitiesList(),
          ],
        ),
      ),
    );
  }
}

// Stat cards (polished)
class _FirestoreCountStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String collection;
  const _FirestoreCountStatCard(
      {required this.title,
      required this.icon,
      required this.color,
      required this.collection});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(collection).snapshots(),
        builder: (context, snapshot) {
          String value = '...';
          if (snapshot.hasData) {
            value = snapshot.data!.docs.length.toString();
          }
          return _StatCard(
              title: title, value: value, icon: icon, color: color);
        },
      ),
    );
  }
}

class _FirestoreSumStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String collection;
  final String field;
  const _FirestoreSumStatCard(
      {required this.title,
      required this.icon,
      required this.color,
      required this.collection,
      required this.field});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(collection).snapshots(),
        builder: (context, snapshot) {
          String value = '...';
          if (snapshot.hasData) {
            double sum = 0.0;
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              sum += (data[field] ?? 0).toDouble();
            }
            value = '₵${sum.toStringAsFixed(2)}';
          }
          return _StatCard(
              title: title, value: value, icon: icon, color: color);
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.18), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            radius: 24,
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(fontSize: 14, color: Colors.black54)),
        ],
      ),
    );
  }
}

// Recent Orders List
class _RecentOrdersList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data!.docs;
          if (orders.isEmpty) {
            return const Center(child: Text('No recent orders'));
          }
          return ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;
              final date = (data['createdAt'] as Timestamp?)?.toDate();
              return ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.green),
                title: Text('Order #${data['orderNumber'] ?? ''}'),
                subtitle: Text(
                    'Customer: ${data['customerName'] ?? ''}\n₵${(data['totalAmount'] ?? 0).toStringAsFixed(2)} | ${data['status'] ?? 'Pending'}'),
                trailing:
                    Text(date != null ? DateFormat('MMMd').format(date) : ''),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}

// Recent Activities List (placeholder if no activity log)
class _RecentActivitiesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CategoryManagementScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.category),
                  label: const Text('Manage Categories'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ProductManagementScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_basket),
                  label: const Text('Manage Products'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
