import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'user_management_screen.dart';
import 'product_management_screen.dart';
import 'order_management_screen.dart';
import 'analytics_screen.dart';
import 'notification_management_screen.dart';
import 'admin_profile_screen.dart';
import 'category_management_screen.dart';
import '../../services/category_service.dart';

class AdminNavBar extends StatefulWidget {
  const AdminNavBar({super.key});

  @override
  State<AdminNavBar> createState() => _AdminNavBarState();
}

class _AdminNavBarState extends State<AdminNavBar> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      AdminDashboardScreen(),
      UserManagementScreen(),
      ProductManagementScreen(),
      OrderManagementScreen(),
      CategoryManagementScreen(),
      AnalyticsScreen(),
      NotificationManagementScreen(),
      AdminProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.people), label: 'Users'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.shopping_basket), label: 'Products'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(
            icon: StreamBuilder<int>(
              stream: CategoryService.getCategoriesCount(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Stack(
                  children: [
                    const Icon(Icons.category),
                    if (count > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Categories',
          ),
          const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Analytics'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Notifications'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
