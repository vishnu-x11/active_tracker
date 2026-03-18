import 'package:active_tracker/presentation/widgets/sync_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:active_tracker/presentation/controllers/dashboard_controller.dart';
import 'package:active_tracker/presentation/controllers/premium/premium_controller.dart';
import 'package:active_tracker/config/constants.dart';
import 'package:active_tracker/config/theme.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';

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
            child: RefreshIndicator(
              onRefresh: controller.loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Sync status
                  Obx(() => SyncStatusBadge(
                    isOnline: controller.isOnline.value,
                    isSyncing: controller.isSyncing.value,
                    lastSync: controller.lastSyncTime.value,
                  )),

                  const SizedBox(height: 16),

                  // Horizontal Calendar
                  Visibility(
                    visible: false, // User requested to hide the calendar
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Obx(() => EasyDateTimeLine(
                        initialDate: controller.today.value,
                        onDateChange: (selectedDate) {
                          controller.updateSelectedDate(selectedDate);
                        },
                        headerProps: const EasyHeaderProps(
                          monthPickerType: MonthPickerType.switcher,
                          dateFormatter: DateFormatter.fullDateMonthAsStrDY(),
                        ),
                        dayProps: const EasyDayProps(
                          dayStructure: DayStructure.dayStrDayNum,
                          activeDayStyle: DayStyle(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xff3371ff),
                                  Color(0xff8426ff),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Today's date & Streak
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Daily Progress',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Obx(() => controller.streakCount.value > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${controller.streakCount.value} Days',
                                          style: const TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink()),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Redesigned Daily Summary Card
                        Obx(() => _buildDailySummaryCard(context, controller)),

                        const SizedBox(height: 16),

                        // Macro Overview Row
                        Obx(() => _buildMacroOverview(context, controller)),

                        const SizedBox(height: 24),

                        // Other Goals (Water, Workout, Burned)
                        Text(
                          'Other Goals',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),

                        // Water Goal (Compact)
                        Obx(() => _buildCompactGoalCard(
                          context,
                          icon: Icons.local_drink,
                          title: 'Water',
                          value: controller.todayWater.value.toStringAsFixed(0),
                          unit: 'ml',
                          goal: controller.waterGoal.value,
                          isMet: controller.isGoalMet('water'),
                        )),

                        // Workout Goal (Compact)
                        Obx(() => _buildCompactGoalCard(
                          context,
                          icon: Icons.fitness_center,
                          title: 'Workout',
                          value: controller.todayWorkoutMinutes.value.toStringAsFixed(0),
                          unit: 'min',
                          goal: controller.workoutGoal.value.toDouble(),
                          isMet: controller.isGoalMet('workout'),
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
                            // _buildQuickActionCard(
                            //   context,
                            //   Icons.flag,
                            //   'Goals',
                            //   () => _handleAction(AppConstants.routeGoals, isPremium: true),
                            //   isPremium: true,
                            // ),
                            // _buildQuickActionCard(
                            //   context,
                            //   Icons.emoji_events,
                            //   'Collection',
                            //   () => _handleAction(AppConstants.routeAchievements, isPremium: true),
                            //   isPremium: true,
                            // ),
                            // _buildQuickActionCard(
                            //   context,
                            //   Icons.people,
                            //   'Community',
                            //   () => _handleAction(AppConstants.routeSocial, isPremium: true),
                            //   isPremium: true,
                            // ),
                            // _buildQuickActionCard(
                            //   context,
                            //   Icons.monitor_weight_outlined,
                            //   'Health',
                            //   () => _handleAction(AppConstants.routeBodyMetrics, isPremium: true),
                            //   isPremium: true,
                            // ),
                            // _buildQuickActionCard(
                            //   context,
                            //   Icons.watch,
                            //   'Devices',
                            //   () => _handleAction(AppConstants.routeDevices, isPremium: true),
                            //   isPremium: true,
                            // ),
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

  Widget _buildDailySummaryCard(BuildContext context, DashboardController controller) {
    if (controller.isLoading.value) {
      return const Card(
        child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      );
    }

    final double consumed = controller.todayCalories.value;
    final double burned = controller.todayBurnedCalories.value;
    final double goal = controller.caloriesGoal.value;
    final double remaining = controller.remainingCalories;
    final double progress = (consumed / (goal + burned)).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withOpacity(0.15),
            AppTheme.accent.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: AppTheme.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 180,
                width: 180,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: AppTheme.white.withOpacity(0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    remaining.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.white,
                    ),
                  ),
                  Text(
                    'Remaining',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryStat('Goal', goal.toStringAsFixed(0), Icons.flag_outlined),
              _buildSummaryStat('Food', consumed.toStringAsFixed(0), Icons.restaurant_outlined),
              _buildSummaryStat('Exercise', burned.toStringAsFixed(0), Icons.fitness_center_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.white.withOpacity(0.5)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.white),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppTheme.white.withOpacity(0.5)),
        ),
      ],
    );
  }

  Widget _buildMacroOverview(BuildContext context, DashboardController controller) {
    return Row(
      children: [
        Expanded(child: _buildMacroProgress('Protein', controller.todayProtein.value, controller.proteinGoal.value, Colors.purpleAccent)),
        const SizedBox(width: 8),
        Expanded(child: _buildMacroProgress('Carbs', controller.todayCarbs.value, controller.carbsGoal.value, Colors.blueAccent)),
        const SizedBox(width: 8),
        Expanded(child: _buildMacroProgress('Fat', controller.todayFat.value, controller.fatGoal.value, Colors.orangeAccent)),
      ],
    );
  }

  Widget _buildMacroProgress(String label, double value, double goal, Color color) {
    final double progress = (value / goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              Text('${value.toStringAsFixed(0)}g', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppTheme.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Text('${goal.toStringAsFixed(0)}g Goal', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4))),
        ],
      ),
    );
  }

  Widget _buildCompactGoalCard(BuildContext context, {required IconData icon, required String title, required String value, required String unit, required double goal, required bool isMet}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(icon, color: isMet ? Colors.green : AppTheme.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('$value / ${goal.toStringAsFixed(0)} $unit', style: TextStyle(color: AppTheme.white.withOpacity(0.6), fontSize: 12)),
              ],
            ),
          ),
          if (isMet) const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
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