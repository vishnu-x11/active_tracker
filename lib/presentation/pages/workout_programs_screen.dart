import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/workouts/workout_programs_controller.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

class WorkoutProgramsScreen extends GetView<WorkoutProgramsController> {
  const WorkoutProgramsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Workout Programs'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppPadding.md),
          itemCount: controller.programs.length,
          itemBuilder: (context, index) {
            final program = controller.programs[index];
            return _buildProgramCard(context, program);
          },
        );
      }),
    );
  }

  Widget _buildProgramCard(BuildContext context, WorkoutProgram program) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppPadding.md),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppTheme.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Program Image Placeholder / Accent
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary.withOpacity(0.5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(Icons.fitness_center, size: 48, color: Colors.white),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(AppPadding.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        program.category,
                        style: const TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '${program.durationWeeks} Weeks',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  program.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  program.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.trending_up, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      program.level,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        Get.snackbar('Coming Soon', 'Workout program enrollment will be available in the next minor update.');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: const Text('ENROLL'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
