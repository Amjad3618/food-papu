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
  late ProductService _productService;
  late CategoryService _categoryService;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _productService = Get.find<ProductService>();
    _categoryService = Get.find<CategoryService>();
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
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildProductsList()),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Get.back(),
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
        padding: const EdgeInsets.all(16),
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
  );

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.all(16),
    child: TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search products...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.cardBackground,
      ),
      onChanged: (_) => setState(() {}),
    ),
  );

  Widget _buildProductsList() => Obx(() {
    if (_productService.isLoading.value && _productService.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_productService.products.isEmpty) {
      return _buildEmptyState();
    }

    final filtered = _productService.products
        .where(
          (p) => p.productName.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ),
        )
        .toList();

    return RefreshIndicator(
      onRefresh: () async => await _productService.fetchAdminProducts(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filtered.length,
        itemBuilder: (_, i) => ProductCard(
          product: filtered[i],
          onEdit: () => _showProductDialog(filtered[i]),
          onDelete: () => _showDeleteDialog(filtered[i]),
        ),
      ),
    );
  });

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          'No Products Yet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _showProductDialog(null),
          icon: const Icon(Icons.add),
          label: const Text('Add Product'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
        ),
      ],
    ),
  );

  FloatingActionButton _buildFAB() => FloatingActionButton.extended(
    onPressed: () => _showProductDialog(null),
    backgroundColor: AppColors.primary,
    icon: const Icon(Icons.add),
    label: const Text('Add '),
  );

  void _showProductDialog(ProductModel? product) {
    showDialog(
      context: context,
      builder: (_) => AddEditProductDialog(
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

  void _showDeleteDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to delete this product?'),
            const SizedBox(height: 16),
            _buildProductPreview(product),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: _productService.isLoading.value
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await _productService.deleteProduct(
                        productId: product.productId,
                      );
                      _productService.fetchAdminProducts();
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: _productService.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductPreview(ProductModel product) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        _buildProductImage(
          product.images.isNotEmpty ? product.images[0] : '',
          50,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.productName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Rs. ${product.price}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildProductImage(
    String url,
    double size, {
    BoxFit fit = BoxFit.cover,
  }) => ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: Image.network(
      url,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported),
      ),
    ),
  );
}

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit, onDelete;

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
    final discount = hasDiscount
        ? ((product.price - product.discountPrice!) / product.price * 100)
              .toStringAsFixed(0)
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _buildImageTile(hasDiscount, discount),
            Expanded(child: _buildDetailsSection(hasDiscount)),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile(bool hasDiscount, String? discount) => Stack(
    children: [
      ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomLeft: Radius.circular(10),
        ),
        child: Image.network(
          product.images.isNotEmpty ? product.images[0] : '',
          height: 100,
          width: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 100,
            width: 100,
            color: AppColors.cardBackground,
            child: const Icon(Icons.image_not_supported, size: 30),
          ),
        ),
      ),
      Positioned(
        top: 4,
        left: 4,
        child: _buildBadge(
          product.inStock ? 'In' : 'Out',
          product.inStock ? Colors.green : Colors.red,
          fontSize: 9,
        ),
      ),
      if (hasDiscount)
        Positioned(
          top: 4,
          right: 4,
          child: _buildBadge('-$discount%', Colors.red, fontSize: 9),
        ),
    ],
  );

  Widget _buildBadge(String text, Color color, {double fontSize = 11}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _buildDetailsSection(bool hasDiscount) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          product.productName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          product.categoryName,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'Rs. ${product.discountPrice ?? product.price}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            if (hasDiscount)
              Text(
                ' Rs. ${product.price}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Stock: ${product.stockQuantity}',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _buildActionButtons() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIconButton(Icons.edit, Colors.blue, onEdit),
        const SizedBox(height: 4),
        _buildIconButton(Icons.delete, Colors.red, onDelete),
      ],
    ),
  );

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onPressed) =>
      InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      );
}

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
  final _imagePicker = ImagePicker();

  late TextEditingController _nameController,
      _descriptionController,
      _priceController,
      _discountPriceController,
      _stockController;

  List<File> selectedImages = [];
  List<String> uploadedImageUrls = [];
  String selectedUnit = 'piece';
  String? selectedCategoryId, selectedCategoryName;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.product?.productName ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    _discountPriceController = TextEditingController(
      text: widget.product?.discountPrice?.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: widget.product?.stockQuantity.toString() ?? '',
    );

    if (widget.product != null) {
      uploadedImageUrls = List.from(widget.product!.images);
      selectedUnit = widget.product!.unit;
      selectedCategoryId = widget.product!.categoryId;
      selectedCategoryName = widget.product!.categoryName;
    }
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

  Future<void> _pickImages() async {
    try {
      final images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() => selectedImages.addAll(images.map((e) => File(e.path))));
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
      for (var image in selectedImages) {
        final url = await widget.productService.uploadImage(image.path);
        if (url != null) uploadedImageUrls.add(url);
      }
      setState(() => selectedImages.clear());
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

    final discountPrice = _discountPriceController.text.isEmpty
        ? null
        : double.tryParse(_discountPriceController.text);

    if (widget.product == null) {
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
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      'Product Name',
                      _nameController,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      'Description',
                      _descriptionController,
                      maxLines: 3,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      'Price',
                      _priceController,
                      isNumber: true,
                      validator: (v) => v?.isEmpty ?? true
                          ? 'Required'
                          : (double.tryParse(v!) == null ? 'Invalid' : null),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      'Discount Price (Optional)',
                      _discountPriceController,
                      isNumber: true,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      'Stock Quantity',
                      _stockController,
                      isNumber: true,
                      validator: (v) => v?.isEmpty ?? true
                          ? 'Required'
                          : (int.tryParse(v!) == null ? 'Invalid' : null),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 12),
                    if (uploadedImageUrls.isNotEmpty)
                      _buildImageList(
                        'Uploaded Images',
                        uploadedImageUrls,
                        true,
                      ),
                    if (selectedImages.isNotEmpty)
                      _buildImageList(
                        'Selected Images',
                        selectedImages.map((e) => e.path).toList(),
                        false,
                      ),
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
                            onPressed: selectedImages.isEmpty
                                ? null
                                : _uploadImages,
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
                  Obx(
                    () => ElevatedButton(
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
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(widget.product == null ? 'Add' : 'Update'),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    maxLines: maxLines,
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    validator: validator,
  );

  Widget _buildCategoryDropdown() => Obx(() {
    final categories = widget.categoryService.getActiveCategories();
    return DropdownButtonFormField<String>(
      value: selectedCategoryId,
      hint: const Text('Select Category'),
      items: categories
          .map(
            (cat) => DropdownMenuItem(
              value: cat.categoryId,
              child: Text(cat.categoryName),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          final cat = widget.categoryService.getCategoryById(value);
          setState(() {
            selectedCategoryId = value;
            selectedCategoryName = cat?.categoryName;
          });
        }
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (v) => v == null ? 'Select category' : null,
    );
  });

  Widget _buildImageList(String title, List<dynamic> images, bool isNetwork) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: isNetwork
                          ? Image.network(
                              images[i] as String,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              images[i] as File,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => setState(
                          () => isNetwork
                              ? uploadedImageUrls.removeAt(i)
                              : selectedImages.removeAt(i),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 12,
                          ),
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
      );
}
