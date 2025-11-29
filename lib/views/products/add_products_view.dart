import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:foodpapu/app_colors/app_colors.dart';
import 'package:foodpapu/services/product_services.dart';
import '../../services/category_services.dart';

class AddProductsView extends StatefulWidget {
  final String? productId;
  const AddProductsView({Key? key, this.productId}) : super(key: key);

  @override
  State<AddProductsView> createState() => _AddProductsViewState();
}

class _AddProductsViewState extends State<AddProductsView> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = Get.put(ProductService());
  final CategoryService _categoryService = Get.put(CategoryService());
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _productNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _discountPriceController;
  late TextEditingController _stockQuantityController;

  List<File> selectedImages = [];
  List<String> uploadedImageUrls = [];
  String selectedUnit = 'piece';
  bool isAvailable = true;
  String? selectedCategoryId;
  String? selectedCategoryName;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _discountPriceController = TextEditingController();
    _stockQuantityController = TextEditingController();

    // Refresh categories when opening this view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _categoryService.fetchAdminCategories();
    });

    // If editing, load product data
    if (widget.productId != null) {
      _loadProductData();
    }
  }

  void _loadProductData() {
    final product = _productService.getProductById(widget.productId!);
    if (product != null) {
      _productNameController.text = product.productName;
      _descriptionController.text = product.description;
      _priceController.text = product.price.toString();
      _discountPriceController.text = product.discountPrice?.toString() ?? '';
      _stockQuantityController.text = product.stockQuantity.toString();
      selectedUnit = product.unit;
      isAvailable = product.isAvailable;
      uploadedImageUrls = List.from(product.images);
      selectedCategoryId = product.categoryId;
      selectedCategoryName = product.categoryName;
      setState(() {});
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          selectedImages.addAll(images.map((img) => File(img.path)));
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick images');
    }
  }

  Future<void> _uploadImages() async {
    if (selectedImages.isEmpty) {
      Get.snackbar('Error', 'Please select at least one image');
      return;
    }

    try {
      for (File image in selectedImages) {
        final url = await _productService.uploadImage(image.path);
        if (url != null) {
          uploadedImageUrls.add(url);
        }
      }
      setState(() {
        selectedImages.clear();
      });
      Get.snackbar('Success', 'Images uploaded successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload images: $e');
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (uploadedImageUrls.isEmpty) {
      Get.snackbar('Error', 'Please upload at least one image');
      return;
    }

    if (selectedCategoryId == null || selectedCategoryName == null) {
      Get.snackbar('Error', 'Please select a category');
      return;
    }

    final double? discountPrice = _discountPriceController.text.isEmpty
        ? null
        : double.tryParse(_discountPriceController.text);

    if (widget.productId == null) {
      // Add new product
      final success = await _productService.addProduct(
        productName: _productNameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        discountPrice: discountPrice,
        imageUrls: uploadedImageUrls,
        categoryId: selectedCategoryId!,
        categoryName: selectedCategoryName!,
        stockQuantity: int.parse(_stockQuantityController.text),
        unit: selectedUnit,
      );

      if (success) {
        Get.back();
      }
    } else {
      // Update existing product
      final success = await _productService.updateProduct(
        productId: widget.productId!,
        productName: _productNameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        discountPrice: discountPrice,
        imageUrls: uploadedImageUrls,
        categoryId: selectedCategoryId!,
        categoryName: selectedCategoryName!,
        stockQuantity: int.parse(_stockQuantityController.text),
        unit: selectedUnit,
        isAvailable: isAvailable,
      );

      if (success) {
        Get.back();
      }
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _stockQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          widget.productId == null ? 'Add Product' : 'Edit Product',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  'Product Name',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _productNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter product name',
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Product name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  'Description',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter product description',
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                Text(
                  'Category',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  final categories = _categoryService.getActiveCategories();
                  print('Categories available: ${categories.length}');
                  for (var cat in categories) {
                    print(
                      'Category: ${cat.categoryName} (ID: ${cat.categoryId})',
                    );
                  }

                  if (_categoryService.isLoading.value) {
                    return Container(
                      height: 56,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    hint: const Text('Select a category'),
                    isExpanded: true,
                    items: categories.isEmpty
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('No categories available'),
                            ),
                          ]
                        : categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category.categoryId,
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      category.categoryImage,
                                      width: 30,
                                      height: 30,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: 30,
                                              height: 30,
                                              color: AppColors.cardBackground,
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                size: 16,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      category.categoryName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final category = _categoryService.getCategoryById(
                          value,
                        );
                        setState(() {
                          selectedCategoryId = value;
                          selectedCategoryName = category?.categoryName;
                        });
                        print(
                          'Selected category: $selectedCategoryName (ID: $selectedCategoryId)',
                        );
                      }
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  );
                }),
                const SizedBox(height: 16),

                // Price and Discount Price
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              filled: true,
                              fillColor: AppColors.cardBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Price is required';
                              }
                              if (double.tryParse(value!) == null) {
                                return 'Enter a valid price';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Discount Price',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _discountPriceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Optional',
                              filled: true,
                              fillColor: AppColors.cardBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stock and Unit
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stock Quantity',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _stockQuantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '0',
                              filled: true,
                              fillColor: AppColors.cardBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Stock quantity is required';
                              }
                              if (int.tryParse(value!) == null) {
                                return 'Enter a valid quantity';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unit',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedUnit,
                            items: ['piece', 'kg', 'liter', 'meter']
                                .map(
                                  (unit) => DropdownMenuItem(
                                    value: unit,
                                    child: Text(unit),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedUnit = value ?? 'piece';
                              });
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.cardBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Images Section
                Text(
                  'Product Images',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                // Uploaded Images
                if (uploadedImageUrls.isNotEmpty)
                  Container(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: uploadedImageUrls.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  uploadedImageUrls[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      uploadedImageUrls.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),

                // Selected Images to Upload
                if (selectedImages.isNotEmpty)
                  Container(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  selectedImages[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),

                // Upload Progress
                Obx(
                  () => _productService.uploadProgress.value > 0
                      ? Column(
                          children: [
                            LinearProgressIndicator(
                              value: _productService.uploadProgress.value,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(_productService.uploadProgress.value * 100).toStringAsFixed(0)}%',
                            ),
                            const SizedBox(height: 16),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),

                // Image Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.image),
                        label: const Text('Pick Images'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: selectedImages.isEmpty
                            ? null
                            : _uploadImages,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Upload'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Availability Toggle (only for edit)
                if (widget.productId != null)
                  Row(
                    children: [
                      Text(
                        'Available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: isAvailable,
                        onChanged: (value) {
                          setState(() {
                            isAvailable = value;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                const SizedBox(height: 24),

                // Save Button
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _productService.isLoading.value
                          ? null
                          : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _productService.isLoading.value
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              widget.productId == null
                                  ? 'Add Product'
                                  : 'Update Product',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
