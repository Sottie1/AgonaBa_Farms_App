import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farming_management/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      default:
        return 'Authentication failed';
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

  Future<void> signOut() => _auth.signOut();
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}
