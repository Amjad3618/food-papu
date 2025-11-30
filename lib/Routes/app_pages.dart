import 'package:foodpapu/Routes/app_routes.dart';
import 'package:foodpapu/views/categories/category_view.dart';
import 'package:foodpapu/views/login/login_view.dart';
import 'package:foodpapu/views/products/products_view.dart';
import 'package:foodpapu/views/singup/signup_view.dart';
import 'package:foodpapu/views/home/home_view.dart';
import 'package:get/get.dart';

class AppPages {
  AppPages._();

  static const INITIAL = AppRoutes.loginview;

  static final routes = [
    GetPage(
      name: AppRoutes.loginview,
      page: () => const LoginView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.signupview,
      page: () => const SignupView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.homeview,
      page: () => const HomeView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
      // Bindings are already initialized globally, no need to repeat
    ),
    GetPage(
      name: AppRoutes.categoriesview,
      page: () => const CategoryView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
      // Bindings are already initialized globally, no need to repeat
    ),
     GetPage(
      name: AppRoutes.productview,
      page: () => const ProductsView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
      // Bindings are already initialized globally, no need to repeat
    ),
  ];
}