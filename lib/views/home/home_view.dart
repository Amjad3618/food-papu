
import 'package:flutter/material.dart';
import 'package:foodpapu/app_colors/app_colors.dart';
import 'package:get/get.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Food Papu Admin Panel",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome Admin! 👋",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Manage your restaurant efficiently",
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Admin Cards
              _buildAdminCard(
                icon: Icons.shopping_bag_outlined,
                title: "Check Orders",
                subtitle: "View and manage orders",
                color: AppColors.orange,
                onTap: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Orders management coming soon',
                    duration: const Duration(seconds: 2),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildAdminCard(
                icon: Icons.add_circle_outline,
                title: "Add Products",
                subtitle: "Create new menu items",
                color: AppColors.green,
                onTap: () {
                  Get.toNamed('/productsview');
                },
              ),
              const SizedBox(height: 20),
              _buildAdminCard(
                icon: Icons.category_outlined,
                title: "Manage Categories",
                subtitle: "Organize your menu",
                color: AppColors.primary,
                onTap: () {
                  Get.toNamed('/categoriesview');
                },
              ),
              const SizedBox(height: 20),
              _buildAdminCard(
                icon: Icons.list_alt_outlined,
                title: "View Products",
                subtitle: "See all menu items",
                color: Colors.purple,
                onTap: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Products list coming soon',
                    duration: const Duration(seconds: 2),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildAdminCard(
                icon: Icons.analytics_outlined,
                title: "Analytics",
                subtitle: "View sales & reports",
                color: Colors.teal,
                onTap: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Analytics coming soon',
                    duration: const Duration(seconds: 2),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey300.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: AppColors.grey400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}