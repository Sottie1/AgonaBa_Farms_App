import 'package:farming_management/auth/auth_service.dart';
import 'package:farming_management/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:farming_management/models/user_model.dart';
import 'edit_farmer_profile.dart';

class FarmerProfileScreen extends StatelessWidget {
  const FarmerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green[800],
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.green),
            onPressed: () async {
              final doc = await FirebaseFirestore.instance
                  .collection('farmers')
                  .doc(user?.uid)
                  .get();
              final farmerData = doc.data() ?? {};
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditFarmerProfileScreen(
                    farmerData: farmerData,
                    user: user,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('farmers')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final farmerData =
              snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: Colors.green[100],
                        backgroundImage: farmerData['photoUrl'] != null
                            ? NetworkImage(farmerData['photoUrl'])
                            : null,
                        child: farmerData['photoUrl'] == null
                            ? const Icon(Icons.person,
                                size: 54, color: Colors.green)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        farmerData['name'] ?? 'Farmer',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        farmerData['farmName'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile Details
                const SizedBox(height: 24),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
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
                        _buildProfileItem(
                            Icons.email, 'Email', user?.email ?? ''),
                        const Divider(),
                        _buildProfileItem(Icons.phone, 'Phone',
                            farmerData['phone'] ?? 'Not provided'),
                        const Divider(),
                        _buildProfileItem(Icons.location_on, 'Address',
                            farmerData['address'] ?? 'Not provided'),
                        const Divider(),
                        _buildProfileItem(Icons.calendar_today, 'Member Since',
                            _formatJoinDate(user?.metadata.creationTime)),
                      ],
                    ),
                  ),
                ),

                // Farm Information
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Farm Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildProfileItem(Icons.business, 'Farm Name',
                            farmerData['farmName'] ?? ''),
                        const Divider(),
                        _buildProfileItem(Icons.agriculture, 'Farm Type',
                            farmerData['farmType'] ?? 'Not specified'),
                        const Divider(),
                        _buildProfileItem(Icons.map, 'Farm Size',
                            farmerData['farmSize'] ?? 'Not specified'),
                      ],
                    ),
                  ),
                ),

                // Logout Button
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      onPressed: () async {
                        await authService.signOut();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      label: const Text('Logout'),
                    ),
                  ),
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

  String _formatJoinDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }
}
