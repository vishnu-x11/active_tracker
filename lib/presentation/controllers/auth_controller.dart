import 'package:get/get.dart';

/// Manages user authentication and session state
class AuthController extends GetxController {
  // ============ OBSERVABLE STATE ============
  final isLoggedIn = false.obs;
  final userId = ''.obs;
  final userName = ''.obs;
  final userEmail = ''.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // ============ LIFECYCLE ============
  @override
  void onInit() {
    super.onInit();
    print('✅ AuthController initialized');
    checkAuthStatus();
  }

  @override
  void onClose() {
    super.onClose();
    print('✅ AuthController closed');
  }

  // ============ BUSINESS LOGIC ============

  /// Check current auth status
  Future<void> checkAuthStatus() async {
    try {
      isLoading.value = true;

      // TODO: Check Firebase auth status
      // final user = FirebaseAuth.instance.currentUser;
      // if (user != null) {
      //   isLoggedIn.value = true;
      //   userId.value = user.uid;
      //   userEmail.value = user.email ?? '';
      // }

      print('✅ Auth status checked');
    } catch (e) {
      errorMessage.value = e.toString();
      print('❌ Error checking auth status: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Login user
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // TODO: Implement Firebase auth login
      // final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
      //   email: email,
      //   password: password,
      // );

      // isLoggedIn.value = true;
      // userId.value = result.user!.uid;
      // userEmail.value = result.user!.email ?? '';

      print('✅ User logged in');
    } catch (e) {
      errorMessage.value = 'Login failed: $e';
      print('❌ Login error: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      isLoading.value = true;

      // TODO: Implement Firebase auth logout
      // await FirebaseAuth.instance.signOut();

      isLoggedIn.value = false;
      userId.value = '';
      userName.value = '';
      userEmail.value = '';

      print('✅ User logged out');
    } catch (e) {
      errorMessage.value = 'Logout failed: $e';
      print('❌ Logout error: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Register new user
  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // TODO: Implement Firebase auth signup
      // final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      //   email: email,
      //   password: password,
      // );

      // await result.user?.updateDisplayName(name);

      // isLoggedIn.value = true;
      // userId.value = result.user!.uid;
      // userName.value = name;
      // userEmail.value = email;

      print('✅ User registered');
    } catch (e) {
      errorMessage.value = 'Registration failed: $e';
      print('❌ Registration error: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      isLoading.value = true;

      // TODO: Implement password reset
      // await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      print('✅ Password reset email sent');
    } catch (e) {
      errorMessage.value = 'Password reset failed: $e';
      print('❌ Password reset error: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get current user ID
  String getCurrentUserId() => userId.value;

  /// Get current user name
  String getCurrentUserName() => userName.value;
}