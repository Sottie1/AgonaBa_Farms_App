import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SuspensionDialog extends StatefulWidget {
  final String userName;
  final String userEmail;
  final bool isCurrentlySuspended;
  final Map<String, dynamic>? currentSuspension;

  const SuspensionDialog({
    super.key,
    required this.userName,
    required this.userEmail,
    this.isCurrentlySuspended = false,
    this.currentSuspension,
  });

  @override
  State<SuspensionDialog> createState() => _SuspensionDialogState();
}

class _SuspensionDialogState extends State<SuspensionDialog> {
  final _reasonController = TextEditingController();
  bool _isTemporary = false;
  DateTime? _suspendedUntil;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentSuspension != null) {
      _reasonController.text = widget.currentSuspension!['suspensionReason'] ?? '';
      if (widget.currentSuspension!['suspendedUntil'] != null) {
        _suspendedUntil = (widget.currentSuspension!['suspendedUntil'] as Timestamp).toDate();
        _isTemporary = true;
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _suspendedUntil ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _suspendedUntil = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.isCurrentlySuspended ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.isCurrentlySuspended ? Icons.check_circle : Icons.block,
                    color: widget.isCurrentlySuspended ? Colors.green[700] : Colors.red[700],
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isCurrentlySuspended ? 'Manage User Suspension' : 'Suspend User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.userName} (${widget.userEmail})',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (widget.isCurrentlySuspended) ...[
              // Current Suspension Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Currently Suspended',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (widget.currentSuspension?['suspensionReason'] != null)
                      Text(
                        'Reason: ${widget.currentSuspension!['suspensionReason']}',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    if (widget.currentSuspension?['suspendedAt'] != null)
                      Text(
                        'Suspended on: ${DateFormat('MMM dd, yyyy').format((widget.currentSuspension!['suspendedAt'] as Timestamp).toDate())}',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    if (widget.currentSuspension?['suspendedUntil'] != null)
                      Text(
                        'Until: ${DateFormat('MMM dd, yyyy').format((widget.currentSuspension!['suspendedUntil'] as Timestamp).toDate())}',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Suspension Type Selection
            Text(
              'Suspension Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Permanent'),
                    subtitle: const Text('Account suspended indefinitely'),
                    value: false,
                    groupValue: _isTemporary,
                    onChanged: (value) => setState(() => _isTemporary = value!),
                    activeColor: Colors.red[700],
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Temporary'),
                    subtitle: const Text('Account suspended until specific date'),
                    value: true,
                    groupValue: _isTemporary,
                    onChanged: (value) => setState(() => _isTemporary = value!),
                    activeColor: Colors.red[700],
                  ),
                ),
              ],
            ),

            // Date Picker for Temporary Suspension
            if (_isTemporary) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Suspension End Date',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _suspendedUntil != null
                                ? DateFormat('MMM dd, yyyy').format(_suspendedUntil!)
                                : 'No date selected',
                            style: TextStyle(
                              fontSize: 16,
                              color: _suspendedUntil != null ? Colors.blue[700] : Colors.grey[600],
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _selectDate,
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('Select Date'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Reason Field
            Text(
              'Suspension Reason',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter the reason for suspension...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red[700]!, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide a reason for suspension';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () {
                      if (_reasonController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please provide a reason for suspension'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (_isTemporary && _suspendedUntil == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a suspension end date'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      Navigator.of(context).pop({
                        'action': widget.isCurrentlySuspended ? 'unsuspend' : 'suspend',
                        'reason': _reasonController.text.trim(),
                        'suspendedUntil': _suspendedUntil,
                        'isTemporary': _isTemporary,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isCurrentlySuspended ? Colors.green[700] : Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            widget.isCurrentlySuspended ? 'Unsuspend User' : 'Suspend User',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
