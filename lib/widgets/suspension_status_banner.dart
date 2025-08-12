import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SuspensionStatusBanner extends StatelessWidget {
  final Map<String, dynamic> suspensionData;
  final VoidCallback? onContactSupport;

  const SuspensionStatusBanner({
    super.key,
    required this.suspensionData,
    this.onContactSupport,
  });

  @override
  Widget build(BuildContext context) {
    final isTemporary = suspensionData['suspendedUntil'] != null;
    final suspendedUntil = suspensionData['suspendedUntil'];
    final reason = suspensionData['suspensionReason'] ?? 'No reason provided';
    final suspendedAt = suspensionData['suspendedAt'];
    
    DateTime? endDate;
    if (suspendedUntil != null) {
      endDate = (suspendedUntil as Timestamp).toDate();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isTemporary 
              ? [Colors.orange[400]!, Colors.orange[600]!]
              : [Colors.red[400]!, Colors.red[600]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isTemporary ? Colors.orange : Colors.red).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isTemporary ? Icons.schedule : Icons.block,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTemporary ? 'Account Temporarily Suspended' : 'Account Permanently Suspended',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isTemporary && endDate != null)
                      Text(
                        'Will be reactivated on ${DateFormat('MMM dd, yyyy').format(endDate)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Suspension Details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suspension Details',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Reason
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.white.withOpacity(0.8),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reason: $reason',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Suspension Date
                if (suspendedAt != null)
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.white.withOpacity(0.8),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Suspended on: ${DateFormat('MMM dd, yyyy').format((suspendedAt as Timestamp).toDate())}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                
                // Time Remaining (for temporary suspensions)
                if (isTemporary && endDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        color: Colors.white.withOpacity(0.8),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Time remaining: ${_getTimeRemaining(endDate)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              if (onContactSupport != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onContactSupport,
                    icon: const Icon(Icons.support_agent, color: Colors.white),
                    label: const Text(
                      'Contact Support',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              if (onContactSupport != null) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Show more detailed information
                    _showDetailedSuspensionInfo(context);
                  },
                  icon: const Icon(Icons.info),
                  label: const Text('More Info'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: isTemporary ? Colors.orange[600] : Colors.red[600],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeRemaining(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);
    
    if (difference.isNegative) {
      return 'Expired';
    }
    
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    
    if (days > 0) {
      return '$days days, $hours hours';
    } else if (hours > 0) {
      return '$hours hours, $minutes minutes';
    } else {
      return '$minutes minutes';
    }
  }

  void _showDetailedSuspensionInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.orange[700],
            ),
            const SizedBox(width: 8),
            const Text('Suspension Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your account has been suspended by an administrator.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Reason: ${suspensionData['suspensionReason'] ?? 'No reason provided'}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (suspensionData['suspendedAt'] != null)
              Text(
                'Suspended on: ${DateFormat('MMM dd, yyyy HH:mm').format((suspensionData['suspendedAt'] as Timestamp).toDate())}',
              ),
            if (suspensionData['suspendedUntil'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Will be reactivated on: ${DateFormat('MMM dd, yyyy HH:mm').format((suspensionData['suspendedUntil'] as Timestamp).toDate())}',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'If you believe this suspension was made in error, please contact support.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (onContactSupport != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onContactSupport!();
              },
              child: const Text('Contact Support'),
            ),
        ],
      ),
    );
  }
}
