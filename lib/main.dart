import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'Routes/app_pages.dart';
import 'app_colors/app_colors.dart';
import 'services/auth_wrapper.dart'; // Import the wrapper

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Food Papu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      home: const AuthWrapper(), // Use AuthWrapper instead of initial route
      getPages: AppPages.routes,
    );
  }
}
