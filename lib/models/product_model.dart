import 'package:flutter/foundation.dart';

class ProductModel {
  final String productId;
  final String productName;
  final String description;
  final double price;
  final double? discountPrice;
  final List<String> images; // Multiple images
  final String categoryId;
  final String categoryName;
  final bool isAvailable;
  final int stockQuantity;
  final String unit; // e.g., "kg", "piece", "liter"
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.productId,
    required this.productName,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.images,
    required this.categoryId,
    required this.categoryName,
    this.isAvailable = true,
    this.stockQuantity = 0,
    this.unit = 'piece',
    required this.createdAt,
    this.updatedAt,
  });

  // Calculate discount percentage
  double get discountPercentage {
    if (discountPrice == null || discountPrice! >= price) return 0.0;
    return ((price - discountPrice!) / price * 100);
  }

  // Get final price (with discount if available)
  double get finalPrice => discountPrice ?? price;

  // Check if product has discount
  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  // Check if product is in stock
  bool get inStock => stockQuantity > 0;

  // Get primary image
  String get primaryImage => images.isNotEmpty ? images.first : '';

  // Convert ProductModel to Map (for Firebase/API)
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'images': images,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'isAvailable': isAvailable,
      'stockQuantity': stockQuantity,
      'unit': unit,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  // Create ProductModel from Map (from Firebase/API)
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      discountPrice: map['discountPrice'] != null 
          ? (map['discountPrice']).toDouble() 
          : null,
      images: List<String>.from(map['images'] ?? []),
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      stockQuantity: map['stockQuantity'] ?? 0,
      unit: map['unit'] ?? 'piece',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
    );
  }

  // Convert to JSON String
  String toJson() => toMap().toString();

  // Create ProductModel from JSON
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel.fromMap(json);
  }

  // CopyWith method for immutable updates
  ProductModel copyWith({
    String? productId,
    String? productName,
    String? description,
    double? price,
    double? discountPrice,
    List<String>? images,
    String? categoryId,
    String? categoryName,
    bool? isAvailable,
    int? stockQuantity,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      images: images ?? this.images,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      isAvailable: isAvailable ?? this.isAvailable,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // toString for debugging
  @override
  String toString() {
    return 'ProductModel(productId: $productId, productName: $productName, price: $price, images: ${images.length}, categoryName: $categoryName, isAvailable: $isAvailable, stockQuantity: $stockQuantity)';
  }

  // Equality comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProductModel &&
        other.productId == productId &&
        other.productName == productName &&
        other.price == price &&
        listEquals(other.images, images) &&
        other.categoryId == categoryId;
  }

  // HashCode
  @override
  int get hashCode {
    return productId.hashCode ^
        productName.hashCode ^
        price.hashCode ^
        images.hashCode ^
        categoryId.hashCode;
  }

  // Empty/Default Product
  static ProductModel empty() {
    return ProductModel(
      productId: '',
      productName: '',
      description: '',
      price: 0.0,
      images: [],
      categoryId: '',
      categoryName: '',
      createdAt: DateTime.now(),
    );
  }

  // Check if product is empty
  bool get isEmpty => productId.isEmpty && productName.isEmpty;
  bool get isNotEmpty => !isEmpty;
}