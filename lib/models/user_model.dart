import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String name;
  final String userType; // 'farmer', 'customer', or 'admin'
  final DateTime createdAt;
  final String? photoUrl;
  final String? farmName;
  final String? phone;
  final String? address;
  final String? farmType;
  final String? farmSize;
  final bool suspended;
  final String? suspensionReason;
  final DateTime? suspendedAt;
  final DateTime? suspendedUntil;
  final String? suspendedBy;
  final List<Map<String, dynamic>> suspensionHistory;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.userType,
    required this.createdAt,
    this.photoUrl,
    this.farmName,
    this.phone,
    this.address,
    this.farmType,
    this.farmSize,
    this.suspended = false,
    this.suspensionReason,
    this.suspendedAt,
    this.suspendedUntil,
    this.suspendedBy,
    this.suspensionHistory = const [],
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      userType: data['userType'] ?? 'customer',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      photoUrl: data['photoUrl'],
      farmName: data['farmName'],
      phone: data['phone'],
      address: data['address'],
      farmType: data['farmType'],
      farmSize: data['farmSize'],
      suspended: data['suspended'] ?? false,
      suspensionReason: data['suspensionReason'],
      suspendedAt: data['suspendedAt']?.toDate(),
      suspendedUntil: data['suspendedUntil']?.toDate(),
      suspendedBy: data['suspendedBy'],
      suspensionHistory: List<Map<String, dynamic>>.from(data['suspensionHistory'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'userType': userType,
      'createdAt': createdAt,
      'photoUrl': photoUrl,
      'farmName': farmName,
      'phone': phone,
      'address': address,
      'farmType': farmType,
      'farmSize': farmSize,
      'suspended': suspended,
      'suspensionReason': suspensionReason,
      'suspendedAt': suspendedAt,
      'suspendedUntil': suspendedUntil,
      'suspendedBy': suspendedBy,
      'suspensionHistory': suspensionHistory,
    };
  }
}