import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodpapu/app_colors/app_colors.dart';
import 'package:foodpapu/services/product_services.dart';
import 'package:foodpapu/services/category_services.dart';
import 'package:foodpapu/models/product_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProductsView extends StatefulWidget {
  const ProductsView({Key? key}) : super(key: key);

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  final ProductService _productService = Get.find<ProductService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _productService.fetchAdminProducts();
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
          'Products',
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
                  'Total: ${_productService.products.length}',
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
                hintText: 'Search products...',
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

          // Products List
          Expanded(
            child: Obx(() {
              if (_productService.isLoading.value &&
                  _productService.products.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (_productService.products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No Products Yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showAddProductDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Product'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Filter products
              var filteredProducts = _productService.products.where((product) {
                return product.productName.toLowerCase().contains(
                    _searchController.text.toLowerCase());
              }).toList();

              return RefreshIndicator(
                onRefresh: () async {
                  await _productService.fetchAdminProducts();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return ProductCard(
                      product: product,
                      onEdit: () => _showEditProductDialog(product),
                      onDelete: () => _showDeleteConfirmation(product),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEditProductDialog(
        productService: _productService,
        categoryService: _categoryService,
        onProductAdded: () {
          Navigator.pop(context);
          _productService.fetchAdminProducts();
        },
      ),
    );
  }

  void _showEditProductDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AddEditProductDialog(
        productService: _productService,
        categoryService: _categoryService,
        product: product,
        onProductAdded: () {
          Navigator.pop(context);
          _productService.fetchAdminProducts();
        },
      ),
    );
  }

  void _showDeleteConfirmation(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this product?'),
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
                      product.images.isNotEmpty ? product.images[0] : '',
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
                        Text(product.productName,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('Rs. ${product.price}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                onPressed: _productService.isLoading.value
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await _productService.deleteProduct(productId: product.productId);
                        _productService.fetchAdminProducts();
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: _productService.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Delete'),
              )),
        ],
      ),
    );
  }
}

// Product Card Widget
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasDiscount =
        product.discountPrice != null && product.discountPrice! < product.price;
    final discountPercentage = hasDiscount
        ? ((product.price - product.discountPrice!) / product.price * 100)
            .toStringAsFixed(0)
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    product.images.isNotEmpty ? product.images[0] : '',
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: AppColors.cardBackground,
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: product.inStock ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.inStock ? 'In Stock' : 'Out of Stock',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '-$discountPercentage%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.productName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(product.categoryName,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Rs. ${product.discountPrice ?? product.price}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                      if (hasDiscount) ...[
                        const SizedBox(width: 8),
                        Text('Rs. ${product.price}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            )),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Stock: ${product.stockQuantity}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add/Edit Product Dialog
class AddEditProductDialog extends StatefulWidget {
  final ProductService productService;
  final CategoryService categoryService;
  final ProductModel? product;
  final VoidCallback onProductAdded;

  const AddEditProductDialog({
    Key? key,
    required this.productService,
    required this.categoryService,
    this.product,
    required this.onProductAdded,
  }) : super(key: key);

  @override
  State<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _discountPriceController;
  late TextEditingController _stockController;

  List<File> selectedImages = [];
  List<String> uploadedImageUrls = [];
  String selectedUnit = 'piece';
  String? selectedCategoryId;
  String? selectedCategoryName;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.productName ?? '');
    _descriptionController =
        TextEditingController(text: widget.product?.description ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _discountPriceController =
        TextEditingController(text: widget.product?.discountPrice?.toString() ?? '');
    _stockController = TextEditingController(
        text: widget.product?.stockQuantity.toString() ?? '');

    if (widget.product != null) {
      uploadedImageUrls = List.from(widget.product!.images);
      selectedUnit = widget.product!.unit;
      selectedCategoryId = widget.product!.categoryId;
      selectedCategoryName = widget.product!.categoryName;
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
      Get.snackbar('Error', 'Please select images');
      return;
    }

    try {
      for (File image in selectedImages) {
        final url = await widget.productService.uploadImage(image.path);
        if (url != null) {
          uploadedImageUrls.add(url);
        }
      }
      setState(() {
        selectedImages.clear();
      });
      Get.snackbar('Success', 'Images uploaded');
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload images');
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (uploadedImageUrls.isEmpty) {
      Get.snackbar('Error', 'Please upload at least one image');
      return;
    }
    if (selectedCategoryId == null) {
      Get.snackbar('Error', 'Please select a category');
      return;
    }

    final double? discountPrice = _discountPriceController.text.isEmpty
        ? null
        : double.tryParse(_discountPriceController.text);

    if (widget.product == null) {
      // Add new
      await widget.productService.addProduct(
        productName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        discountPrice: discountPrice,
        imageUrls: uploadedImageUrls,
        categoryId: selectedCategoryId!,
        categoryName: selectedCategoryName!,
        stockQuantity: int.parse(_stockController.text),
        unit: selectedUnit,
      );
    } else {
      // Update
      await widget.productService.updateProduct(
        productId: widget.product!.productId,
        productName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        discountPrice: discountPrice,
        imageUrls: uploadedImageUrls,
        categoryId: selectedCategoryId!,
        categoryName: selectedCategoryName!,
        stockQuantity: int.parse(_stockController.text),
        unit: selectedUnit,
        isAvailable: widget.product!.isAvailable,
      );
    }

    widget.onProductAdded();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                widget.product == null ? 'Add Product' : 'Edit Product',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Form Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty ?? true
                          ? 'Required'
                          : (double.tryParse(v!) == null ? 'Invalid' : null),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _discountPriceController,
                      decoration: InputDecoration(
                        labelText: 'Discount Price (Optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _stockController,
                      decoration: InputDecoration(
                        labelText: 'Stock Quantity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty ?? true
                          ? 'Required'
                          : (int.tryParse(v!) == null ? 'Invalid' : null),
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      final categories =
                          widget.categoryService.getActiveCategories();
                      return DropdownButtonFormField<String>(
                        value: selectedCategoryId,
                        hint: const Text('Select Category'),
                        items: categories
                            .map((cat) => DropdownMenuItem(
                                  value: cat.categoryId,
                                  child: Text(cat.categoryName),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            final cat =
                                widget.categoryService.getCategoryById(value);
                            setState(() {
                              selectedCategoryId = value;
                              selectedCategoryName = cat?.categoryName;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (v) => v == null ? 'Select category' : null,
                      );
                    }),
                    const SizedBox(height: 12),
                    // Uploaded Images
                    if (uploadedImageUrls.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Uploaded Images:',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: uploadedImageUrls.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        uploadedImageUrls[index],
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() =>
                                              uploadedImageUrls.removeAt(index));
                                        },
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          child: const Icon(Icons.close,
                                              color: Colors.white, size: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    // Selected Images to Upload
                    if (selectedImages.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Selected Images:',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: selectedImages.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        selectedImages[index],
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() =>
                                              selectedImages.removeAt(index));
                                        },
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          child: const Icon(Icons.close,
                                              color: Colors.white, size: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    // Image Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.image, size: 18),
                            label: const Text('Pick'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                selectedImages.isEmpty ? null : _uploadImages,
                            icon: const Icon(Icons.cloud_upload, size: 18),
                            label: const Text('Upload'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  Obx(() => ElevatedButton(
                        onPressed: widget.productService.isLoading.value
                            ? null
                            : _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: widget.productService.isLoading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(widget.product == null ? 'Add' : 'Update'),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}