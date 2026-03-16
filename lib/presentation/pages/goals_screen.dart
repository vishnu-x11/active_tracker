import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/goals/goals_controller.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

class GoalsScreen extends GetView<GoalsController> {
  const GoalsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Setting & Predictions'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppPadding.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Prediction Card
              _buildPredictionCard(),
              
              const SizedBox(height: AppPadding.xl),
              
              Text(
                'Active Goals',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppPadding.md),
              
              ...controller.goals.map((goal) => _buildGoalItem(context, goal)).toList(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPredictionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppPadding.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          const Text(
            'AI Progress Prediction',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Based on your current activity and metabolism, you are on track to reach your weight goal in:',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 12),
          Text(
            '${controller.predictedDaysToGoal.value} Days',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Keep going! You are doing great.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(BuildContext context, UserGoal goal) {
    final double progress = (goal.current / goal.target).clamp(0.0, 1.0);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppPadding.md),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  goal.type,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${goal.current} / ${goal.target} ${goal.unit}',
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Get.snackbar('Edit Goal', 'Goal editing will be available soon.');
                },
                child: const Text('EDIT GOAL'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
