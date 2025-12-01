import 'package:get/get.dart';
import 'package:foodpapu/services/category_services.dart';
import 'package:foodpapu/services/product_services.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Check if services already exist, if not create them
    if (!Get.isRegistered<CategoryService>()) {
      Get.put(CategoryService(), permanent: true);
    } else {}

    if (!Get.isRegistered<ProductService>()) {
      Get.put(ProductService(), permanent: true);
    } else {}
  }
}
