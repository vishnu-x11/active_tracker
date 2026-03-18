import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:active_tracker/domain/repositories/repositories.dart';
import 'package:hive/hive.dart';
import 'package:active_tracker/config/constants.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// Manages user authentication and session state
class AuthController extends GetxController {
  // ============ OBSERVABLE STATE ============
  final isLoggedIn = false.obs;
  final userId = ''.obs;
  final userName = ''.obs;
  final userEmail = ''.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final successMessage = ''.obs;
  final profileImageUrl = Rx<String?>(null);

  // ============ GOOGLE SIGN IN CONFIG ============
  late final GoogleSignIn _googleSignIn;

  // ============ LIFECYCLE ============
  @override
  void onInit() {
    super.onInit();
    print('✅ AuthController initialized');
    _googleSignIn = GoogleSignIn(
      serverClientId: '773988908810-g9edgsr32bj76ncpc545e0r29p54mfu5.apps.googleusercontent.com',
    );
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

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        isLoggedIn.value = true;
        userId.value = user.uid;
        userEmail.value = user.email ?? '';
        userName.value = user.displayName ?? '';
        
        // Load profile image from Hive
        final onboardingRepo = Get.find<OnboardingRepository>();
        final profile = onboardingRepo.getUserProfileSync();
        if (profile != null) {
          profileImageUrl.value = profile.imageUrl;
        }
        
        print('✅ User is logged in: ${user.email}');
      } else {
        isLoggedIn.value = false;
        userId.value = '';
        userEmail.value = '';
        userName.value = '';
        profileImageUrl.value = null;
        print('ℹ️ No user logged in');
      }

      print('✅ Auth status checked');
    } catch (e) {
      errorMessage.value = e.toString();
      print('❌ Error checking auth status: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Login user
  Future<void> login({required String email, required String password}) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        errorMessage.value = 'Please fill in all details';
        return;
      }

      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user != null) {
        isLoggedIn.value = true;
        userId.value = user.uid;
        userEmail.value = user.email ?? '';
        userName.value = user.displayName ?? '';
        print('✅ User logged in: ${user.email}');
        
        // Smart navigation based on onboarding status
        await _handlePostLoginNavigation(user.uid);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        errorMessage.value = 'User does not exist. Please create an account.';
      } else if (e.code == 'wrong-password') {
        errorMessage.value = 'Invalid password. Please try again.';
      } else if (e.code == 'invalid-email') {
        errorMessage.value = 'Invalid email address format.';
      } else if (e.code == 'user-disabled') {
        errorMessage.value = 'This account has been disabled.';
      } else {
        errorMessage.value = 'Login failed: ${e.message}';
      }
      print('❌ Firebase Auth error: ${e.code} - ${e.message}');
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred: $e';
      print('❌ Unexpected login error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /*
  /// Send OTP to Phone (Firebase)
  Future<void> sendPhoneOTP(String phoneNumber) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (rare on iOS)
          await FirebaseAuth.instance.signInWithCredential(credential);
          await checkAuthStatus();
        },
        verificationFailed: (FirebaseAuthException e) {
          errorMessage.value = e.message ?? 'Verification failed';
          print('❌ OTP Send failed: ${e.code} - ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          Get.toNamed('/otp', arguments: {
            'verificationId': verificationId,
            'phoneNumber': phoneNumber,
            'isEmail': false,
          });
          successMessage.value = 'OTP sent to $phoneNumber';
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      errorMessage.value = 'Failed to send OTP: $e';
      print('❌ Error sending phone OTP: $e');
    } finally {
      isLoading.value = false;
    }
  }
  */

  /*
  /// Send OTP to Email (Firebase Login Link - alternative for Email OTP)
  /// Note: Firebase doesn't have a direct "6 digit code" for email like phone,
  /// but we can simulate it or use Email Link. For v4.0 SRS, we'll implement 
  /// a logic that handles the verification.
  Future<void> sendEmailOTP(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      var actionCodeSettings = ActionCodeSettings(
        url: 'https://activehealth.page.link/login',
        handleCodeInApp: true,
        iOSBundleId: 'com.active.tracker',
        androidPackageName: 'com.active.tracker',
        androidInstallApp: true,
        androidMinimumVersion: '12',
      );

      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
      
      // Save email locally to complete sign-in
      final authBox = Hive.box(AppConstants.authBoxName);
      await authBox.put('emailForSignIn', email);
      
      successMessage.value = 'Login link sent to $email';
      Get.snackbar('Email Sent', 'Please check your email for the login link.');
    } catch (e) {
      errorMessage.value = 'Failed to send email link: $e';
      print('❌ Error sending email link: $e');
    } finally {
      isLoading.value = false;
    }
  }
  */

  /*
  /// Verify OTP Code
  Future<void> verifyOTP(String verificationId, String smsCode) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = result.user;

      if (user != null) {
        isLoggedIn.value = true;
        userId.value = user.uid;
        // phoneNumber.value = user.phoneNumber ?? ''; // Removed as phoneNumber observable is removed
        print('✅ User logged in with OTP: ${user.phoneNumber}');
        
        await _handlePostLoginNavigation(user.uid);
      }
    } on FirebaseAuthException catch (e) {
      errorMessage.value = 'Invalid OTP: ${e.message}';
      print('❌ OTP verification failed: ${e.code}');
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred: $e';
    } finally {
      isLoading.value = false;
    }
  }
  */

  /// Pick and upload profile image
  Future<void> pickAndUploadProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return;

      isLoading.value = true;
      errorMessage.value = '';

      final File file = File(image.path);
      final String uid = userId.value;
      
      if (uid.isEmpty) throw Exception('User not logged in');

      print('🔄 Starting image upload for user: $uid');

      // 1. Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('profiles/$uid/photo.jpg');
      final uploadTask = storageRef.putFile(file);
      
      // Monitor progress (optional but good for debugging)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('📈 Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
      }, onError: (e) {
        print('❌ Upload task error: $e');
      });

      // Wait for upload to complete
      await uploadTask;
      print('✅ Upload task completed');
      
      // 2. Get Download URL with Retry mechanism
      String? downloadUrl;
      int retries = 0;
      const int maxRetries = 3;

      while (retries < maxRetries) {
        try {
          downloadUrl = await storageRef.getDownloadURL();
          break; // Success
        } catch (e) {
          retries++;
          print('⚠️ Error getting download URL (attempt $retries/$maxRetries): $e');
          if (retries >= maxRetries) rethrow;
          await Future.delayed(Duration(seconds: retries * 1)); // Exponential-ish backoff
        }
      }

      if (downloadUrl == null) throw Exception('Failed to retrieve download URL');

      // 3. Update Local and Cloud Profile via Repository
      final onboardingRepo = Get.find<OnboardingRepository>();
      await onboardingRepo.updateUserProfileImage(downloadUrl);
      
      // 4. Update state
      profileImageUrl.value = downloadUrl;
      successMessage.value = 'Profile picture updated successfully!';
      
      print('✅ Profile image uploaded and updated: $downloadUrl');
    } catch (e) {
      errorMessage.value = 'Failed to upload image: $e';
      print('❌ Image upload error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  final phoneNumber = ''.obs;

  /// Logout user
  Future<void> logout() async {
    try {
      isLoading.value = true;

      await FirebaseAuth.instance.signOut();
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print('⚠️ Google Sign Out warning: $e');
      }

      isLoggedIn.value = false;
      userId.value = '';
      userName.value = '';
      userEmail.value = '';

      try {
        final onboardingRepo = Get.find<OnboardingRepository>();
        await onboardingRepo.clearUserProfile();
      } catch (e) {
        print('⚠️ Error clearing profile on logout: $e');
      }

      print('✅ User logged out and profile cleared');
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
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        errorMessage.value = 'Please fill in all details';
        return;
      }

      if (password.length < 6) {
        errorMessage.value = 'Password must be at least 6 characters';
        return;
      }

      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user != null) {
        await user.updateDisplayName(name);
        
        // As requested: after successful sign up, show the sign in screen
        // We must sign out because Firebase auto-logs in after creation
        await FirebaseAuth.instance.signOut();
        
        isLoggedIn.value = false;
        successMessage.value = 'Registration successful! Please sign in.';
        print('✅ User registered and signed out for manual login: $email');
        
        // Navigate to login screen
        Get.offAllNamed('/login');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        errorMessage.value = 'This email is already registered.';
      } else if (e.code == 'weak-password') {
        errorMessage.value = 'The password provided is too weak.';
      } else if (e.code == 'invalid-email') {
        errorMessage.value = 'Invalid email address format.';
      } else {
        errorMessage.value = 'Registration failed: ${e.message}';
      }
      print('❌ Firebase Auth error: ${e.code} - ${e.message}');
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred: $e';
      print('❌ Unexpected registration error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      isLoading.value = true;

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      print('✅ Password reset email sent to $email');
    } catch (e) {
      errorMessage.value = 'Password reset failed: $e';
      print('❌ Password reset error: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      // Trigger the interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('ℹ️ Google Sign in canceled by user');
        return;
      }

      // Obtain the auth details (provides tokens)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        isLoggedIn.value = true;
        userId.value = user.uid;
        userName.value = user.displayName ?? '';
        userEmail.value = user.email ?? '';
        print('✅ User signed in with Google: ${user.email}');
        
        // Smart navigation based on onboarding status
        await _handlePostLoginNavigation(user.uid);
      }
    } catch (e) {
      if (e.toString().contains('canceled')) {
        print('ℹ️ Google Sign in canceled by user');
      } else {
        errorMessage.value = 'Google Sign In failed: $e';
        print('❌ Google Sign In error: $e');

        if (e.toString().contains('28444') || e.toString().contains('developer console')) {
          errorMessage.value =
              'Google Sign In error [28444]: Please ensure your SHA-1 and google-services.json are correctly configured in Firebase.';
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Get current user ID
  String getCurrentUserId() => userId.value;

  /// Get current user name
  String getCurrentUserName() => userName.value;

  /// Handle navigation after successful login/signup
  Future<void> _handlePostLoginNavigation(String userId) async {
    try {
      // ============ NEW: Store Session in authBox (v4.0) ============
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final authBox = Hive.box(AppConstants.authBoxName);
        final idToken = await user.getIdToken();
        
        await authBox.putAll({
          'userId': user.uid,
          'email': user.email ?? '',
          'phoneNumber': user.phoneNumber ?? '',
          'idToken': idToken,
          'lastLogin': DateTime.now().millisecondsSinceEpoch,
        });
      }

      // Check if onboarding is complete local first
      final onboardingRepo = Get.find<OnboardingRepository>();
      bool isComplete = await onboardingRepo.isOnboardingComplete();
      
      if (!isComplete) {
        // Try to sync from cloud
        print('🔄 Local profile missing, trying to sync from cloud...');
        isComplete = await onboardingRepo.syncUserProfileFromCloud(userId);
      }
      
      if (isComplete) {
        print('✅ Onboarding complete, going to dashboard');
        Get.offAllNamed('/dashboard');
      } else {
        print('📍 Onboarding incomplete, going to onboarding');
        Get.offAllNamed('/onboarding');
      }
    } catch (e) {
      print('⚠️ Error during post-login navigation: $e');
      // Fallback to dashboard if anything fails, better than getting stuck
      Get.offAllNamed('/dashboard');
    }
  }
}
