import 'package:cloud_firestore/cloud_firestore.dart';

class FarmNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'new_order', 'order_status', 'system', etc.
  final Map<String, dynamic> data;
  final bool read;
  final DateTime timestamp;
  final DateTime? readAt;

  FarmNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.read,
    required this.timestamp,
    this.readAt,
  });

  factory FarmNotification.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FarmNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'system',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      read: data['read'] ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      readAt: data['readAt']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'read': read,
      'timestamp': FieldValue.serverTimestamp(),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  FarmNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    bool? read,
    DateTime? timestamp,
    DateTime? readAt,
  }) {
    return FarmNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      read: read ?? this.read,
      timestamp: timestamp ?? this.timestamp,
      readAt: readAt ?? this.readAt,
    );
  }
}
