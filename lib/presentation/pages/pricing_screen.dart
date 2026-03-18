import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/premium/premium_controller.dart';
import '../../utils/app_colors.dart';
import '../widgets/common/container_widget.dart';
import '../widgets/common/text_widget.dart';
import '../widgets/common/button_widget.dart';

class PricingScreen extends GetView<PremiumController> {
  const PricingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Go Premium')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.star_rounded, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            const TextWidget(
              'Unlock Active Health PRO',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
              color: AppColors.textPrimary,
            ),
            const SizedBox(height: 12),
            const TextWidget(
              'Get access to AI coaching, advanced analytics, custom meal plans, and more.',
              textAlign: TextAlign.center,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 48),
            _buildFeatureRow(Icons.psychology, 'AI Health Coaching'),
            _buildFeatureRow(Icons.analytics, 'Advanced Performance Insights'),
            _buildFeatureRow(Icons.flatware, 'Smart Meal Planning'),
            _buildFeatureRow(Icons.watch, 'Premium Device Integration'),
            const SizedBox(height: 48),
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
            const SizedBox(height: 48),
            Obx(() => ButtonWidget(
              onPressed: controller.isLoading.value ? () {} : () => controller.upgradeToPremium(),
              buttonColor: AppColors.primary,
              textWidget: controller.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                    )
                  : const TextWidget('UPGRADE NOW', color: AppColors.white, fontWeight: FontWeight.w700),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 16),
          TextWidget(text, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        ],
      ),
    );
  }

  Widget _buildPricingCard(String title, String price, String desc, bool isBestValue) {
    return ContainerWidget(
      backgroundColor: isBestValue ? AppColors.white : AppColors.background,
      borderColor: isBestValue ? AppColors.primary : const Color(0xFFEEEEEE),
      borderWidth: isBestValue ? 2 : 1,
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      margin: EdgeInsets.zero,
      boxShadow: isBestValue ? [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        )
      ] : null,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(title, fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
                  const SizedBox(height: 4),
                  TextWidget(desc, fontSize: 13, color: AppColors.textSecondary),
                ],
              ),
            ),
            TextWidget(price, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
          ],
        ),
      ],
    );
  }
}
