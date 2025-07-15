import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../widgets/product_form_dialog.dart';
import '../../services/image_service.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen>
    with SingleTickerProviderStateMixin {
  String _search = '';
  final ImageService _imageService = ImageService();
  late TabController _tabController;
  Set<String> _selectedPending = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green[800],
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green[800],
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green[800],
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or category',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (val) =>
                  setState(() => _search = val.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All Products Tab
                _buildProductList(filter: null),
                // Pending Approvals Tab
                _buildProductList(filter: false, showBulk: true),
                // Approved Products Tab
                _buildProductList(filter: true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProduct,
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildProductList({bool? filter, bool showBulk = false}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products found'));
        }
        final products = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final category = (data['category'] ?? '').toString().toLowerCase();
          final approved = data['approved'] ?? true;
          final matchesSearch = _search.isEmpty ||
              name.contains(_search) ||
              category.contains(_search);
          if (filter == null) return matchesSearch;
          return matchesSearch && (approved == filter);
        }).toList();
        if (showBulk) {
          // Pending Approvals Tab with bulk actions
          return Column(
            children: [
              if (_selectedPending.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _bulkApproveReject(true),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve Selected'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700]),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _bulkApproveReject(false),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject Selected'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = products[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isSelected = _selectedPending.contains(doc.id);
                    return ListTile(
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedPending.add(doc.id);
                            } else {
                              _selectedPending.remove(doc.id);
                            }
                          });
                        },
                      ),
                      title: Text(data['name'] ?? 'No Name'),
                      subtitle: Text(
                          'Category: ${data['category'] ?? ''}\nPrice: ₵${(data['pricePerUnit'] ?? 0).toString()}\nStock: ${data['stock'] ?? 0}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStatusBadge('Pending',
                              onTap: () => _showApprovalModal(doc, data)),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Product'),
                                    content: Text(
                                        'Are you sure you want to delete "${data['name']}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: TextButton.styleFrom(
                                            foregroundColor: Colors.red),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await FirebaseFirestore.instance
                                      .collection('products')
                                      .doc(doc.id)
                                      .delete();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Product deleted')),
                                  );
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                  value: 'delete', child: Text('Delete')),
                            ],
                            icon: const Icon(Icons.more_vert),
                          ),
                        ],
                      ),
                      onTap: () => _showApprovalModal(doc, data),
                    );
                  },
                ),
              ),
            ],
          );
        }
        // All/Approved Tabs
        return ListView.separated(
          itemCount: products.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = products[index];
            final data = doc.data() as Map<String, dynamic>;
            final approved = data['approved'] ?? true;
            final status = approved ? 'Approved' : 'Pending';
            return ListTile(
              leading: data['imageUrl'] != null && data['imageUrl'] != ''
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        data['imageUrl'],
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          Icon(Icons.shopping_basket, color: Colors.green[900]),
                    ),
              title: Text(data['name'] ?? 'No Name'),
              subtitle: Text(
                  'Category: ${data['category'] ?? ''}\nPrice: ₵${(data['pricePerUnit'] ?? 0).toString()}\nStock: ${data['stock'] ?? 0}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusBadge(status,
                      onTap: !approved
                          ? () => _showApprovalModal(doc, data)
                          : null),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Product'),
                            content: Text(
                                'Are you sure you want to delete "${data['name']}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await FirebaseFirestore.instance
                              .collection('products')
                              .doc(doc.id)
                              .delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Product deleted')),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
                    ],
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
              ),
              onTap: !approved ? () => _showApprovalModal(doc, data) : null,
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status, {VoidCallback? onTap}) {
    Color color;
    switch (status) {
      case 'Approved':
        color = Colors.green;
        break;
      case 'Rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(status,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showApprovalModal(
      QueryDocumentSnapshot doc, Map<String, dynamic> data) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final TextEditingController _feedbackController =
            TextEditingController();
        return AlertDialog(
          title: Text(data['name'] ?? 'Product Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['imageUrl'] != null && data['imageUrl'] != '')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Image.network(data['imageUrl'], height: 120),
                  ),
                Text('Category: ${data['category'] ?? ''}'),
                Text('Price: ₵${(data['pricePerUnit'] ?? 0).toString()}'),
                Text('Stock: ${data['stock'] ?? 0}'),
                if (data['description'] != null && data['description'] != '')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Description: ${data['description']}'),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _feedbackController,
                  decoration: const InputDecoration(
                    labelText: 'Feedback (optional, for rejection)',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: () => _approveRejectProduct(doc, true),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
              child: const Text('Approve'),
            ),
            OutlinedButton(
              onPressed: () => _approveRejectProduct(doc, false,
                  feedback: _feedbackController.text),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    // Optionally handle result
  }

  void _approveRejectProduct(QueryDocumentSnapshot doc, bool approve,
      {String? feedback}) async {
    await FirebaseFirestore.instance.collection('products').doc(doc.id).update({
      'approved': approve,
      if (!approve) 'rejected': true,
      if (!approve && feedback != null && feedback.isNotEmpty)
        'rejectionFeedback': feedback,
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(approve ? 'Product approved' : 'Product rejected')),
    );
  }

  void _bulkApproveReject(bool approve) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final id in _selectedPending) {
      final ref = FirebaseFirestore.instance.collection('products').doc(id);
      batch.update(ref, {
        'approved': approve,
        if (!approve) 'rejected': true,
      });
    }
    await batch.commit();
    setState(() => _selectedPending.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(approve
              ? 'Selected products approved'
              : 'Selected products rejected')),
    );
  }

  void _addProduct() async {
    final result = await showDialog(
      context: context,
      builder: (context) => ProductFormDialog(
        imageService: _imageService,
        initialFarmerId: null, // Admin can set or leave blank
        initialFarmerName: null,
      ),
    );
    if (result != null) {
      // Save new product to Firestore, mark as approved by admin
      await FirebaseFirestore.instance.collection('products').add({
        ...result.toFirestore(),
        'approved': true,
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Product added')));
    }
  }
}
