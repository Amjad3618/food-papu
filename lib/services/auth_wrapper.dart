import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodpapu/services/auth_services.dart';
import 'package:foodpapu/views/login/login_view.dart';
import 'package:foodpapu/views/home/home_view.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Get.put(AuthService());

    return Obx(() {
      // If user is logged in, show home
      if (authService.isLoggedIn.value && authService.currentAdmin.value != null) {
        return const HomeView();
      }
      
      // If not logged in, show login screen
      return const LoginView();
    });
  }
}