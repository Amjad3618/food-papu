import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'Routes/app_pages.dart';
import 'app_colors/app_colors.dart';
import 'services/app_bindings/bindings.dart';
import 'services/auth_wrapper.dart';

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
      initialBinding: AppBindings(), // ADD THIS LINE - Initialize all services at startup
      home: const AuthWrapper(),
      getPages: AppPages.routes,
    );
  }
}