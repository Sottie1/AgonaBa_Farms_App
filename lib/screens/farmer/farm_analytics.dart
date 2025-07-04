import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:farming_management/auth/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FarmAnalyticsScreen extends StatefulWidget {
  const FarmAnalyticsScreen({super.key});

  @override
  State<FarmAnalyticsScreen> createState() => _FarmAnalyticsScreenState();
}

class _FarmAnalyticsScreenState extends State<FarmAnalyticsScreen> {
  late String _farmerId;
  String _selectedPeriod = 'This Month';
  final currencyFormat = NumberFormat.currency(symbol: '₵', decimalDigits: 2);
  final numberFormat = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _farmerId = authService.currentUser?.uid ?? '';
  }

  // Get filtered orders stream based on selected period
  Stream<QuerySnapshot> _getFilteredOrdersStream() {
    print('Fetching orders for farmer: $_farmerId');
    // Simplified query without ordering to avoid index issues
    return FirebaseFirestore.instance
        .collection('orders')
        .where('farmerId', isEqualTo: _farmerId)
        .limit(50) // Limit to recent orders for better performance
        .snapshots();
  }

  // Get filtered products stream based on selected period
  Stream<QuerySnapshot> _getFilteredProductsStream() {
    return FirebaseFirestore.instance
        .collection('products')
        .where('farmerId', isEqualTo: _farmerId)
        .snapshots();
  }

  // Filter orders by date range
  List<QueryDocumentSnapshot> _filterOrdersByPeriod(
      List<QueryDocumentSnapshot> orders) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Last 3 Months':
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    return orders.where((doc) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final createdAtField = data['createdAt'];

        // Handle different timestamp formats
        DateTime createdAt;
        if (createdAtField is Timestamp) {
          createdAt = createdAtField.toDate();
        } else if (createdAtField is DateTime) {
          createdAt = createdAtField;
        } else {
          // If no createdAt field, use document creation time or current time
          createdAt = now;
        }

        return createdAt.isAfter(startDate) &&
            createdAt.isBefore(now.add(const Duration(days: 1)));
      } catch (e) {
        // If there's any error parsing the date, include the order
        print('Error parsing order date: $e');
        return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Farm Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'This Week', child: Text('This Week')),
              const PopupMenuItem(
                  value: 'This Month', child: Text('This Month')),
              const PopupMenuItem(
                  value: 'Last 3 Months', child: Text('Last 3 Months')),
              const PopupMenuItem(value: 'This Year', child: Text('This Year')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedPeriod,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildOverviewCards(),
            const SizedBox(height: 16),
            _buildSalesChart(),
            const SizedBox(height: 16),
            _buildProductPerformance(),
            const SizedBox(height: 16),
            _buildOrderStatusChart(),
            const SizedBox(height: 16),
            _buildTopProducts(),
            const SizedBox(height: 16),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Total Revenue',
                  currencyFormat.format(0.0),
                  Icons.attach_money,
                  Colors.grey,
                  '0%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Total Orders',
                  numberFormat.format(0),
                  Icons.shopping_cart,
                  Colors.grey,
                  '0%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Pending',
                  numberFormat.format(0),
                  Icons.pending,
                  Colors.grey,
                  '',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Completed',
                  numberFormat.format(0),
                  Icons.check_circle,
                  Colors.grey,
                  '0%',
                ),
              ),
            ],
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final allOrders = snapshot.data!.docs;

        // If no orders found, show empty state
        if (allOrders.isEmpty) {
          return Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Total Revenue',
                  currencyFormat.format(0.0),
                  Icons.attach_money,
                  Colors.grey,
                  '0%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Total Orders',
                  numberFormat.format(0),
                  Icons.shopping_cart,
                  Colors.grey,
                  '0%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Pending',
                  numberFormat.format(0),
                  Icons.pending,
                  Colors.grey,
                  '',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Completed',
                  numberFormat.format(0),
                  Icons.check_circle,
                  Colors.grey,
                  '0%',
                ),
              ),
            ],
          );
        }
        print('Total orders fetched: ${allOrders.length}');
        final orders = _filterOrdersByPeriod(allOrders);
        print('Orders after filtering: ${orders.length}');

        final totalRevenue = orders.fold(0.0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          return sum + (data['totalAmount'] ?? 0.0);
        });
        final totalOrders = orders.length;
        final pendingOrders = orders.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'pending';
        }).length;
        final completedOrders = orders.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'delivered';
        }).length;

        // Calculate growth percentages (simplified for demo)
        final revenueGrowth = totalRevenue > 0
            ? '+${(totalRevenue * 0.125).toStringAsFixed(1)}%'
            : '0%';
        final ordersGrowth = totalOrders > 0
            ? '+${(totalOrders * 0.082).toStringAsFixed(1)}%'
            : '0%';
        final completedGrowth = completedOrders > 0
            ? '+${(completedOrders * 0.153).toStringAsFixed(1)}%'
            : '0%';

        return Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Total Revenue',
                currencyFormat.format(totalRevenue),
                Icons.attach_money,
                Colors.green,
                revenueGrowth,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Total Orders',
                numberFormat.format(totalOrders),
                Icons.shopping_cart,
                Colors.blue,
                ordersGrowth,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Pending',
                numberFormat.format(pendingOrders),
                Icons.pending,
                Colors.orange,
                '',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Completed',
                numberFormat.format(completedOrders),
                Icons.check_circle,
                Colors.purple,
                completedGrowth,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverviewCard(
      String title, String value, IconData icon, Color color, String growth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (growth.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    growth,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Sales Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '+15.2%',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Error loading data',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  );
                }

                final allOrders = snapshot.data!.docs;
                final orders = _filterOrdersByPeriod(allOrders);
                final salesData = _generateSalesData(orders);

                if (salesData.isEmpty ||
                    salesData.every((data) => data.amount == 0)) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No sales data available',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'for $_selectedPeriod',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return SfCartesianChart(
                  primaryXAxis: CategoryAxis(
                    majorGridLines: const MajorGridLines(width: 0),
                  ),
                  primaryYAxis: NumericAxis(
                    labelFormat: '{value}₵',
                    majorGridLines:
                        const MajorGridLines(width: 0.5, color: Colors.grey),
                  ),
                  plotAreaBorderWidth: 0,
                  series: <CartesianSeries>[
                    AreaSeries<SalesData, String>(
                      dataSource: salesData,
                      xValueMapper: (SalesData sales, _) => sales.month,
                      yValueMapper: (SalesData sales, _) => sales.amount,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withOpacity(0.3),
                          Colors.green.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderColor: Colors.green,
                      borderWidth: 2,
                    ),
                    LineSeries<SalesData, String>(
                      dataSource: salesData,
                      xValueMapper: (SalesData sales, _) => sales.month,
                      yValueMapper: (SalesData sales, _) => sales.amount,
                      color: Colors.green,
                      width: 3,
                      markerSettings: const MarkerSettings(isVisible: true),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductPerformance() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredProductsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Error loading data',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  );
                }

                final products = snapshot.data!.docs;
                final performanceData = _generatePerformanceData(products);

                return SfCircularChart(
                  legend: Legend(
                    isVisible: true,
                    position: LegendPosition.bottom,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  series: <CircularSeries>[
                    DoughnutSeries<ProductPerformance, String>(
                      dataSource: performanceData,
                      xValueMapper: (ProductPerformance data, _) =>
                          data.product,
                      yValueMapper: (ProductPerformance data, _) =>
                          data.percentage,
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        labelPosition: ChartDataLabelPosition.outside,
                        textStyle: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      pointColorMapper: (ProductPerformance data, _) =>
                          data.color,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _getFilteredOrdersStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Error loading data',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                );
              }

              final allOrders = snapshot.data!.docs;
              final orders = _filterOrdersByPeriod(allOrders);
              final statusData = _generateStatusData(orders);

              if (statusData.isEmpty ||
                  statusData.every((status) => status.count == 0)) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No orders available',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'for $_selectedPeriod',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: statusData
                    .map((status) => _buildStatusItem(status))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(StatusData status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: status.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(status.icon, color: status.color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: status.color,
                  ),
                ),
                Text(
                  '${status.count} orders',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${status.percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Performing Products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _getFilteredProductsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Error loading data',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                );
              }

              final products = snapshot.data!.docs;

              // Sort products by rating and take top 5
              final sortedProducts = products.toList()
                ..sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aRating = aData['rating'] ?? 0.0;
                  final bRating = bData['rating'] ?? 0.0;
                  return bRating.compareTo(aRating);
                });

              return Column(
                children: sortedProducts
                    .take(5)
                    .toList()
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  final doc = entry.value;
                  final data = doc.data() as Map<String, dynamic>;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (data['imageUrl'] != null &&
                            data['imageUrl'].isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: data['imageUrl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? 'Unknown Product',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                currencyFormat
                                    .format(data['pricePerUnit'] ?? 0.0),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '${data['rating']?.toStringAsFixed(1) ?? '0.0'}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Text(
                              '${data['reviewCount'] ?? 0} reviews',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _getFilteredOrdersStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Error loading data',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                );
              }

              final allOrders = snapshot.data!.docs;
              final orders = _filterOrdersByPeriod(allOrders);

              // Sort orders by creation date and take top 5
              final sortedOrders = orders.toList()
                ..sort((a, b) {
                  try {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;

                    final aCreatedAtField = aData['createdAt'];
                    final bCreatedAtField = bData['createdAt'];

                    DateTime aCreatedAt, bCreatedAt;

                    if (aCreatedAtField is Timestamp) {
                      aCreatedAt = aCreatedAtField.toDate();
                    } else if (aCreatedAtField is DateTime) {
                      aCreatedAt = aCreatedAtField;
                    } else {
                      aCreatedAt = DateTime.now();
                    }

                    if (bCreatedAtField is Timestamp) {
                      bCreatedAt = bCreatedAtField.toDate();
                    } else if (bCreatedAtField is DateTime) {
                      bCreatedAt = bCreatedAtField;
                    } else {
                      bCreatedAt = DateTime.now();
                    }

                    return bCreatedAt.compareTo(aCreatedAt);
                  } catch (e) {
                    print('Error sorting orders: $e');
                    return 0;
                  }
                });

              if (sortedOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No recent activity',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'for $_selectedPeriod',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: sortedOrders.take(5).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  DateTime timestamp;
                  try {
                    final createdAtField = data['createdAt'];
                    if (createdAtField is Timestamp) {
                      timestamp = createdAtField.toDate();
                    } else if (createdAtField is DateTime) {
                      timestamp = createdAtField;
                    } else {
                      timestamp = DateTime.now();
                    }
                  } catch (e) {
                    timestamp = DateTime.now();
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.shopping_cart,
                              color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New order received',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Order #${doc.id.substring(0, 8)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(data['totalAmount'] ?? 0.0),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              _formatTimestamp(timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  List<SalesData> _generateSalesData(List<QueryDocumentSnapshot> orders) {
    // Generate real sales data based on selected period
    final now = DateTime.now();
    List<String> labels;
    int periods;

    switch (_selectedPeriod) {
      case 'This Week':
        labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        periods = 7;
        break;
      case 'This Month':
        labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
        periods = 4;
        break;
      case 'Last 3 Months':
        labels = ['Month 1', 'Month 2', 'Month 3'];
        periods = 3;
        break;
      case 'This Year':
        labels = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        periods = 12;
        break;
      default:
        labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
        periods = 4;
    }

    // Group orders by period and calculate revenue
    final salesByPeriod = <String, double>{};
    for (final doc in orders) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final createdAtField = data['createdAt'];
        final amount = data['totalAmount'] ?? 0.0;

        // Handle different timestamp formats
        DateTime createdAt;
        if (createdAtField is Timestamp) {
          createdAt = createdAtField.toDate();
        } else if (createdAtField is DateTime) {
          createdAt = createdAtField;
        } else {
          // If no createdAt field, skip this order
          continue;
        }

        String periodKey;
        switch (_selectedPeriod) {
          case 'This Week':
            periodKey = labels[createdAt.weekday - 1];
            break;
          case 'This Month':
            final weekOfMonth = ((createdAt.day - 1) ~/ 7) + 1;
            periodKey = 'Week $weekOfMonth';
            break;
          case 'Last 3 Months':
            final monthDiff = (now.year - createdAt.year) * 12 +
                (now.month - createdAt.month);
            periodKey = 'Month ${3 - monthDiff}';
            break;
          case 'This Year':
            periodKey = labels[createdAt.month - 1];
            break;
          default:
            periodKey = 'Week 1';
        }

        salesByPeriod[periodKey] = (salesByPeriod[periodKey] ?? 0.0) + amount;
      } catch (e) {
        print('Error processing order for sales data: $e');
        continue;
      }
    }

    // Create sales data for all periods
    return labels.take(periods).map((label) {
      return SalesData(label, salesByPeriod[label] ?? 0.0);
    }).toList();
  }

  List<ProductPerformance> _generatePerformanceData(
      List<QueryDocumentSnapshot> products) {
    if (products.isEmpty) {
      return [
        ProductPerformance('No Products', 100, Colors.grey),
      ];
    }

    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red
    ];
    return products.take(5).map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final index = products.indexOf(doc);
      return ProductPerformance(
        data['name'] ?? 'Unknown',
        (data['rating'] ?? 0.0) * 20, // Convert rating to percentage
        colors[index % colors.length],
      );
    }).toList();
  }

  List<StatusData> _generateStatusData(List<QueryDocumentSnapshot> orders) {
    final statuses = ['pending', 'processing', 'shipped', 'delivered'];
    final statusCounts = <String, int>{};

    for (final doc in orders) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'pending';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    final total = orders.length;
    if (total == 0) {
      return [
        StatusData('No Orders', 0, 0, Icons.inbox, Colors.grey),
      ];
    }

    return statuses.map((status) {
      final count = statusCounts[status] ?? 0;
      final percentage = total > 0 ? (count / total) * 100 : 0.0;

      IconData icon;
      Color color;

      switch (status) {
        case 'pending':
          icon = Icons.access_time;
          color = Colors.orange;
          break;
        case 'processing':
          icon = Icons.settings;
          color = Colors.blue;
          break;
        case 'shipped':
          icon = Icons.local_shipping;
          color = Colors.purple;
          break;
        case 'delivered':
          icon = Icons.check_circle;
          color = Colors.green;
          break;
        default:
          icon = Icons.receipt;
          color = Colors.grey;
      }

      return StatusData(status, count, percentage, icon, color);
    }).toList();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class SalesData {
  SalesData(this.month, this.amount);
  final String month;
  final double amount;
}

class ProductPerformance {
  ProductPerformance(this.product, this.percentage, this.color);
  final String product;
  final double percentage;
  final Color color;
}

class StatusData {
  StatusData(this.status, this.count, this.percentage, this.icon, this.color);
  final String status;
  final int count;
  final double percentage;
  final IconData icon;
  final Color color;
}
