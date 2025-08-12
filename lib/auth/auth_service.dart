import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farming_management/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<AppUser?> get user {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return await _getUserData(user.uid);
    });
  }

  Future<AppUser?> getCurrentUser() async {
    User? user = _auth.currentUser;
    if (user == null) return null;
    return await _getUserData(user.uid);
  }

  Future<bool> isFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasSeenOnboarding') ?? true;
  }

  Future<void> setOnboardingSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', false);
  }

  Future<AppUser?> _getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      return doc.exists ? AppUser.fromFirestore(doc) : null;
    } catch (e) {
      print("Error getting user data: $e");
      return null;
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verify user document exists
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(credential.user!.uid).get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw AuthException('User data not found');
      }

      // Check if user is suspended
      final userData = userDoc.data() as Map<String, dynamic>;
      if (userData['suspended'] == true) {
        await _auth.signOut();
        final suspensionReason =
            userData['suspensionReason'] ?? 'No reason provided';
        final suspendedUntil = userData['suspendedUntil'];

        if (suspendedUntil != null) {
          final suspendedUntilDate = (suspendedUntil as Timestamp).toDate();
          if (suspendedUntilDate.isAfter(DateTime.now())) {
            // Temporary suspension still active
            final daysLeft =
                suspendedUntilDate.difference(DateTime.now()).inDays;
            throw AuthException(
                'Account suspended until ${DateFormat('MMM dd, yyyy').format(suspendedUntilDate)}. Reason: $suspensionReason');
          } else {
            // Suspension period expired, reactivate account
            await _firestore
                .collection('users')
                .doc(credential.user!.uid)
                .update({
              'suspended': false,
              'suspensionReason': null,
              'suspendedUntil': null,
              'suspensionHistory': FieldValue.arrayUnion([
                {
                  'action': 'auto_reactivated',
                  'timestamp': FieldValue.serverTimestamp(),
                  'reason': 'Suspension period expired'
                }
              ])
            });
          }
        } else {
          // Permanent suspension
          throw AuthException(
              'Account permanently suspended. Reason: $suspensionReason');
        }
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code));
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support';
      case 'invalid-credential':
        return 'Invalid credentials provided';
      default:
        return 'Authentication failed: $code';
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String userType,
    String? farmName,
    String? phone,
    String? address,
    String? farmType,
    String? farmSize,
  }) async {
    print('Register function called');
    try {
      // Create user in Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user display name
      await credential.user!.updateDisplayName(name);

      // Create user document in appropriate collection
      final userData = {
        'uid': credential.user!.uid,
        'email': email,
        'name': name,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      };

      if (userType == 'farmer') {
        await _firestore.collection('farmers').doc(credential.user!.uid).set({
          ...userData,
          'farmName': farmName,
          'address': address,
          'farmType': farmType,
          'farmSize': farmSize,
          'stats': {
            'totalProducts': 0,
            'pendingOrders': 0,
            'todayRevenue': 0,
            'monthlyGrowth': 0,
          },
          'recentActivities': [],
        });
      } else {
        await _firestore
            .collection('customers')
            .doc(credential.user!.uid)
            .set(userData);
      }

      // Also create a basic document in the users collection
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userData);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code));
    }
  }

  Future<void> createAdminUser({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      print('Starting admin user creation for: $email');

      // Test Firebase connection first
      try {
        await _firestore.collection('test_connection').doc('test').get();
        print('Firebase connection test successful');
      } catch (e) {
        print('Firebase connection test failed: $e');
        throw AuthException(
            'Cannot connect to database. Please check your internet connection and try again.');
      }

      // Check if admin users already exist - REMOVED RESTRICTION
      // This allows multiple admin users to be created
      final adminQuery = await _firestore.collection('admins').limit(1).get();
      if (adminQuery.docs.isNotEmpty) {
        print(
            'Admin users already exist, but proceeding with creation (multiple admins allowed)');
      } else {
        print('No existing admins found, proceeding with creation');
      }

      // Create user in Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Firebase Auth user created successfully: ${credential.user!.uid}');

      // Update user display name
      await credential.user!.updateDisplayName(name);
      print('Display name updated to: $name');

      // Create admin user document
      final adminData = {
        'uid': credential.user!.uid,
        'email': email,
        'name': name,
        'userType': 'admin',
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'permissions': {
          'canManageUsers': true,
          'canManageProducts': true,
          'canManageOrders': true,
          'canViewAnalytics': true,
          'canManageSystem': true,
        },
        'lastLogin': FieldValue.serverTimestamp(),
      };

      print('Creating admin document in admins collection');
      // Create admin document in admins collection
      await _firestore
          .collection('admins')
          .doc(credential.user!.uid)
          .set(adminData);

      print('Admin document created successfully');

      print('Creating user document in users collection');
      // Also create a basic document in the users collection
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': email,
        'name': name,
        'userType': 'admin',
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('User document created successfully');
      print('Admin user creation completed successfully');
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException caught: ${e.code} - ${e.message}');
      String errorMessage = _getErrorMessage(e.code);
      if (errorMessage.isEmpty) {
        errorMessage = 'Authentication error: ${e.message}';
      }
      throw AuthException(errorMessage);
    } on FirebaseException catch (e) {
      print('FirebaseException caught: ${e.code} - ${e.message}');
      throw AuthException('Database error: ${e.message}');
    } catch (e) {
      print('Unexpected error caught: $e');
      print('Error type: ${e.runtimeType}');
      throw AuthException('Unexpected error: $e');
    }
  }

  Future<void> signOut() => _auth.signOut();

  // Test method to check Firebase connectivity
  Future<bool> testFirebaseConnection() async {
    try {
      await _firestore.collection('test_connection').doc('test').get();
      return true;
    } catch (e) {
      print('Firebase connection test failed: $e');
      return false;
    }
  }

  // User Suspension Management Methods
  Future<void> suspendUser({
    required String userId,
    required String reason,
    DateTime? suspendedUntil,
    String? adminId,
  }) async {
    try {
      final suspensionData = {
        'suspended': true,
        'suspensionReason': reason,
        'suspendedAt': FieldValue.serverTimestamp(),
        'suspendedBy': adminId,
        'suspensionHistory': FieldValue.arrayUnion([
          {
            'action': 'suspended',
            'timestamp': FieldValue.serverTimestamp(),
            'reason': reason,
            'adminId': adminId,
            'suspendedUntil': suspendedUntil,
          }
        ])
      };

      if (suspendedUntil != null) {
        suspensionData['suspendedUntil'] = Timestamp.fromDate(suspendedUntil);
      }

      await _firestore.collection('users').doc(userId).update(suspensionData);
    } catch (e) {
      throw AuthException('Failed to suspend user: $e');
    }
  }

  Future<void> unsuspendUser({
    required String userId,
    required String reason,
    String? adminId,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'suspended': false,
        'suspensionReason': null,
        'suspendedUntil': null,
        'suspensionHistory': FieldValue.arrayUnion([
          {
            'action': 'unsuspended',
            'timestamp': FieldValue.serverTimestamp(),
            'reason': reason,
            'adminId': adminId,
          }
        ])
      });
    } catch (e) {
      throw AuthException('Failed to unsuspend user: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserSuspensionStatus(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'suspended': data['suspended'] ?? false,
          'suspensionReason': data['suspensionReason'],
          'suspendedAt': data['suspendedAt'],
          'suspendedUntil': data['suspendedUntil'],
          'suspendedBy': data['suspendedBy'],
          'suspensionHistory': data['suspensionHistory'] ?? [],
        };
      }
      return null;
    } catch (e) {
      throw AuthException('Failed to get user suspension status: $e');
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}
