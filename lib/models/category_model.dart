class CategoryModel {
  final String categoryId;
  final String categoryName;
  final String categoryImage;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final int itemCount;

  CategoryModel({
    required this.categoryId,
    required this.categoryName,
    required this.categoryImage,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.itemCount = 0,
  });

  // Convert CategoryModel to Map (for Firebase/API)
  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryImage': categoryImage,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'isActive': isActive,
      'itemCount': itemCount,
    };
  }

  // Create CategoryModel from Map (from Firebase/API)
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      categoryImage: map['categoryImage'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
      isActive: map['isActive'] ?? true,
      itemCount: map['itemCount'] ?? 0,
    );
  }

  // Convert to JSON String
  String toJson() => toMap().toString();

  // Create CategoryModel from JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel.fromMap(json);
  }

  // CopyWith method for immutable updates
  CategoryModel copyWith({
    String? categoryId,
    String? categoryName,
    String? categoryImage,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? itemCount,
  }) {
    return CategoryModel(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryImage: categoryImage ?? this.categoryImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  // toString for debugging
  @override
  String toString() {
    return 'CategoryModel(categoryId: $categoryId, categoryName: $categoryName, categoryImage: $categoryImage, createdAt: $createdAt, updatedAt: $updatedAt, isActive: $isActive, itemCount: $itemCount)';
  }

  // Equality comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CategoryModel &&
        other.categoryId == categoryId &&
        other.categoryName == categoryName &&
        other.categoryImage == categoryImage &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isActive == isActive &&
        other.itemCount == itemCount;
  }

  // HashCode
  @override
  int get hashCode {
    return categoryId.hashCode ^
        categoryName.hashCode ^
        categoryImage.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        isActive.hashCode ^
        itemCount.hashCode;
  }

  // Empty/Default Category
  static CategoryModel empty() {
    return CategoryModel(
      categoryId: '',
      categoryName: '',
      categoryImage: '',
      createdAt: DateTime.now(),
    );
  }

  // Check if category is empty
  bool get isEmpty => categoryId.isEmpty && categoryName.isEmpty;
  bool get isNotEmpty => !isEmpty;
}
