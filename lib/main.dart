import 'package:farming_management/auth/auth_service.dart';
import 'package:farming_management/auth/login_screen.dart';
import 'package:farming_management/auth/register_screen.dart';
import 'package:farming_management/models/user_model.dart';
import 'package:farming_management/screens/customer_home.dart';
import 'package:farming_management/screens/farmer/farmer_navbar.dart';
import 'package:farming_management/screens/onboarding_screen.dart';
import 'package:farming_management/screens/splash_screen.dart';
import 'package:farming_management/services/image_service.dart';
import 'package:farming_management/services/cart_service.dart';
import 'package:farming_management/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<ImageService>(
          create: (_) => ImageService(),
        ),
        ChangeNotifierProvider<CartService>(
          create: (_) => CartService(),
        ),
        ChangeNotifierProvider<NotificationService>(
          create: (_) => NotificationService(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farm Management Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: Colors.green[800]),
        ),
      ),
      home: AuthWrapper(),
      routes: {
        '/onboarding': (_) => OnboardingScreen(),
        '/login': (_) => LoginScreen(),
        '/register': (_) => RegisterScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show splash screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }

        // User is logged in - route by type
        if (snapshot.hasData) {
          return FutureBuilder<AppUser?>(
            future: authService.getCurrentUser(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return SplashScreen();
              }

              if (userSnapshot.hasData) {
                final user = userSnapshot.data!;
                return user.userType == 'farmer'
                    ? FarmerNavBar()
                    : CustomerHome();
              }

              return LoginScreen();
            },
          );
        }

        // No user - show onboarding first time, otherwise login
        return FutureBuilder<bool>(
          future: authService.isFirstTimeUser(),
          builder: (context, firstTimeSnapshot) {
            if (firstTimeSnapshot.connectionState == ConnectionState.waiting) {
              return SplashScreen();
            }
            return firstTimeSnapshot.data ?? true
                ? OnboardingScreen()
                : LoginScreen();
          },
        );
      },
    );
  }
}
