import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:active_tracker/presentation/controllers/auth_controller.dart';
import 'package:active_tracker/domain/repositories/repositories.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Navigate after 3 seconds based on auth status
    Future.delayed(const Duration(seconds: 3), () async {
      final authController = Get.find<AuthController>();
      
      if (authController.isLoggedIn.value) {
        // Use the same smart navigation logic
        final onboardingRepo = Get.find<OnboardingRepository>();
        final isComplete = await onboardingRepo.isOnboardingComplete();
        
        if (isComplete) {
          Get.offAllNamed('/dashboard');
        } else {
          // Try cloud sync one more time
          final synced = await onboardingRepo.syncUserProfileFromCloud(authController.userId.value);
          if (synced) {
            Get.offAllNamed('/dashboard');
          } else {
            Get.offAllNamed('/onboarding');
          }
        }
      } else {
        Get.offAllNamed('/login');
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.fitness_center,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 32),
              Text(
                'Active Tracker',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Track Your Fitness Goals',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 64),
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                  strokeWidth: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}