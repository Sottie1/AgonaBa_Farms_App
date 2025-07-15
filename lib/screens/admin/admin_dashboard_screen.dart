import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
                _FirestoreSumStatCard(
                    title: 'Sales',
                    icon: Icons.attach_money,
                    color: tealAccent,
                    collection: 'orders',
                    field: 'totalAmount'),
              ],
            ),
            const SizedBox(height: 32),
            Divider(thickness: 1, color: Colors.grey[200]),
            const SizedBox(height: 24),
            const Text('Sales Trend',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _SalesTrendChart(),
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
            child: Icon(icon, color: color, size: 28),
            radius: 24,
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

// Sales Trend Chart (last 6 months)
class _SalesTrendChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final orders = snapshot.data!.docs;
          final Map<String, double> salesByMonth = {};
          for (var doc in orders) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['createdAt'] as Timestamp?)?.toDate();
            final amount = (data['totalAmount'] ?? 0).toDouble();
            if (date != null) {
              final key = DateFormat('yyyy-MM').format(date);
              salesByMonth[key] = (salesByMonth[key] ?? 0) + amount;
            }
          }
          final sortedKeys = salesByMonth.keys.toList()..sort();
          final last6 = sortedKeys.length > 6
              ? sortedKeys.sublist(sortedKeys.length - 6)
              : sortedKeys;
          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: List.generate(last6.length, (i) {
                final key = last6[i];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: salesByMonth[key]!,
                      color: Colors.green[700],
                      width: 18,
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= last6.length)
                        return const SizedBox();
                      final key = last6[value.toInt()];
                      return Text(key.substring(2),
                          style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: false),
            ),
          );
        },
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
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final orders = snapshot.data!.docs;
          if (orders.isEmpty)
            return const Center(child: Text('No recent orders'));
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
    // If you have an activities collection, use it here. Otherwise, show a placeholder.
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          'No recent activities to display.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }
}
