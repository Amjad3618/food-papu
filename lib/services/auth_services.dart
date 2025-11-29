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
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        _getAdminData(user.uid);
        isLoggedIn.value = true;
      }
    } catch (e) {
      print('Error checking user status: $e');
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
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      if (password != confirmPassword) {
        errorMessage.value = 'Passwords do not match';
        isLoading.value = false;
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      if (password.length < 6) {
        errorMessage.value = 'Password must be at least 6 characters';
        isLoading.value = false;
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      // Validate email format
      if (!email.contains('@') || !email.contains('.')) {
        errorMessage.value = 'Please enter a valid email';
        isLoading.value = false;
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      print('Starting signup process for: $email');

      // Create user in Firebase Auth
      final UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final String userId = userCredential.user!.uid;
      print('User created with ID: $userId');

      // Create Admin object
      final AdminMdel newAdmin = AdminMdel(
        id: userId,
        name: name,
        email: email,
        password: password,
        createdAt: DateTime.now(),
      );

      print('Saving admin data to Firestore...');

      // Save to Firestore
      await _firebaseFirestore
          .collection('admins')
          .doc(userId)
          .set(newAdmin.toJson());

      print('Admin data saved successfully');

      currentAdmin.value = newAdmin;
      isLoggedIn.value = true;

      Get.snackbar('Success', 'Account created successfully');
      Get.offAllNamed(AppRoutes.homeview);

      isLoading.value = false;
      return true;
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      
      if (e.code == 'email-already-in-use') {
        errorMessage.value = 'Email already in use';
      } else if (e.code == 'weak-password') {
        errorMessage.value = 'Password is too weak';
      } else if (e.code == 'invalid-email') {
        errorMessage.value = 'Invalid email address';
      } else {
        errorMessage.value = e.message ?? 'Authentication error';
      }
      Get.snackbar('Auth Error', errorMessage.value);
      return false;
    } on FirebaseException catch (e) {
      isLoading.value = false;
      print('Firebase Error: ${e.code} - ${e.message}');
      errorMessage.value = e.message ?? 'Firebase error occurred';
      Get.snackbar('Firebase Error', errorMessage.value);
      return false;
    } catch (e) {
      isLoading.value = false;
      print('Unexpected Error: $e');
      errorMessage.value = 'An unexpected error occurred: $e';
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
        Get.snackbar('Error', errorMessage.value);
        return false;
      }

      print('Attempting login for: $email');

      final UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final String userId = userCredential.user!.uid;
      print('User logged in with ID: $userId');

      await _getAdminData(userId);

      isLoggedIn.value = true;
      Get.snackbar('Success', 'Logged in successfully');
      Get.offAllNamed(AppRoutes.homeview);

      isLoading.value = false;
      return true;
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      
      if (e.code == 'user-not-found') {
        errorMessage.value = 'User not found';
      } else if (e.code == 'wrong-password') {
        errorMessage.value = 'Wrong password';
      } else if (e.code == 'invalid-email') {
        errorMessage.value = 'Invalid email address';
      } else {
        errorMessage.value = e.message ?? 'Authentication error';
      }
      Get.snackbar('Login Error', errorMessage.value);
      return false;
    } catch (e) {
      isLoading.value = false;
      print('Unexpected Error: $e');
      errorMessage.value = 'An unexpected error occurred: $e';
      Get.snackbar('Error', errorMessage.value);
      return false;
    }
  }

  // Get Admin Data from Firestore
  Future<void> _getAdminData(String userId) async {
    try {
      print('Fetching admin data for user: $userId');
      
      final DocumentSnapshot doc =
          await _firebaseFirestore.collection('admins').doc(userId).get();

      if (doc.exists) {
        currentAdmin.value = AdminMdel.fromJson(doc.data() as Map<String, dynamic>);
        print('Admin data loaded successfully');
      } else {
        print('Admin document does not exist');
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
      Get.snackbar('Success', 'Logged out successfully');
      Get.offAllNamed(AppRoutes.loginview);
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Error logging out';
      Get.snackbar('Error', errorMessage.value);
      print('Logout error: $e');
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
      errorMessage.value = 'Error updating profile: $e';
      Get.snackbar('Error', errorMessage.value);
      print('Update profile error: $e');
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
      print('Error checking email: $e');
      return false;
    }
  }
}