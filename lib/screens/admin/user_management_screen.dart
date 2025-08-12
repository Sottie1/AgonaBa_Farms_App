import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:farming_management/auth/auth_service.dart';
import 'package:farming_management/widgets/suspension_dialog.dart';
import 'package:intl/intl.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _search = '';
  String _filterStatus = 'all';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name or email',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (val) => setState(() => _search = val.trim().toLowerCase()),
                ),
                const SizedBox(height: 16),
                
                // Status Filter
                Row(
                  children: [
                    Text(
                      'Filter by status:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All Users',
                              value: 'all',
                              selected: _filterStatus == 'all',
                              onSelected: (value) => setState(() => _filterStatus = value),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Active',
                              value: 'active',
                              selected: _filterStatus == 'active',
                              onSelected: (value) => setState(() => _filterStatus = value),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Suspended',
                              value: 'suspended',
                              selected: _filterStatus == 'suspended',
                              onSelected: (value) => setState(() => _filterStatus = value),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Admins',
                              value: 'admins',
                              selected: _filterStatus == 'admins',
                              onSelected: (value) => setState(() => _filterStatus = value),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final userType = data['userType'] ?? 'customer';
                  final suspended = data['suspended'] ?? false;
                  
                  // Search filter
                  final matchesSearch = _search.isEmpty || 
                      name.contains(_search) || 
                      email.contains(_search);
                  
                  // Status filter
                  bool matchesStatus = true;
                  switch (_filterStatus) {
                    case 'active':
                      matchesStatus = !suspended;
                      break;
                    case 'suspended':
                      matchesStatus = suspended;
                      break;
                    case 'admins':
                      matchesStatus = userType == 'admin';
                      break;
                    default:
                      matchesStatus = true;
                  }
                  
                  return matchesSearch && matchesStatus;
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No users match your filters',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filter criteria',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = users[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isSuspended = data['suspended'] ?? false;
                    final userType = data['userType'] ?? 'customer';
                    
                    return _UserCard(
                      userData: data,
                      userId: doc.id,
                      onAction: _handleAction,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(String action, String userId, Map<String, dynamic> data) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentAdmin = FirebaseAuth.instance.currentUser;

    try {
      setState(() => _isLoading = true);

      switch (action) {
        case 'suspend':
        case 'manage_suspension':
          final result = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (context) => SuspensionDialog(
              userName: data['name'] ?? 'Unknown User',
              userEmail: data['email'] ?? '',
              isCurrentlySuspended: isSuspended(data),
              currentSuspension: getSuspensionData(data),
            ),
          );

          if (result != null) {
            if (result['action'] == 'suspend') {
              await authService.suspendUser(
                userId: userId,
                reason: result['reason'],
                suspendedUntil: result['suspendedUntil'],
                adminId: currentAdmin?.uid,
              );
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result['isTemporary'] 
                          ? 'User temporarily suspended until ${DateFormat('MMM dd, yyyy').format(result['suspendedUntil'])}'
                          : 'User permanently suspended'
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            } else if (result['action'] == 'unsuspend') {
              await authService.unsuspendUser(
                userId: userId,
                reason: result['reason'],
                adminId: currentAdmin?.uid,
              );
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User unsuspended successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          }
          break;

        case 'make_admin':
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'userType': 'admin'});
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User role updated to admin'),
                backgroundColor: Colors.green,
              ),
            );
          }
          break;

        case 'revoke_admin':
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'userType': 'customer'});
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Admin privileges revoked'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          break;

        case 'delete':
          final shouldDelete = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Deletion'),
              content: Text(
                'Are you sure you want to delete ${data['name'] ?? 'this user'}? '
                'This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );

          if (shouldDelete == true) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .delete();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool isSuspended(Map<String, dynamic> data) {
    final suspended = data['suspended'] ?? false;
    if (!suspended) return false;
    
    final suspendedUntil = data['suspendedUntil'];
    if (suspendedUntil != null) {
      final suspendedUntilDate = (suspendedUntil as Timestamp).toDate();
      return suspendedUntilDate.isAfter(DateTime.now());
    }
    
    return true; // Permanent suspension
  }

  Map<String, dynamic>? getSuspensionData(Map<String, dynamic> data) {
    if (!isSuspended(data)) return null;
    
    return {
      'suspensionReason': data['suspensionReason'],
      'suspendedAt': data['suspendedAt'],
      'suspendedUntil': data['suspendedUntil'],
      'suspendedBy': data['suspendedBy'],
    };
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final Function(String) onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
      selectedColor: Colors.red[100],
      checkmarkColor: Colors.red[700],
      labelStyle: TextStyle(
        color: selected ? Colors.red[700] : Colors.grey[700],
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String userId;
  final Function(String, String, Map<String, dynamic>) onAction;

  const _UserCard({
    required this.userData,
    required this.userId,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final name = userData['name'] ?? 'No Name';
    final email = userData['email'] ?? '';
    final userType = userData['userType'] ?? 'customer';
    final suspended = userData['suspended'] ?? false;
    final suspendedUntil = userData['suspendedUntil'];
    final createdAt = userData['createdAt'];
    
    bool isTemporarySuspension = false;
    DateTime? suspensionEndDate;
    
    if (suspended && suspendedUntil != null) {
      suspensionEndDate = (suspendedUntil as Timestamp).toDate();
      isTemporarySuspension = suspensionEndDate.isAfter(DateTime.now());
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Row(
              children: [
                // Avatar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getUserTypeColor(userType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getUserTypeIcon(userType),
                    color: _getUserTypeColor(userType),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Status Badge
                          if (suspended)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isTemporarySuspension ? Colors.orange[100] : Colors.red[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isTemporarySuspension ? Colors.orange[300]! : Colors.red[300]!,
                                ),
                              ),
                              child: Text(
                                isTemporarySuspension ? 'TEMPORARILY SUSPENDED' : 'PERMANENTLY SUSPENDED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isTemporarySuspension ? Colors.orange[700] : Colors.red[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getUserTypeColor(userType).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              userType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getUserTypeColor(userType),
                              ),
                            ),
                          ),
                          if (createdAt != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Joined ${DateFormat('MMM yyyy').format((createdAt as Timestamp).toDate())}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action Menu
                PopupMenuButton<String>(
                  onSelected: (value) => onAction(value, userId, userData),
                  itemBuilder: (context) => [
                    if (suspended)
                      const PopupMenuItem(
                        value: 'manage_suspension',
                        child: Row(
                          children: [
                            Icon(Icons.manage_accounts, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Manage Suspension'),
                          ],
                        ),
                      )
                    else
                      const PopupMenuItem(
                        value: 'suspend',
                        child: Row(
                          children: [
                            Icon(Icons.block, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Suspend User'),
                          ],
                        ),
                      ),
                    if (userType != 'admin')
                      const PopupMenuItem(
                        value: 'make_admin',
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Make Admin'),
                          ],
                        ),
                      )
                    else
                      const PopupMenuItem(
                        value: 'revoke_admin',
                        child: Row(
                          children: [
                            Icon(Icons.person_remove, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Revoke Admin'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete User'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.more_vert, color: Colors.grey),
                  ),
                ),
              ],
            ),
            
            // Suspension Details (if suspended)
            if (suspended) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isTemporarySuspension ? Colors.orange[50] : Colors.red[50],
                  border: Border.all(
                    color: isTemporarySuspension ? Colors.orange[200]! : Colors.red[200]!,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isTemporarySuspension ? Colors.orange[700] : Colors.red[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Suspension Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isTemporarySuspension ? Colors.orange[700] : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (userData['suspensionReason'] != null)
                      Text(
                        'Reason: ${userData['suspensionReason']}',
                        style: TextStyle(
                          color: isTemporarySuspension ? Colors.orange[700] : Colors.red[700],
                        ),
                      ),
                    if (userData['suspendedAt'] != null)
                      Text(
                        'Suspended on: ${DateFormat('MMM dd, yyyy').format((userData['suspendedAt'] as Timestamp).toDate())}',
                        style: TextStyle(
                          color: isTemporarySuspension ? Colors.orange[700] : Colors.red[700],
                        ),
                      ),
                    if (isTemporarySuspension && suspensionEndDate != null)
                      Text(
                        'Will be reactivated on: ${DateFormat('MMM dd, yyyy').format(suspensionEndDate)}',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getUserTypeColor(String userType) {
    switch (userType) {
      case 'admin':
        return Colors.red[700]!;
      case 'farmer':
        return Colors.green[700]!;
      case 'customer':
        return Colors.blue[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  IconData _getUserTypeIcon(String userType) {
    switch (userType) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'farmer':
        return Icons.agriculture;
      case 'customer':
        return Icons.shopping_cart;
      default:
        return Icons.person;
    }
  }
} 