import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodpapu/models/category_model.dart';

class CategoryService extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  RxList<CategoryModel> categories = <CategoryModel>[].obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxDouble uploadProgress = 0.0.obs;
  RxBool _hasInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (!_hasInitialized.value) {
      fetchAdminCategories();
      _hasInitialized.value = true;
      print('✅ CategoryService.onInit() - Categories fetched');
    }
  }

  // Get current admin ID
  String get currentAdminId => _auth.currentUser?.uid ?? '';

  // Fetch all categories for current admin
  Future<void> fetchAdminCategories() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('🔍 Fetching categories for admin: $currentAdminId');

      final QuerySnapshot snapshot = await _firestore
          .collection('categories')
          .where('adminId', isEqualTo: currentAdminId)
          .orderBy('createdAt', descending: true)
          .get();

      print('📦 Categories found: ${snapshot.docs.length}');

      categories.value = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            print('   ✓ Category: ${data['categoryName']}');
            return CategoryModel.fromMap(data);
          })
          .toList();

      print('✅ Fetched ${categories.length} categories');
    } catch (e) {
      errorMessage.value = 'Error fetching categories: $e';
      print('❌ Error fetching categories: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Add new category
  Future<bool> addCategory({
    required String categoryName,
    required String categoryImageUrl,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Validation
      if (categoryName.isEmpty) {
        errorMessage.value = 'Category name is required';
        isLoading.value = false;
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      if (categoryImageUrl.isEmpty) {
        errorMessage.value = 'Category image is required';
        isLoading.value = false;
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      final String categoryId = _firestore.collection('categories').doc().id;

      final CategoryModel newCategory = CategoryModel(
        adminId: currentAdminId,
        categoryId: categoryId,
        categoryName: categoryName,
        categoryImage: categoryImageUrl,
        createdAt: DateTime.now(),
        isActive: true,
        itemCount: 0,
      );

      // Create map with adminId explicitly set
      final Map<String, dynamic> categoryData = {
        'adminId': currentAdminId,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'categoryImage': categoryImageUrl,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': null,
        'isActive': true,
        'itemCount': 0,
      };

      print('💾 Saving category: $categoryName');

      await _firestore
          .collection('categories')
          .doc(categoryId)
          .set(categoryData);

      // Add to local list immediately
      categories.add(newCategory);
      
      print('✅ Category added: $categoryName');
      Get.snackbar('Success', 'Category added successfully');

      isLoading.value = false;
      return true;
    } catch (e) {
      errorMessage.value = 'Error adding category: $e';
      Get.snackbar('Error', errorMessage.value);
      isLoading.value = false;
      print('❌ Error adding category: $e');
      return false;
    }
  }

  // Update category
  Future<bool> updateCategory({
    required String categoryId,
    required String categoryName,
    String? categoryImageUrl,
    required bool isActive,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Validation
      if (categoryName.isEmpty) {
        errorMessage.value = 'Category name is required';
        isLoading.value = false;
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      // Find category index
      int categoryIndex =
          categories.indexWhere((c) => c.categoryId == categoryId);

      if (categoryIndex == -1) {
        errorMessage.value = 'Category not found';
        isLoading.value = false;
        return false;
      }

      final updatedCategory = categories[categoryIndex].copyWith(
        categoryName: categoryName,
        categoryImage: categoryImageUrl ?? categories[categoryIndex].categoryImage,
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      final updateData = updatedCategory.toMap();
      updateData['adminId'] = currentAdminId;

      print('📝 Updating category: $categoryName');

      await _firestore
          .collection('categories')
          .doc(categoryId)
          .update(updateData);

      // Update local list immediately
      categories[categoryIndex] = updatedCategory;
      
      print('✅ Category updated: $categoryName');
      Get.snackbar('Success', 'Category updated successfully');

      isLoading.value = false;
      return true;
    } catch (e) {
      errorMessage.value = 'Error updating category: $e';
      Get.snackbar('Error', errorMessage.value);
      isLoading.value = false;
      print('❌ Error updating category: $e');
      return false;
    }
  }

  // Delete category
  Future<bool> deleteCategory({required String categoryId}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Find category to get image URL
      final CategoryModel? category =
          categories.firstWhereOrNull((c) => c.categoryId == categoryId);

      if (category == null) {
        errorMessage.value = 'Category not found';
        isLoading.value = false;
        return false;
      }

      // Delete image from Firebase Storage
      try {
        final ref = _storage.refFromURL(category.categoryImage);
        await ref.delete();
      } catch (e) {
        print('⚠️ Error deleting image: $e');
      }

      print('🗑️ Deleting category: ${category.categoryName}');

      // Delete category from Firestore
      await _firestore.collection('categories').doc(categoryId).delete();

      // Remove from local list immediately
      categories.removeWhere((c) => c.categoryId == categoryId);

      print('✅ Category deleted: ${category.categoryName}');
      Get.snackbar('Success', 'Category deleted successfully');

      isLoading.value = false;
      return true;
    } catch (e) {
      errorMessage.value = 'Error deleting category: $e';
      Get.snackbar('Error', errorMessage.value);
      isLoading.value = false;
      print('❌ Error deleting category: $e');
      return false;
    }
  }

  // Upload category image to Firebase Storage
  Future<String?> uploadCategoryImage(String imagePath) async {
    try {
      uploadProgress.value = 0.0;

      final File file = File(imagePath);
      final String fileName =
          'categories/${currentAdminId}/${DateTime.now().millisecondsSinceEpoch}';

      print('📤 Uploading image to: $fileName');

      final UploadTask uploadTask = _storage.ref(fileName).putFile(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        uploadProgress.value =
            (snapshot.bytesTransferred / snapshot.totalBytes);
      });

      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      uploadProgress.value = 0.0;
      print('✅ Image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      errorMessage.value = 'Error uploading image: $e';
      uploadProgress.value = 0.0;
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  // Get category by ID
  CategoryModel? getCategoryById(String categoryId) {
    try {
      return categories.firstWhereOrNull((c) => c.categoryId == categoryId);
    } catch (e) {
      return null;
    }
  }

  // Get active categories only
  List<CategoryModel> getActiveCategories() {
    return categories.where((c) => c.isActive).toList();
  }

  // Search categories
  List<CategoryModel> searchCategories(String query) {
    if (query.isEmpty) return categories;
    return categories
        .where((c) =>
            c.categoryName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Get total categories count
  int get totalCategoriesCount => categories.length;

  // Update category item count
  Future<void> updateCategoryItemCount(String categoryId, int count) async {
    try {
      final categoryIndex =
          categories.indexWhere((c) => c.categoryId == categoryId);
      if (categoryIndex != -1) {
        final updated = categories[categoryIndex].copyWith(itemCount: count);
        await _firestore
            .collection('categories')
            .doc(categoryId)
            .update({'itemCount': count});
        categories[categoryIndex] = updated;
      }
    } catch (e) {
      print('❌ Error updating item count: $e');
    }
  }

  // Toggle category active status
  Future<bool> toggleCategoryStatus(String categoryId) async {
    try {
      final category = getCategoryById(categoryId);
      if (category != null) {
        return await updateCategory(
          categoryId: categoryId,
          categoryName: category.categoryName,
          categoryImageUrl: category.categoryImage,
          isActive: !category.isActive,
        );
      }
      return false;
    } catch (e) {
      print('❌ Error toggling category: $e');
      return false;
    }
  }
}