import 'package:active_tracker/presentation/widgets/goal_card.dart';
import 'package:active_tracker/presentation/widgets/sync_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:active_tracker/presentation/controllers/dashboard_controller.dart';
import 'package:active_tracker/presentation/controllers/premium/premium_controller.dart';
import 'package:active_tracker/config/constants.dart';
import 'package:active_tracker/config/theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DashboardController>(
      tag: 'dashboard',
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Active Tracker'),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Get.toNamed('/settings'),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Sync status
                  Obx(() => SyncStatusBadge(
                    isOnline: controller.isOnline.value,
                    isSyncing: controller.isSyncing.value,
                    lastSync: controller.lastSyncTime.value,
                  )),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Today's date
                        Text(
                          'Today\'s Progress',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),

                        // Calories Goal
                        Obx(() => GoalCard(
                          icon: Icons.restaurant,
                          title: 'Calories',
                          value: controller.todayCalories.value.toStringAsFixed(0),
                          unit: 'kcal',
                          goal: 2000,
                          progress: controller.todayCalories.value / 2000,
                          isMet: controller.todayCalories.value >= 1800,
                        )),

                        // Water Goal
                        Obx(() => GoalCard(
                          icon: Icons.local_drink,
                          title: 'Water',
                          value: controller.todayWater.value.toStringAsFixed(0),
                          unit: 'ml',
                          goal: 2500,
                          progress: controller.todayWater.value / 2500,
                          isMet: controller.todayWater.value >= 2500,
                        )),

                        // Workout Goal
                        Obx(() => GoalCard(
                          icon: Icons.fitness_center,
                          title: 'Workout',
                          value: controller.todayWorkoutMinutes.value.toStringAsFixed(0),
                          unit: 'min',
                          goal: controller.workoutGoal.value.toDouble(),
                          progress: controller.workoutProgress.value,
                          isMet: controller.isGoalMet('workout'),
                        )),

                        // Calories Burned Goal
                        Obx(() => GoalCard(
                          icon: Icons.local_fire_department,
                          title: 'Calories Burned',
                          value: controller.todayBurnedCalories.value.toStringAsFixed(0),
                          unit: 'kcal',
                          goal: controller.burnedCalorieGoal.value,
                          progress: controller.caloriesBurnedProgress.value,
                          isMet: controller.isGoalMet('burned'),
                        )),

                        // Weight Goal
                        Obx(() => GoalCard(
                          icon: Icons.scale,
                          title: 'Weight',
                          value: controller.todayWeight.value.toStringAsFixed(1),
                          unit: 'kg',
                          progress: 0.5,
                        )),

                        const SizedBox(height: 24),

                        // Quick actions
                        Text(
                          'Quick Actions',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),

                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: AppPadding.md,
                          crossAxisSpacing: AppPadding.md,
                          childAspectRatio: 1.0,
                          children: [
                             _buildQuickActionCard(
                              context,
                              Icons.fastfood,
                              'Log Food',
                              () => _handleAction(AppConstants.routeNutrition),
                            ),
                            _buildQuickActionCard(
                              context,
                              Icons.fitness_center,
                              'Log Workout',
                              () => _handleAction(AppConstants.routeTraining),
                            ),
                            _buildQuickActionCard(
                              context,
                              Icons.local_drink,
                              'Log Water',
                              () => _handleAction(AppConstants.routeHydration),
                            ),
                            _buildQuickActionCard(
                              context,
                              Icons.scale,
                              'Log Weight',
                              () => _handleAction(AppConstants.routeBmi),
                            ),
                            _buildQuickActionCard(
                              context,
                              Icons.insights,
                              'Insights',
                              () => _handleAction(AppConstants.routeAnalytics, isPremium: true),
                              isPremium: true,
                            ),
                            _buildQuickActionCard(
                              context,
                              Icons.fitness_center, // Different icon for program vs log
                              'Workouts',
                              () => _handleAction(AppConstants.routeWorkoutPrograms, isPremium: true),
                              isPremium: true,
                            ),
                            _buildQuickActionCard(
                              context,
                              Icons.restaurant_menu,
                              'Meal Plans',
                              () => _handleAction(AppConstants.routeMealPlanning, isPremium: true),
                              isPremium: true,
                            ),
                            _buildQuickActionCard(
                              context,
                              Icons.flag,
                              'Goals',
                              () => _handleAction(AppConstants.routeGoals, isPremium: true),
                              isPremium: true,
                            ),
                            _buildQuickActionCard(
                              context,
                              Icons.emoji_events,
                              'Collection',
                              () => _handleAction(AppConstants.routeAchievements, isPremium: true),
                              isPremium: true,
                            ),
                            _buildQuickActionCard(
                              context,
                              Icons.people,
                              'Community',
                              () => _handleAction(AppConstants.routeSocial, isPremium: true),
                              isPremium: true,
                            ),
                            _buildQuickActionCard(
                              context,
                              Icons.monitor_weight_outlined,
                              'Health',
                              () => _handleAction(AppConstants.routeBodyMetrics, isPremium: true),
                              isPremium: true,
                            ),
                            _buildQuickActionCard(
                              context,
                              Icons.watch,
                              'Devices',
                              () => _handleAction(AppConstants.routeDevices, isPremium: true),
                              isPremium: true,
                            ),
                            _buildQuickActionCard(
                              context,
                              Icons.psychology,
                              'AI Coach',
                              () => _handleAction(AppConstants.routeAICoach, isPremium: true),
                              isPremium: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleAction(String route, {bool isPremium = false}) {
    if (isPremium) {
      final premiumController = Get.find<PremiumController>();
      if (premiumController.isPremium.value) {
        Get.toNamed(route);
      } else {
        Get.toNamed(AppConstants.routePricing);
      }
    } else {
      Get.toNamed(route);
    }
  }

  Widget _buildQuickActionCard(
      BuildContext context,
      IconData icon,
      String label,
      VoidCallback onTap, {
        bool isPremium = false,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        color: AppTheme.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppTheme.white.withOpacity(0.1)),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 36, color: isPremium ? AppTheme.accent : AppTheme.primary),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (isPremium)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}