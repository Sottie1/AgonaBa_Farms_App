import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farming_management/models/product_model.dart';
import 'package:farming_management/services/image_service.dart';
import 'dart:io';

class ProductFormDialog extends StatefulWidget {
  final FarmProduct? product;
  final ImageService imageService;
  final String? initialFarmerId;
  final String? initialFarmerName;

  const ProductFormDialog({
    super.key,
    this.product,
    required this.imageService,
    this.initialFarmerId,
    this.initialFarmerName,
  });

  @override
  _ProductFormDialogState createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController();
  final _stockController = TextEditingController();
  final _subCategoryController = TextEditingController();
  final _growthStageController = TextEditingController();
  final _daysToMaturityController = TextEditingController();
  final _seasonController = TextEditingController();
  final _supplierController = TextEditingController();
  final _discountController = TextEditingController();

  String _selectedCategory = '';
  List<String> _categories = [];
  List<String> _subCategories = [];
  List<File> _imageFiles = [];
  bool _isUploading = false;
  bool _isOrganic = false;
  String? _farmerId;
  String? _farmerName;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadCategories();
  }

  void _initializeForm() {
    _farmerId = widget.initialFarmerId ?? widget.product?.farmerId;
    _farmerName = widget.initialFarmerName ?? widget.product?.farmerName;
    _imageFiles = [];
    if (widget.product?.imageUrls != null &&
        widget.product!.imageUrls.isNotEmpty) {
      // Images will be loaded as URLs, not files, so just show as preview
    }

    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.pricePerUnit.toString();
      _unitController.text = widget.product!.unit;
      _stockController.text = widget.product!.stock.toString();
      _selectedCategory = widget.product!.category;
      _subCategoryController.text = widget.product!.subCategory;
      _growthStageController.text = widget.product!.growthStage;
      _daysToMaturityController.text =
          widget.product!.daysToMaturity.toString();
      _seasonController.text = widget.product!.season;
      _supplierController.text = widget.product!.supplier;
      _isOrganic = widget.product!.isOrganic;
      _discountController.text = widget.product!.discount != null
          ? (widget.product!.discount! * 100).toString()
          : '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    _subCategoryController.dispose();
    _growthStageController.dispose();
    _daysToMaturityController.dispose();
    _seasonController.dispose();
    _supplierController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('name')
          .get();

      setState(() {
        _categories =
            snapshot.docs.map((doc) => doc['name'] as String).toList();
        if (_selectedCategory.isEmpty && _categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
        _loadSubCategories();
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      _showErrorSnackbar('Failed to load categories');
    }
  }

  Future<void> _loadSubCategories() async {
    if (_selectedCategory.isEmpty) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('subcategories')
          .where('category', isEqualTo: _selectedCategory)
          .get();

      setState(() {
        _subCategories =
            snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      debugPrint('Error loading subcategories: $e');
    }
  }

  Future<void> _pickImages() async {
    try {
      final images = await widget.imageService.pickMultipleImages();
      if (images != null && images.isNotEmpty) {
        setState(() => _imageFiles.addAll(images));
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      _showErrorSnackbar('Failed to pick images');
    }
  }

  Future<void> _uploadImagesAndSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_farmerId == null) {
      _showErrorSnackbar('Farmer information is missing');
      return;
    }
    if (_imageFiles.isEmpty && (widget.product?.imageUrls.isEmpty ?? true)) {
      _showErrorSnackbar('Please select at least one image for the product');
      return;
    }
    setState(() => _isUploading = true);
    try {
      String productId = widget.product?.id ?? '';
      if (productId.isEmpty) {
        productId = FirebaseFirestore.instance.collection('products').doc().id;
      }
      List<String> imageUrls = [];
      // Upload new images
      for (final file in _imageFiles) {
        final url =
            await widget.imageService.uploadProductImage(file, productId);
        if (url != null) imageUrls.add(url);
      }
      // If editing, keep existing images not removed
      if (widget.product != null && widget.product!.imageUrls.isNotEmpty) {
        imageUrls.insertAll(
            0,
            widget.product!.imageUrls
                .where((url) => !_imageFiles.any((f) => f.path == url)));
      }
      final product = _createProductFromForm(imageUrls, productId);
      if (mounted) Navigator.pop(context, product);
    } catch (e) {
      debugPrint('Product save error: $e');
      _showErrorSnackbar('Failed to save product: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  FarmProduct _createProductFromForm(List<String> imageUrls, String productId) {
    return FarmProduct(
      id: productId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      subCategory: _subCategoryController.text.trim(),
      pricePerUnit: double.parse(_priceController.text),
      unit: _unitController.text.trim(),
      imageUrl: imageUrls.isNotEmpty ? imageUrls[0] : '',
      imageUrls: imageUrls,
      growthStage: _growthStageController.text.trim(),
      daysToMaturity: int.tryParse(_daysToMaturityController.text) ?? 0,
      season: _seasonController.text.trim(),
      rating: widget.product?.rating ?? 0,
      reviewCount: widget.product?.reviewCount ?? 0,
      compatibleCrops: widget.product?.compatibleCrops ?? [],
      commonPests: widget.product?.commonPests ?? [],
      diseases: widget.product?.diseases ?? [],
      careRequirements: widget.product?.careRequirements ?? {},
      isOrganic: _isOrganic,
      harvestDate: widget.product?.harvestDate,
      stock: int.parse(_stockController.text),
      supplier: _supplierController.text.trim(),
      farmerId: _farmerId!,
      farmerName: _farmerName ?? 'Unknown Farm',
      createdAt: widget.product?.createdAt ?? DateTime.now(),
      discount: _discountController.text.isNotEmpty
          ? double.parse(_discountController.text) / 100
          : null,
    );
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_shopping_cart, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.product == null ? 'Add Product' : 'Edit Product',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_farmerName != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person,
                                  color: Colors.green[700], size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Farmer: $_farmerName',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Image upload section
                      Text(
                        'Product Images',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickImages,
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Add Images'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (_imageFiles.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imageFiles.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _imageFiles[index],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(
                                            () => _imageFiles.removeAt(index));
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Product Information
                      Text(
                        'Product Information',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextFormField(
                        controller: _nameController,
                        label: 'Product Name',
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      _buildTextFormField(
                        controller: _descriptionController,
                        label: 'Description',
                        maxLines: 3,
                      ),

                      const SizedBox(height: 16),
                      Text(
                        'Pricing & Stock',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextFormField(
                              controller: _priceController,
                              label: 'Price',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                if (double.tryParse(value!) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextFormField(
                              controller: _unitController,
                              label: 'Unit (kg, lb, etc.)',
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      _buildTextFormField(
                        controller: _discountController,
                        label: 'Discount (%)',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final d = double.tryParse(value);
                            if (d == null || d < 0 || d > 100) {
                              return 'Enter 0-100';
                            }
                          }
                          return null;
                        },
                      ),
                      _buildTextFormField(
                        controller: _stockController,
                        label: 'Stock Quantity',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          if (int.tryParse(value!) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),
                      Text(
                        'Categories',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_categories.isNotEmpty) _buildCategoryDropdown(),
                      const SizedBox(height: 8),
                      _buildTextFormField(
                        controller: _subCategoryController,
                        label: 'Sub-Category',
                      ),

                      const SizedBox(height: 16),
                      Text(
                        'Agricultural Details',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextFormField(
                        controller: _growthStageController,
                        label: 'Growth Stage',
                      ),
                      _buildTextFormField(
                        controller: _daysToMaturityController,
                        label: 'Days to Maturity',
                        keyboardType: TextInputType.number,
                      ),
                      _buildTextFormField(
                        controller: _seasonController,
                        label: 'Season',
                      ),
                      _buildTextFormField(
                        controller: _supplierController,
                        label: 'Supplier',
                      ),

                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Organic Product'),
                        value: _isOrganic,
                        onChanged: _isUploading
                            ? null
                            : (value) {
                                setState(() => _isOrganic = value);
                              },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isUploading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _uploadImagesAndSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save Product'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    int? maxLines,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: _isUploading
          ? null
          : (value) {
              setState(() {
                _selectedCategory = value!;
                _loadSubCategories();
              });
            },
      decoration: const InputDecoration(labelText: 'Category'),
    );
  }
}
