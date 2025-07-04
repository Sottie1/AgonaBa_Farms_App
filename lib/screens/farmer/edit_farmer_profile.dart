import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditFarmerProfileScreen extends StatefulWidget {
  final Map<String, dynamic> farmerData;
  final User? user;
  const EditFarmerProfileScreen(
      {super.key, required this.farmerData, required this.user});

  @override
  State<EditFarmerProfileScreen> createState() =>
      _EditFarmerProfileScreenState();
}

class _EditFarmerProfileScreenState extends State<EditFarmerProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _farmNameController;
  late TextEditingController _farmTypeController;
  late TextEditingController _farmSizeController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.farmerData['name'] ?? '');
    _phoneController =
        TextEditingController(text: widget.farmerData['phone'] ?? '');
    _addressController =
        TextEditingController(text: widget.farmerData['address'] ?? '');
    _farmNameController =
        TextEditingController(text: widget.farmerData['farmName'] ?? '');
    _farmTypeController =
        TextEditingController(text: widget.farmerData['farmType'] ?? '');
    _farmSizeController =
        TextEditingController(text: widget.farmerData['farmSize'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _farmNameController.dispose();
    _farmTypeController.dispose();
    _farmSizeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(widget.user?.uid)
          .update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'farmName': _farmNameController.text.trim(),
        'farmType': _farmTypeController.text.trim(),
        'farmSize': _farmSizeController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile updated'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green[800],
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person, color: Colors.green),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone, color: Colors.green),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                prefixIcon: const Icon(Icons.location_on, color: Colors.green),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _farmNameController,
              decoration: InputDecoration(
                labelText: 'Farm Name',
                prefixIcon: const Icon(Icons.business, color: Colors.green),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _farmTypeController,
              decoration: InputDecoration(
                labelText: 'Farm Type',
                prefixIcon: const Icon(Icons.agriculture, color: Colors.green),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _farmSizeController,
              decoration: InputDecoration(
                labelText: 'Farm Size',
                prefixIcon: const Icon(Icons.map, color: Colors.green),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
