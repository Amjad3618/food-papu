import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:foodpapu/app_colors/app_colors.dart';
import 'package:foodpapu/services/category_services.dart';
import 'package:foodpapu/models/category_model.dart';

class CategoryView extends StatefulWidget {
  const CategoryView({super.key});

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  final CategoryService _categoryService = Get.find<CategoryService>();
  final ImagePicker _imagePicker = ImagePicker();
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Refresh categories when opening this page
    _categoryService.fetchAdminCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
         leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Get.back();
            },
          ),
        title: const Text(
          'Categories',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Obx(
                () => Text(
                  'Total: ${_categoryService.categories.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search categories...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                filled: true,
                fillColor: AppColors.cardBackground,
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          // Categories List
          Expanded(
            child: Obx(() {
              if (_categoryService.isLoading.value &&
                  _categoryService.categories.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading categories...'),
                    ],
                  ),
                );
              }

              if (_categoryService.categories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.category_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Categories Yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add your first category to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showAddCategoryDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Category'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Filter categories based on search
              final filteredCategories =
                  _categoryService.categories.where((category) {
                return category.categoryName
                    .toLowerCase()
                    .contains(_searchController.text.toLowerCase());
              }).toList();

              if (filteredCategories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Categories Found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No results for "${_searchController.text}"',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await _categoryService.fetchAdminCategories();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredCategories.length,
                  itemBuilder: (context, index) {
                    final category = filteredCategories[index];
                    return CategoryCard(
                      category: category,
                      onEdit: () => _showEditCategoryDialog(category),
                      onDelete: () => _showDeleteConfirmation(category),
                      onToggleStatus: () =>
                          _toggleCategoryStatus(category.categoryId),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }

  // Show Add Category Dialog
  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEditCategoryDialog(
        categoryService: _categoryService,
        imagePicker: _imagePicker,
        onCategoryAdded: () {
          Navigator.pop(context);
          _categoryService.fetchAdminCategories();
        },
      ),
    );
  }

  // Show Edit Category Dialog
  void _showEditCategoryDialog(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AddEditCategoryDialog(
        categoryService: _categoryService,
        imagePicker: _imagePicker,
        category: category,
        onCategoryAdded: () {
          Navigator.pop(context);
          _categoryService.fetchAdminCategories();
        },
      ),
    );
  }

  // Show Delete Confirmation
  void _showDeleteConfirmation(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this category?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      category.categoryImage,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.categoryName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Items: ${category.itemCount}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
                onPressed: _categoryService.isLoading.value
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await _categoryService.deleteCategory(
                          categoryId: category.categoryId,
                        );
                        _categoryService.fetchAdminCategories();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: _categoryService.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Delete'),
              )),
        ],
      ),
    );
  }

  // Toggle Category Status
  Future<void> _toggleCategoryStatus(String categoryId) async {
    await _categoryService.toggleCategoryStatus(categoryId);
    _categoryService.fetchAdminCategories();
  }
}

// Category Card Widget
class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const CategoryCard({
    Key? key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              category.categoryImage,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image_not_supported),
                );
              },
            ),
          ),
          title: Text(
            category.categoryName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 8,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: category.isActive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: category.isActive ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    category.isActive ? '● Active' : '● Inactive',
                    style: TextStyle(
                      color: category.isActive ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Items: ${category.itemCount}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          trailing: PopupMenuButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: onEdit,
                child: const Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: Colors.blue),
                    SizedBox(width: 12),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: onToggleStatus,
                child: Row(
                  children: [
                    Icon(
                      category.isActive ? Icons.pause_circle : Icons.play_circle,
                      size: 20,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Text(category.isActive ? 'Deactivate' : 'Activate'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: onDelete,
                child: const Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add/Edit Category Dialog
class AddEditCategoryDialog extends StatefulWidget {
  final CategoryService categoryService;
  final ImagePicker imagePicker;
  final CategoryModel? category;
  final VoidCallback onCategoryAdded;

  const AddEditCategoryDialog({
    Key? key,
    required this.categoryService,
    required this.imagePicker,
    this.category,
    required this.onCategoryAdded,
  }) : super(key: key);

  @override
  State<AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<AddEditCategoryDialog> {
  late TextEditingController _nameController;
  File? _selectedImage;
  String? _selectedImageUrl;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.category?.categoryName ?? '',
    );
    _selectedImageUrl = widget.category?.categoryImage;
    _isActive = widget.category?.isActive ?? true;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await widget.imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e');
    }
  }

  Future<void> _saveCategory() async {
    if (_nameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter category name');
      return;
    }

    if (_selectedImage == null && _selectedImageUrl == null) {
      Get.snackbar('Error', 'Please select an image');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = _selectedImageUrl ?? '';

      // Upload new image if selected
      if (_selectedImage != null) {
        final uploadedUrl = await widget.categoryService
            .uploadCategoryImage(_selectedImage!.path);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        } else {
          throw Exception('Failed to upload image');
        }
      }

      bool success;

      if (widget.category == null) {
        // Add new category
        success = await widget.categoryService.addCategory(
          categoryName: _nameController.text.trim(),
          categoryImageUrl: imageUrl,
        );
      } else {
        // Update existing category
        success = await widget.categoryService.updateCategory(
          categoryId: widget.category!.categoryId,
          categoryName: _nameController.text.trim(),
          categoryImageUrl: imageUrl,
          isActive: _isActive,
        );
      }

      if (success) {
        widget.onCategoryAdded();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save category: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.category != null;

    return AlertDialog(
      title: Text(
        isEdit ? 'Edit Category' : 'Add New Category',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Name Input
            const Text(
              'Category Name',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter category name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                filled: true,
                fillColor: AppColors.cardBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 16),

            // Image Section
            const Text(
              'Category Image',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.border,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.cardBackground,
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : _selectedImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _selectedImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap to change image',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                );
                              },
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to select image',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 16),

            // Active Status (only for edit)
            if (isEdit)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Category Status',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _isActive ? 'Currently Active' : 'Currently Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isActive ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() => _isActive = value);
                      },
                      activeColor: Colors.green,
                      // inactiveColor: Colors.red,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _saveCategory,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.save),
          label: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(isEdit ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}