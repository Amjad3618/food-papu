import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:foodpapu/models/admin_model.dart';
import 'package:foodpapu/Routes/app_routes.dart';

class AuthService extends GetxController {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Observable variables
  Rx<AdminMdel?> currentAdmin = Rx<AdminMdel?>(null);
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxBool isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkUserStatus();
  }

  // Check if user is already logged in
  void _checkUserStatus() {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      _getAdminData(user.uid);
      isLoggedIn.value = true;
    }
  }

  // Sign Up
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Validation
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        errorMessage.value = 'All fields are required';
        isLoading.value = false;
        return false;
      }

      if (password != confirmPassword) {
        errorMessage.value = 'Passwords do not match';
        isLoading.value = false;
        return false;
      }

      if (password.length < 6) {
        errorMessage.value = 'Password must be at least 6 characters';
        isLoading.value = false;
        return false;
      }

      // Create user in Firebase Auth
      final UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String userId = userCredential.user!.uid;

      // Create Admin object
      final AdminMdel newAdmin = AdminMdel(
        id: userId,
        name: name,
        email: email,
        password: password, // In production, hash this or don't store it
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _firebaseFirestore
          .collection('admins')
          .doc(userId)
          .set(newAdmin.toJson());

      currentAdmin.value = newAdmin;
      isLoggedIn.value = true;

      Get.offAllNamed(AppRoutes.homeview);
      Get.snackbar('Success', 'Account created successfully');

      isLoading.value = false;
      return true;
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      if (e.code == 'email-already-in-use') {
        errorMessage.value = 'Email already in use';
      } else if (e.code == 'weak-password') {
        errorMessage.value = 'Password is too weak';
      } else {
        errorMessage.value = e.message ?? 'An error occurred';
      }
      Get.snackbar('Error', errorMessage.value);
      return false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'An unexpected error occurred';
      Get.snackbar('Error', errorMessage.value);
      return false;
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (email.isEmpty || password.isEmpty) {
        errorMessage.value = 'Email and password are required';
        isLoading.value = false;
        return false;
      }

      final UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String userId = userCredential.user!.uid;
      await _getAdminData(userId);

      isLoggedIn.value = true;
      Get.offAllNamed(AppRoutes.homeview);
      Get.snackbar('Success', 'Logged in successfully');

      isLoading.value = false;
      return true;
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      if (e.code == 'user-not-found') {
        errorMessage.value = 'User not found';
      } else if (e.code == 'wrong-password') {
        errorMessage.value = 'Wrong password';
      } else {
        errorMessage.value = e.message ?? 'An error occurred';
      }
      Get.snackbar('Error', errorMessage.value);
      return false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'An unexpected error occurred';
      Get.snackbar('Error', errorMessage.value);
      return false;
    }
  }

  // Get Admin Data from Firestore
  Future<void> _getAdminData(String userId) async {
    try {
      final DocumentSnapshot doc =
          await _firebaseFirestore.collection('admins').doc(userId).get();

      if (doc.exists) {
        currentAdmin.value = AdminMdel.fromJson(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error getting admin data: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      isLoading.value = true;
      await _firebaseAuth.signOut();
      currentAdmin.value = null;
      isLoggedIn.value = false;
      errorMessage.value = '';
      Get.offAllNamed(AppRoutes.loginview);
      Get.snackbar('Success', 'Logged out successfully');
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Error logging out';
      Get.snackbar('Error', errorMessage.value);
    }
  }

  // Update Admin Profile
  Future<bool> updateAdminProfile({
    required String name,
    required String email,
  }) async {
    try {
      isLoading.value = true;
      final String userId = _firebaseAuth.currentUser!.uid;

      final updatedAdmin = currentAdmin.value?.copyWith(
        name: name,
        email: email,
      );

      await _firebaseFirestore
          .collection('admins')
          .doc(userId)
          .update(updatedAdmin!.toJson());

      currentAdmin.value = updatedAdmin;
      Get.snackbar('Success', 'Profile updated successfully');

      isLoading.value = false;
      return true;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Error updating profile';
      Get.snackbar('Error', errorMessage.value);
      return false;
    }
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _firebaseAuth.currentUser?.uid;
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      final result = await _firebaseFirestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .get();
      return result.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}