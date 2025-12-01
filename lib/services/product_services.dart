import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodpapu/models/product_model.dart';

class ProductService extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  RxList<ProductModel> products = <ProductModel>[].obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxDouble uploadProgress = 0.0.obs;
  RxBool _hasInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (!_hasInitialized.value) {
      fetchAdminProducts();
      _hasInitialized.value = true;
    }
  }

  // Get current admin ID
  String get currentAdminId => _auth.currentUser?.uid ?? '';

  // Fetch all products for current admin
  Future<void> fetchAdminProducts() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';


      final QuerySnapshot snapshot = await _firestore
          .collection('products')
          .where('adminId', isEqualTo: currentAdminId)
          .orderBy('createdAt', descending: true)
          .get();


      products.value = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ProductModel.fromMap(data);
          })
          .toList();

    } catch (e) {
      errorMessage.value = 'Error fetching products: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Add new product
  Future<bool> addProduct({
    required String productName,
    required String description,
    required double price,
    double? discountPrice,
    required List<String> imageUrls,
    required String categoryId,
    required String categoryName,
    required int stockQuantity,
    required String unit,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Validation
      if (productName.isEmpty || description.isEmpty) {
        errorMessage.value = 'Product name and description are required';
        isLoading.value = false;
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      if (price <= 0) {
        errorMessage.value = 'Price must be greater than 0';
        isLoading.value = false;
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      if (imageUrls.isEmpty) {
        errorMessage.value = 'At least one image is required';
        isLoading.value = false;
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      final String productId = _firestore.collection('products').doc().id;

      final ProductModel newProduct = ProductModel(
        adminId: currentAdminId,
        productId: productId,
        productName: productName,
        description: description,
        price: price,
        discountPrice: discountPrice,
        images: imageUrls,
        categoryId: categoryId,
        categoryName: categoryName,
        stockQuantity: stockQuantity,
        unit: unit,
        isAvailable: true,
        createdAt: DateTime.now(),
      );

      // Ensure adminId is included in the map
      final productData = newProduct.toMap();
      productData['adminId'] = currentAdminId;


      await _firestore
          .collection('products')
          .doc(productId)
          .set(productData);

      // Add to local list immediately
      products.add(newProduct);
      
      Get.snackbar('Success', 'Product added successfully');

      isLoading.value = false;
      return true;
    } catch (e) {
      errorMessage.value = 'Error adding product: $e';
      Get.snackbar('Error', errorMessage.value);
      isLoading.value = false;
      return false;
    }
  }

  // Update product
  Future<bool> updateProduct({
    required String productId,
    required String productName,
    required String description,
    required double price,
    double? discountPrice,
    required List<String> imageUrls,
    required String categoryId,
    required String categoryName,
    required int stockQuantity,
    required String unit,
    required bool isAvailable,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Validation
      if (productName.isEmpty || description.isEmpty) {
        errorMessage.value = 'Product name and description are required';
        isLoading.value = false;
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      if (price <= 0) {
        errorMessage.value = 'Price must be greater than 0';
        isLoading.value = false;
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      // Find product index
      int productIndex = products.indexWhere((p) => p.productId == productId);

      if (productIndex == -1) {
        errorMessage.value = 'Product not found';
        isLoading.value = false;
        return false;
      }

      final updatedProduct = products[productIndex].copyWith(
        productName: productName,
        description: description,
        price: price,
        discountPrice: discountPrice,
        images: imageUrls,
        categoryId: categoryId,
        categoryName: categoryName,
        stockQuantity: stockQuantity,
        unit: unit,
        isAvailable: isAvailable,
        updatedAt: DateTime.now(),
      );

      final updateData = updatedProduct.toMap();
      updateData['adminId'] = currentAdminId;


      await _firestore
          .collection('products')
          .doc(productId)
          .update(updateData);

      // Update local list immediately
      products[productIndex] = updatedProduct;
      
      Get.snackbar('Success', 'Product updated successfully');

      isLoading.value = false;
      return true;
    } catch (e) {
      errorMessage.value = 'Error updating product: $e';
      Get.snackbar('Error', errorMessage.value);
      isLoading.value = false;
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct({required String productId}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Find product to get image URLs
      final ProductModel? product =
          products.firstWhereOrNull((p) => p.productId == productId);

      if (product == null) {
        errorMessage.value = 'Product not found';
        isLoading.value = false;
        return false;
      }

      // Delete images from Firebase Storage
      for (String imageUrl in product.images) {
        try {
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
        }
      }


      // Delete product from Firestore
      await _firestore.collection('products').doc(productId).delete();

      // Remove from local list immediately
      products.removeWhere((p) => p.productId == productId);

      Get.snackbar('Success', 'Product deleted successfully');

      isLoading.value = false;
      return true;
    } catch (e) {
      errorMessage.value = 'Error deleting product: $e';
      Get.snackbar('Error', errorMessage.value);
      isLoading.value = false;
      return false;
    }
  }

  // Upload image to Firebase Storage
  Future<String?> uploadImage(String imagePath) async {
    try {
      uploadProgress.value = 0.0;

      final File file = File(imagePath);
      final String fileName =
          'products/${currentAdminId}/${DateTime.now().millisecondsSinceEpoch}';


      final UploadTask uploadTask = _storage.ref(fileName).putFile(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        uploadProgress.value =
            (snapshot.bytesTransferred / snapshot.totalBytes);
      });

      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      uploadProgress.value = 0.0;
      return downloadUrl;
    } catch (e) {
      errorMessage.value = 'Error uploading image: $e';
      uploadProgress.value = 0.0;
      return null;
    }
  }

  // Get product by ID
  ProductModel? getProductById(String productId) {
    try {
      return products.firstWhereOrNull((p) => p.productId == productId);
    } catch (e) {
      return null;
    }
  }

  // Get products by category
  List<ProductModel> getProductsByCategory(String categoryId) {
    return products.where((p) => p.categoryId == categoryId).toList();
  }

  // Search products
  List<ProductModel> searchProducts(String query) {
    if (query.isEmpty) return products;
    return products
        .where((p) =>
            p.productName.toLowerCase().contains(query.toLowerCase()) ||
            p.description.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Get available products only
  List<ProductModel> getAvailableProducts() {
    return products.where((p) => p.isAvailable && p.inStock).toList();
  }

  // Get total products count
  int get totalProductsCount => products.length;

  // Get low stock products (stock < 10)
  List<ProductModel> getLowStockProducts() {
    return products.where((p) => p.stockQuantity < 10).toList();
  }
}