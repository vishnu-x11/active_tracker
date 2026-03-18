import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:active_tracker/data/models/sqlite/workout_log.dart';
import 'package:active_tracker/data/models/sqlite/exercise.dart';
import 'package:active_tracker/presentation/controllers/training_controller.dart';
import 'package:active_tracker/config/constants.dart';
import 'package:active_tracker/data/models/sqlite/exercise_definition.dart';
import 'package:active_tracker/presentation/widgets/date_navigator.dart';
import 'package:active_tracker/presentation/widgets/common/container_widget.dart';
import 'package:active_tracker/presentation/widgets/common/text_widget.dart';
import 'package:active_tracker/presentation/widgets/common/button_widget.dart';
import 'package:active_tracker/utils/app_colors.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TrainingController>(
      tag: 'training',
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Training'),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.today),
                tooltip: 'Go to today',
                onPressed: controller.goToday,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Obx(() => DateNavigator(
                  selectedDate: controller.selectedDate.value,
                  onPrevious: controller.previousDay,
                  onNext: controller.nextDay,
                  onToday: controller.goToday,
                  onDateTap: () => controller.selectDate(context),
                )),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return RefreshIndicator(
                      onRefresh: controller.loadTrainingData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppPadding.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Summary Cards
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    context,
                                    Icons.timer,
                                    'Duration',
                                    controller.getTotalDurationString(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatCard(
                                    context,
                                    Icons.local_fire_department,
                                    'Burned',
                                    controller.getCaloriesBurnedString(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Error message
                            if (controller.errorMessage.value.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  controller.errorMessage.value,
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                ),
                              ),

                            // Workout Logs Section
                            const TextWidget(
                              'Workouts',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                            const SizedBox(height: 8),
                            if (controller.workoutLogs.isEmpty)
                              _buildEmptyState(
                                context,
                                Icons.fitness_center,
                                'No workouts logged yet',
                                'Tap + to add a workout',
                              )
                            else
                              ...controller.workoutLogs.map(
                                (log) => ContainerWidget(
                                  backgroundColor: AppColors.white,
                                  borderColor: const Color(0xFFEEEEEE),
                                  borderRadius: 16,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(4),
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.fitness_center, color: AppColors.primary),
                                      title: TextWidget(log.workoutName, fontWeight: FontWeight.w600),
                                      subtitle: TextWidget(
                                        '${log.duration} min • ${log.caloriesBurned.toStringAsFixed(0)} kcal',
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                            onPressed: () => _showAddWorkoutDialog(context, workoutLog: log),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                            onPressed: () => controller.deleteWorkout(log.id ?? 0),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 16),

                             // Exercises Section
                            const TextWidget(
                              'Exercises',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                            const SizedBox(height: 8),
                            if (controller.exercises.isEmpty)
                              _buildEmptyState(
                                context,
                                Icons.sports_gymnastics,
                                'No exercises logged yet',
                                'Tap + to log pushups, pullups, etc.',
                              )
                            else
                              ...controller.getGroupedExercises().entries.map((entry) {
                                final category = entry.key;
                                final exercises = entry.value;
                                
                                IconData getCategoryIcon(String category) {
                                  switch (category.toLowerCase()) {
                                    case 'chest': return Icons.fitness_center;
                                    case 'back': return Icons.straighten;
                                    case 'shoulder': return Icons.accessibility;
                                    case 'biceps':
                                    case 'triceps':
                                    case 'fore arms': return Icons.legend_toggle;
                                    case 'leg': return Icons.directions_walk;
                                    case 'abs': return Icons.grid_view;
                                    case 'pushups': return Icons.upload;
                                    case 'pullups': return Icons.download;
                                    case 'cardio': return Icons.favorite;
                                    default: return Icons.sports_gymnastics;
                                  }
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ContainerWidget(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      margin: const EdgeInsets.only(top: 20, bottom: 12),
                                      backgroundColor: AppColors.primaryWith20,
                                      borderColor: AppColors.primaryWith50,
                                      borderRadius: 12,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(getCategoryIcon(category), size: 20, color: AppColors.primary),
                                            const SizedBox(width: 12),
                                            TextWidget(
                                              category.toUpperCase(),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
                                              onPressed: () {
                                                controller.selectCategory(category);
                                                _showAddExerciseDialog(context, initialCategory: category);
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    ...exercises.map((ex) => ContainerWidget(
                                      backgroundColor: AppColors.white,
                                      borderColor: const Color(0xFFEEEEEE),
                                      borderRadius: 16,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(4),
                                      children: [
                                        ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: AppColors.primaryWith20,
                                            child: Icon(getCategoryIcon(category), size: 18, color: AppColors.primary),
                                          ),
                                          title: TextWidget(ex.exerciseType, fontWeight: FontWeight.w600),
                                          subtitle: TextWidget(
                                            '${ex.reps} reps × ${ex.sets} sets',
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (ex.weight != null)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    margin: const EdgeInsets.only(right: 4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF5F5F5),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: TextWidget(
                                                      '${ex.weight!.toStringAsFixed(1)} kg',
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                                                  onPressed: () => _showEditExerciseDialog(context, ex),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                                  onPressed: () => controller.deleteExercise(ex.id ?? 0),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                        ),
                                      ],
                                    )),
                                  ],
                                );
                              }),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  heroTag: 'add_exercise',
                  onPressed: () => _showAddExerciseDialog(context),
                  tooltip: 'Add Exercise',
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  child: const Icon(Icons.add),
                ),
                FloatingActionButton(
                  heroTag: 'add_workout',
                  onPressed: () => _showAddWorkoutDialog(context),
                  tooltip: 'Add General Workout Session',
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  child: const Icon(Icons.playlist_add),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String label, String value) {
    return ContainerWidget(
      backgroundColor: AppColors.white,
      borderColor: AppColors.transparent,
      borderWidth: 0,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        TextWidget(
          value,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
        TextWidget(
          label,
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.bodyLarge),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  void _showAddWorkoutDialog(BuildContext context, {WorkoutLog? workoutLog}) {
    final controller = Get.find<TrainingController>(tag: 'training');
    final nameCtrl = TextEditingController(text: workoutLog?.workoutName ?? '');
    final durationCtrl = TextEditingController(text: workoutLog?.duration.toString() ?? '');
    final caloriesCtrl = TextEditingController(text: workoutLog?.caloriesBurned.toString() ?? '');

    Get.dialog(
      AlertDialog(
        title: Text(workoutLog == null ? 'Add Workout' : 'Edit Workout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Workout Name')),
            const SizedBox(height: 8),
            TextField(controller: durationCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration (min)')),
            const SizedBox(height: 8),
            TextField(controller: caloriesCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories Burned')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const TextWidget('Cancel', color: AppColors.textSecondary)),
          ButtonWidget(
            width: 100,
            height: 40,
            onPressed: () {
              if (workoutLog == null) {
                controller.addWorkout(
                  workoutName: nameCtrl.text.trim(),
                  duration: int.tryParse(durationCtrl.text) ?? 0,
                  caloriesBurned: double.tryParse(caloriesCtrl.text) ?? 0,
                );
              } else {
                final updated = workoutLog.copyWith(
                  workoutName: nameCtrl.text.trim(),
                  duration: int.tryParse(durationCtrl.text) ?? 0,
                  caloriesBurned: double.tryParse(caloriesCtrl.text) ?? 0,
                  updatedAt: DateTime.now().millisecondsSinceEpoch,
                );
                controller.updateWorkout(updated);
              }
              Get.back();
            },
            textWidget: TextWidget(workoutLog == null ? 'Add' : 'Update', color: AppColors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context, {String? initialCategory}) {
    final controller = Get.find<TrainingController>(tag: 'training');
    final repsCtrl = TextEditingController(text: '10');
    final setsCtrl = TextEditingController(text: '3');
    final weightCtrl = TextEditingController();
    final searchCtrl = TextEditingController();

    // Reset controller state if no initial category
    if (initialCategory == null) {
      controller.clearSelection();
    }
    controller.clearSuggestions();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Container(
          padding: const EdgeInsets.all(AppPadding.md),
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Exercise', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                  labelText: 'Search exercises...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchCtrl.clear();
                      controller.clearSuggestions();
                    },
                  ),
                ),
                onChanged: (value) => controller.searchExercises(value),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  // PRIORITY 1: Search results
                  if (searchCtrl.text.isNotEmpty) {
                    if (controller.isSearching.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (controller.exerciseSuggestions.isEmpty) {
                      return const Center(child: Text('No exercises found'));
                    }
                    return ListView.builder(
                      itemCount: controller.exerciseSuggestions.length,
                      itemBuilder: (context, index) => _buildExerciseTile(
                        context,
                        controller,
                        controller.exerciseSuggestions[index],
                        repsCtrl,
                        setsCtrl,
                        weightCtrl,
                      ),
                    );
                  }

                  // PRIORITY 2: Exercises within a selected category
                  if (controller.selectedCategory.isNotEmpty) {
                    return Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.arrow_back),
                          title: Text('Back to Categories', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                          onTap: () => controller.clearSelection(),
                        ),
                        const Divider(),
                        Expanded(
                          child: controller.isLoading.value 
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                itemCount: controller.exercisesByCategory.length,
                                itemBuilder: (context, index) => _buildExerciseTile(
                                  context,
                                  controller,
                                  controller.exercisesByCategory[index],
                                  repsCtrl,
                                  setsCtrl,
                                  weightCtrl,
                                ),
                              ),
                        ),
                      ],
                    );
                  }

                  // PRIORITY 3: Category Grid
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: controller.categories.length,
                    itemBuilder: (context, index) {
                      final category = controller.categories[index];
                      return ContainerWidget(
                        onPressed: () => controller.selectCategory(category),
                        backgroundColor: AppColors.primaryWith20,
                        borderColor: AppColors.primaryWith50,
                        borderRadius: 12,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextWidget(
                            category,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ],
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseTile(
    BuildContext context,
    TrainingController controller,
    ExerciseDefinition item,
    TextEditingController repsCtrl,
    TextEditingController setsCtrl,
    TextEditingController weightCtrl,
  ) {
    return ListTile(
      title: Text(item.name),
      subtitle: Text(item.category),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showDetailsForm(context, controller, item, repsCtrl, setsCtrl, weightCtrl);
      },
    );
  }

  void _showDetailsForm(
    BuildContext context,
    TrainingController controller,
    ExerciseDefinition exercise,
    TextEditingController repsCtrl,
    TextEditingController setsCtrl,
    TextEditingController weightCtrl,
  ) {
    Get.back(); // Close category/list dialog
    
    Get.dialog(
      AlertDialog(
        title: Text('Log ${exercise.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(exercise.category, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 16),
            TextField(
              controller: repsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: setsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sets'),
            ),
            if (!exercise.isBodyweight) ...[
              const SizedBox(height: 8),
              TextField(
                controller: weightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Weight (kg)', suffixText: 'kg'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const TextWidget('Cancel', color: AppColors.textSecondary)),
          ButtonWidget(
            width: 100,
            height: 40,
            onPressed: () {
              controller.addExercise(
                exerciseType: exercise.name,
                category: exercise.category,
                reps: int.tryParse(repsCtrl.text) ?? 0,
                sets: int.tryParse(setsCtrl.text) ?? 1,
                weight: double.tryParse(weightCtrl.text),
              );
              Get.back();
            },
            textWidget: const TextWidget('Log', color: AppColors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showEditExerciseDialog(BuildContext context, Exercise exercise) {
    final controller = Get.find<TrainingController>(tag: 'training');
    final repsCtrl = TextEditingController(text: exercise.reps.toString());
    final setsCtrl = TextEditingController(text: exercise.sets.toString());
    final weightCtrl = TextEditingController(text: exercise.weight?.toString() ?? '');

    Get.dialog(
      AlertDialog(
        title: Text('Edit ${exercise.exerciseType}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(exercise.category, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 16),
            TextField(
              controller: repsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: setsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sets'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: weightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Weight (kg)', suffixText: 'kg'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const TextWidget('Cancel', color: AppColors.textSecondary)),
          ButtonWidget(
            width: 100,
            height: 40,
            onPressed: () {
              final updated = exercise.copyWith(
                reps: int.tryParse(repsCtrl.text) ?? 0,
                sets: int.tryParse(setsCtrl.text) ?? 1,
                weight: double.tryParse(weightCtrl.text),
                updatedAt: DateTime.now().millisecondsSinceEpoch,
              );
              controller.updateExercise(updated);
              Get.back();
            },
            textWidget: const TextWidget('Update', color: AppColors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

}
