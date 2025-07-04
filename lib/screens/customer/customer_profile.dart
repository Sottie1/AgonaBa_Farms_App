import 'package:farming_management/auth/auth_service.dart';
import 'package:farming_management/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farming_management/models/user_model.dart';
import 'package:farming_management/screens/customer/edit_profile.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green[800],
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.green),
            onPressed: () async {
              final user = await authService.getCurrentUser();
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(user: user),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<AppUser?>(
        future: authService.getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Please login to view profile'));
          }
          final user = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                CircleAvatar(
                  radius: 54,
                  backgroundColor: Colors.green[100],
                  child: user.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            user.photoUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.person, size: 54, color: Colors.green),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildProfileItem(Icons.email, 'Email', user.email),
                        const Divider(),
                        _buildProfileItem(
                            Icons.phone, 'Phone', user.phone ?? 'Not provided'),
                        const Divider(),
                        _buildProfileItem(
                          Icons.calendar_today,
                          'Member since',
                          user.createdAt.toLocal().toString().substring(0, 10),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text('Sign Out',
                            style: TextStyle(fontSize: 16)),
                        onPressed: () async {
                          await authService.signOut();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.green[700]),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15)),
      contentPadding: EdgeInsets.zero,
    );
  }
}
