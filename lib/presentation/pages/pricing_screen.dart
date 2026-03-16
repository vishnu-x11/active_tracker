import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/premium/premium_controller.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

class PricingScreen extends GetView<PremiumController> {
  const PricingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Go Premium')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.lg),
        child: Column(
          children: [
            const Icon(Icons.star, size: 80, color: AppTheme.warning),
            const SizedBox(height: 24),
            const Text(
              'Unlock Active Health PRO',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'Get access to AI coaching, advanced analytics, custom meal plans, and more.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 40),
            _buildFeatureRow(Icons.psychology, 'AI Health Coaching'),
            _buildFeatureRow(Icons.analytics, 'Advanced Performance Insights'),
            _buildFeatureRow(Icons.flatware, 'Smart Meal Planning'),
            _buildFeatureRow(Icons.watch, 'Premium Device Integration'),
            const SizedBox(height: 40),
            _buildPricingCard(
              'PRO MONTHLY',
              '\$9.99/mo',
              'Perfect for getting started.',
              false,
            ),
            const SizedBox(height: 16),
            _buildPricingCard(
              'PRO ANNUAL',
              '\$79.99/yr',
              'Best value. Save 33%.',
              true,
            ),
            const SizedBox(height: 40),
            Obx(() => SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: controller.isLoading.value 
                  ? null 
                  : () => controller.upgradeToPremium(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                ),
                child: controller.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('UPGRADE NOW', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 16),
          Text(text, style: const TextStyle(color: AppTheme.white)),
        ],
      ),
    );
  }

  Widget _buildPricingCard(String title, String price, String desc, bool isBestValue) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.md),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isBestValue ? AppTheme.primary : Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.white)),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ],
      ),
    );
  }
}
