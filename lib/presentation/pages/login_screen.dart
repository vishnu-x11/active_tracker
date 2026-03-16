import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:active_tracker/presentation/controllers/auth_controller.dart';
import 'package:active_tracker/config/constants.dart';
import 'package:active_tracker/config/theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();

    return GetBuilder<AuthController>(
      builder: (controller) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.background, AppTheme.grey800],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    
                    // App Logo
                    Center(
                      child: Container(
                        height: 120,
                        width: 120,
                        padding: const EdgeInsets.all(AppPadding.md),
                        decoration: BoxDecoration(
                          color: AppTheme.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(color: AppTheme.white.withOpacity(0.1)),
                        ),
                        child: Image.asset('assets/images/logo.png'),
                      ),
                    ),
                    
                    const SizedBox(height: AppPadding.xl),
                    
                    Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppTheme.white,
                            letterSpacing: 1.2,
                          ),
                    ),
                    
                    const SizedBox(height: AppPadding.sm),
                    
                    Text(
                      'Your Journey Starts Here',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.white.withOpacity(0.6),
                          ),
                    ),
                    
                    const SizedBox(height: 50),

                    // Choice of Login Type (Password or OTP)
                    DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          TabBar(
                            tabs: const [
                              Tab(text: 'Password'),
                              Tab(text: 'OTP'),
                            ],
                            labelColor: AppTheme.primary,
                            unselectedLabelColor: AppTheme.white.withOpacity(0.5),
                            indicatorColor: AppTheme.primary,
                            dividerColor: Colors.transparent,
                          ),
                          const SizedBox(height: AppPadding.lg),
                          SizedBox(
                            height: 250,
                            child: TabBarView(
                              children: [
                                // PASSWORD LOGIN
                                Column(
                                  children: [
                                    TextField(
                                      controller: emailController,
                                      style: const TextStyle(color: AppTheme.white),
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: Icon(Icons.email_outlined),
                                      ),
                                    ),
                                    const SizedBox(height: AppPadding.md),
                                    TextField(
                                      controller: passwordController,
                                      obscureText: true,
                                      style: const TextStyle(color: AppTheme.white),
                                      decoration: const InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: Icon(Icons.lock_outlined),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          if (emailController.text.trim().isNotEmpty) {
                                            controller.resetPassword(emailController.text.trim());
                                          }
                                        },
                                        child: const Text('Forgot Password?'),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // OTP LOGIN
                                Column(
                                  children: [
                                    TextField(
                                      controller: phoneController,
                                      keyboardType: TextInputType.phone,
                                      style: const TextStyle(color: AppTheme.white),
                                      decoration: const InputDecoration(
                                        labelText: 'Phone Number',
                                        hintText: '+1234567890',
                                        prefixIcon: Icon(Icons.phone_outlined),
                                      ),
                                    ),
                                    const SizedBox(height: AppPadding.lg),
                                    const Text(
                                      'We will send a 6-digit verification code to your phone number.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Actions
                    Obx(() => controller.errorMessage.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: AppPadding.md),
                            child: Text(
                              controller.errorMessage.value,
                              style: const TextStyle(color: AppTheme.error),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : const SizedBox.shrink()),

                    Obx(() => ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () {
                                  // Simplified logic: if phone is filled, assume OTP
                                  if (phoneController.text.trim().isNotEmpty) {
                                    controller.sendPhoneOTP(phoneController.text.trim());
                                  } else {
                                    controller.login(
                                      email: emailController.text.trim(),
                                      password: passwordController.text,
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        )),

                    const SizedBox(height: AppPadding.xl),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppTheme.white.withOpacity(0.1))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
                          child: Text('OR', style: TextStyle(color: AppTheme.white.withOpacity(0.3))),
                        ),
                        Expanded(child: Divider(color: AppTheme.white.withOpacity(0.1))),
                      ],
                    ),

                    const SizedBox(height: AppPadding.xl),

                    // Social Logins
                    OutlinedButton.icon(
                      onPressed: controller.isLoading.value ? null : () => controller.signInWithGoogle(),
                      icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg', height: 24),
                      label: const Text('Google', style: TextStyle(color: AppTheme.white)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppTheme.white.withOpacity(0.1)),
                      ),
                    ),

                    const SizedBox(height: AppPadding.xl),

                    // Sign Up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("New to Active Health? ", style: TextStyle(color: AppTheme.white.withOpacity(0.6))),
                        TextButton(
                          onPressed: () => Get.toNamed(AppConstants.routeSignup),
                          child: const Text('Create Account', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppPadding.xl),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
