import 'package:farming_management/auth/auth_service.dart';
import 'package:farming_management/models/user_model.dart';
import 'package:farming_management/screens/farmer/category_management.dart';
import 'package:farming_management/screens/farmer/farm_analytics.dart';
import 'package:farming_management/screens/farmer/farmer_dashboard.dart';
import 'package:farming_management/screens/farmer/farmer_profile.dart';
import 'package:farming_management/screens/farmer/order_management.dart';
import 'package:farming_management/screens/farmer/product_management.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';


class FarmerNavBar extends StatefulWidget {
  const FarmerNavBar({super.key});

  @override
  _FarmerNavBarState createState() => _FarmerNavBarState();
}

class _FarmerNavBarState extends State<FarmerNavBar> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FarmerDashboardScreen(),
    const FarmerProductsScreen(),
    const OrdersManagementScreen(),
    const FarmAnalyticsScreen(),
    const FarmerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return StreamBuilder<AppUser?>(
      stream: authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final user = snapshot.data;
        if (user == null || user.userType != 'farmer') {
          // Redirect to login if not authenticated as farmer
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.green[800],
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_basket),
                label: 'Products',
              ),
              BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.clipboardList),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
          floatingActionButton: _currentIndex == 1 // Products tab
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CategoryManagementScreen(),
                      ),
                    );
                  },
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.category),
                )
              : null,
        );
      },
    );
  }
}