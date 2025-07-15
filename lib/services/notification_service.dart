import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Notification service initialized');
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  // Create notification for farmer
  Future<void> createFarmerNotification({
    required String farmerId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationData = {
        'userId': farmerId,
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('notifications').add(notificationData);
      debugPrint('Notification created for farmer: $farmerId');
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  // Get unread notifications count
  Stream<int> getUnreadNotificationsCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('All notifications marked as read for user: $userId');
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // Get notifications for a user
  Stream<QuerySnapshot> getNotificationsForUser(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  // Clear all notifications for a user
  Future<void> clearAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('All notifications cleared for user: $userId');
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
    }
  }
}
