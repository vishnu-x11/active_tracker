import 'package:flutter/material.dart' hide Badge;
import 'package:get/get.dart';
import '../controllers/gamification/gamification_controller.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

class AchievementsScreen extends GetView<GamificationController> {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements & Badges'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          children: [
            // Streak Section
            _buildStreakCard(),
            
            const SizedBox(height: AppPadding.xl),
            
            // Badges Grid
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Collection',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.white),
              ),
            ),
            const SizedBox(height: AppPadding.md),
            
            Obx(() => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppPadding.md,
                mainAxisSpacing: AppPadding.md,
                childAspectRatio: 0.8,
              ),
              itemCount: controller.badges.length,
              itemBuilder: (context, index) {
                final badge = controller.badges[index];
                return _buildBadgeItem(badge);
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppPadding.lg),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.fireplace, color: AppTheme.warning, size: 64),
          const SizedBox(height: 8),
          Obx(() => Text(
            '${controller.currentStreak.value} Days Streak!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.white),
          )),
          const Text(
            'Keep it up! You are on fire.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          // Progress bar to next milestone
          const LinearProgressIndicator(
            value: 0.7,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.warning),
          ),
          const SizedBox(height: 8),
          const Text(
            '2 days to 7-day milestone',
            style: TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(Badge badge) {
    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: badge.isUnlocked ? AppTheme.primary.withOpacity(0.2) : Colors.white10,
            shape: BoxShape.circle,
            border: Border.all(
              color: badge.isUnlocked ? AppTheme.primary : Colors.white24,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              badge.icon,
              style: TextStyle(
                fontSize: 32,
                color: Colors.white.withOpacity(badge.isUnlocked ? 1.0 : 0.3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          badge.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: badge.isUnlocked ? AppTheme.white : Colors.white38,
            fontWeight: badge.isUnlocked ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
