import 'package:farming_management/auth/auth_service.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'image': 'assets/onboarding1.jpg',
      'title': 'Manage Your Farm Products',
      'description':
          'Easily add, edit, and organize your crops and vegetables for better farm management.',
      'color': Color(0xFF4CAF50),
    },
    {
      'image': 'assets/onboarding2.jpg',
      'title': 'Browse & Order Fresh Produce',
      'description':
          'Customers can explore a variety of farm products and place orders directly from local farmers.',
      'color': Color(0xFF2196F3),
    },
    {
      'image': 'assets/onboarding3.jpg',
      'title': 'Track Orders & Sales',
      'description':
          'Stay updated on your orders and sales with real-time notifications and analytics.',
      'color': Color(0xFF673AB7),
    },
    {
      'image': 'assets/onboarding4.jpg',
      'title': 'Promotions & Categories',
      'description':
          'Discover special offers and organize your products by categories for a seamless experience.',
      'color': Color(0xFFFF9800),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen PageView with images
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (int page) {
              setState(() => _currentPage = page);
            },
            itemBuilder: (_, index) {
              return _buildOnboardingPage(_pages[index]);
            },
          ),

          // Bottom controls
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                // Dynamic Page Indicator
                _buildPageIndicator(),
                SizedBox(height: 32),

                // Get Started Button (only on last page)
                if (_currentPage == _pages.length - 1)
                  _buildGetStartedButton(context),

                // Skip Button (not shown on last page)
                if (_currentPage != _pages.length - 1)
                  TextButton(
                    onPressed: () =>
                        _pageController.jumpToPage(_pages.length - 1),
                    child: Text(
                      'SKIP',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(Map<String, dynamic> page) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(page['image']),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              page['title'],
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              page['description'],
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildGetStartedButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () async {
          await AuthService().setOnboardingSeen();
          Navigator.pushReplacementNamed(context, '/login');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
        ),
        child: Text(
          'GET STARTED',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
