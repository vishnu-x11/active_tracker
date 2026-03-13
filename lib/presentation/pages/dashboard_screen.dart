import 'package:active_tracker/presentation/pages/settings_screen.dart';
import 'package:active_tracker/presentation/widgets/sync_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:active_tracker/presentation/controllers/dashboard_controller.dart';

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
                          goal: 30,
                          progress: controller.todayWorkoutMinutes.value / 30,
                          isMet: controller.todayWorkoutMinutes.value >= 30,
                        )),

                        // Weight Goal
                        Obx(() => GoalCard(
                          icon: Icons.scale,
                          title: 'Weight',
                          value: '${controller.todayWeight.value.toStringAsFixed(1)}',
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
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            _buildQuickActionCard(
                              context,
                              Icons.fastfood,
                              'Log Food',
                                  () => Get.toNamed('/nutrition'),
                            ),
                            _buildQuickActionCard(
                              context,
                              Icons.fitness_center,
                              'Log Workout',
                                  () => Get.toNamed('/training'),
                            ),
                            _buildQuickActionCard(
                              context,
                              Icons.local_drink,
                              'Log Water',
                                  () => Get.toNamed('/hydration'),
                            ),
                            _buildQuickActionCard(
                              context,
                              Icons.scale,
                              'Log Weight',
                                  () => Get.toNamed('/bmi'),
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

  Widget _buildQuickActionCard(
      BuildContext context,
      IconData icon,
      String label,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}