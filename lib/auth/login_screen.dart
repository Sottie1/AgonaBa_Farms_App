import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farming_management/auth/auth_service.dart';
import 'package:farming_management/auth/forgot_password.dart';
import 'package:farming_management/auth/register_screen.dart';
import 'package:farming_management/screens/customer_home.dart';
import 'package:farming_management/screens/farmer/farmer_navbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // 1. First authenticate with Firebase Auth
      await authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // 2. Get the current Firebase user
      final user = authService.currentUser;
      if (user == null) {
        throw AuthException("Authentication failed - no user found");
      }

      // 3. Check if user exists in the users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw AuthException("User profile not found in database");
      }

      // 4. Get the user type and navigate accordingly
      final userType = userDoc.data()?['userType'] ?? 'customer';
      
      if (userType == 'farmer') {
        // Verify farmer document exists
        final farmerDoc = await FirebaseFirestore.instance
            .collection('farmers')
            .doc(user.uid)
            .get();
            
        if (!farmerDoc.exists) {
          throw AuthException("Farmer profile not found");
        }
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => FarmerNavBar()),
        );
      } else {
        // Verify customer document exists
        final customerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(user.uid)
            .get();
            
        if (!customerDoc.exists) {
          throw AuthException("Customer profile not found");
        }
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CustomerHome()),
        );
      }

    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed. Please try again.")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 60),
                Image.asset(
                  'assets/farm_logo.png',
                  height: 120,
                ),
                SizedBox(height: 24),
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Login to manage your farm or shop',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 48),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) => 
                      !value!.contains('@') ? 'Enter a valid email' : null,
                ),
                SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) => 
                      value!.isEmpty ? 'Enter your password' : null,
                ),
                SizedBox(height: 8),
                
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ForgotPassword()),
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.green[600]),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[400])),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('OR', style: TextStyle(color: Colors.grey[600])),
                    ),
                    Expanded(child: Divider(color: Colors.grey[400])),
                  ],
                ),
                SizedBox(height: 24),

                // Register Option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? "),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RegisterScreen()),
                      ),
                      child: Text(
                        'Register',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}