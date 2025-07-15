import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.green[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sales Over Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _SalesOverTimeChart(),
            const SizedBox(height: 32),
            const Text('Orders by Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _OrdersByStatusChart(),
            const SizedBox(height: 32),
            const Text('Top Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _TopProductsChart(),
          ],
        ),
      ),
    );
  }
}

class _SalesOverTimeChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
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
          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: List.generate(sortedKeys.length, (i) {
                final key = sortedKeys[i];
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
                      if (value < 0 || value >= sortedKeys.length) return const SizedBox();
                      final key = sortedKeys[value.toInt()];
                      return Text(key.substring(2), style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

class _OrdersByStatusChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final orders = snapshot.data!.docs;
          final Map<String, int> statusCounts = {};
          for (var doc in orders) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? 'Pending').toString();
            statusCounts[status] = (statusCounts[status] ?? 0) + 1;
          }
          final statuses = statusCounts.keys.toList();
          final colors = [Colors.green, Colors.orange, Colors.blue, Colors.purple, Colors.red, Colors.grey];
          return PieChart(
            PieChartData(
              sections: List.generate(statuses.length, (i) {
                final status = statuses[i];
                final count = statusCounts[status]!;
                final total = orders.length;
                return PieChartSectionData(
                  value: count.toDouble(),
                  color: colors[i % colors.length],
                  title: '$status\n${((count / total) * 100).toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          );
        },
      ),
    );
  }
}

class _TopProductsChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final orders = snapshot.data!.docs;
          final Map<String, int> productCounts = {};
          for (var doc in orders) {
            final data = doc.data() as Map<String, dynamic>;
            final items = (data['items'] ?? []) as List;
            for (var item in items) {
              final name = item['name'] ?? 'Unknown';
              final qty = item['quantity'] ?? 1;
              productCounts[name] = (productCounts[name] ?? 0) + (qty is int ? qty : (qty as num).toInt());
            }
          }
          final sorted = productCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final top = sorted.take(5).toList();
          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: List.generate(top.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: top[i].value.toDouble(),
                      color: Colors.blue[700],
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
                      if (value < 0 || value >= top.length) return const SizedBox();
                      return Text(top[value.toInt()].key, style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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