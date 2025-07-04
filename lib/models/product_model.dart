import 'package:cloud_firestore/cloud_firestore.dart';

class FarmProduct {
  final String id;
  final String name;
  final String description;
  final String category;
  final String subCategory;
  final double pricePerUnit;
  final String unit;
  final String imageUrl;
  final List<String> imageUrls;
  final String growthStage;
  final int daysToMaturity;
  final String season;
  final double rating;
  final int reviewCount;
  final List<String> compatibleCrops;
  final List<String> commonPests;
  final List<String> diseases;
  final Map<String, dynamic> careRequirements;
  final bool isOrganic;
  final DateTime? harvestDate;
  final int stock;
  final String supplier;
  final String farmerId; // Added farmer association
  final String farmerName; // Added farmer name for display
  final DateTime createdAt;
  final double? discount; // Discount percentage (e.g., 0.2 for 20%)

  FarmProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.subCategory,
    required this.pricePerUnit,
    required this.unit,
    required this.imageUrl,
    required this.imageUrls,
    required this.growthStage,
    required this.daysToMaturity,
    required this.season,
    required this.rating,
    required this.reviewCount,
    required this.compatibleCrops,
    required this.commonPests,
    required this.diseases,
    required this.careRequirements,
    required this.isOrganic,
    this.harvestDate,
    required this.stock,
    required this.supplier,
    required this.farmerId,
    required this.farmerName,
    required this.createdAt,
    this.discount,
  });

  factory FarmProduct.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final List<String> imageUrls = data['imageUrls'] != null
        ? List<String>.from(data['imageUrls'])
        : (data['imageUrl'] != null && data['imageUrl'] != ''
            ? [data['imageUrl']]
            : []);
    return FarmProduct(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      subCategory: data['subCategory'] ?? '',
      pricePerUnit: (data['pricePerUnit'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      imageUrl: imageUrls.isNotEmpty ? imageUrls[0] : '',
      imageUrls: imageUrls,
      growthStage: data['growthStage'] ?? '',
      daysToMaturity: data['daysToMaturity'] ?? 0,
      season: data['season'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      compatibleCrops: List<String>.from(data['compatibleCrops'] ?? []),
      commonPests: List<String>.from(data['commonPests'] ?? []),
      diseases: List<String>.from(data['diseases'] ?? []),
      careRequirements:
          Map<String, dynamic>.from(data['careRequirements'] ?? {}),
      isOrganic: data['isOrganic'] ?? false,
      harvestDate: data['harvestDate']?.toDate(),
      stock: data['stock'] ?? 0,
      supplier: data['supplier'] ?? '',
      farmerId: data['farmerId'] ?? '', // Added
      farmerName: data['farmerName'] ?? '', // Added
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      discount: (data['discount'] != null)
          ? (data['discount'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'subCategory': subCategory,
      'pricePerUnit': pricePerUnit,
      'unit': unit,
      'imageUrl': imageUrls.isNotEmpty ? imageUrls[0] : '',
      'imageUrls': imageUrls,
      'growthStage': growthStage,
      'daysToMaturity': daysToMaturity,
      'season': season,
      'rating': rating,
      'reviewCount': reviewCount,
      'compatibleCrops': compatibleCrops,
      'commonPests': commonPests,
      'diseases': diseases,
      'careRequirements': careRequirements,
      'isOrganic': isOrganic,
      'harvestDate':
          harvestDate != null ? Timestamp.fromDate(harvestDate!) : null,
      'stock': stock,
      'supplier': supplier,
      'farmerId': farmerId, // Added
      'farmerName': farmerName, // Added
      'createdAt': FieldValue.serverTimestamp(),
      'discount': discount,
    };
  }
}
