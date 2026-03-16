import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:active_tracker/presentation/controllers/training_controller.dart';
import 'package:active_tracker/config/constants.dart';
import 'package:active_tracker/data/models/sqlite/exercise_definition.dart';
import 'package:active_tracker/presentation/widgets/date_navigator.dart';

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
                DateNavigator(
                  selectedDate: controller.selectedDate.value,
                  onPrevious: controller.previousDay,
                  onNext: controller.nextDay,
                  onToday: controller.goToday,
                ),
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
                            Text(
                              'Workouts',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                (log) => Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.fitness_center),
                                    title: Text(log.workoutName),
                                    subtitle: Text('${log.duration} min • ${log.caloriesBurned.toStringAsFixed(0)} kcal'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => controller.deleteWorkout(log.id ?? 0),
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),

                             // Exercises Section
                            Text(
                              'Exercises',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        entry.key.toUpperCase(),
                                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                          letterSpacing: 1.2,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    ...entry.value.map((ex) => Card(
                                      child: ListTile(
                                        leading: const Icon(Icons.sports_gymnastics),
                                        title: Text(ex.exerciseType),
                                        subtitle: Text('${ex.reps} reps × ${ex.sets} sets'),
                                        trailing: ex.weight != null
                                            ? Text('${ex.weight!.toStringAsFixed(1)} kg')
                                            : null,
                                      ),
                                    )),
                                    const SizedBox(height: 8),
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
                  child: const Icon(Icons.add),
                ),
                FloatingActionButton(
                  heroTag: 'add_workout',
                  onPressed: () => _showAddWorkoutDialog(context),
                  tooltip: 'Add General Workout Session',
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
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

  void _showAddWorkoutDialog(BuildContext context) {
    final controller = Get.find<TrainingController>(tag: 'training');
    final nameCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final caloriesCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Add Workout'),
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
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              controller.addWorkout(
                workoutName: nameCtrl.text.trim(),
                duration: int.tryParse(durationCtrl.text) ?? 0,
                caloriesBurned: double.tryParse(caloriesCtrl.text) ?? 0,
              );
              Get.back();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context) {
    final controller = Get.find<TrainingController>(tag: 'training');
    final repsCtrl = TextEditingController(text: '10');
    final setsCtrl = TextEditingController(text: '3');
    final weightCtrl = TextEditingController();

    // Reset controller state
    controller.clearSelection();

    Get.dialog(
      Dialog(
        child: Container(
          padding: const EdgeInsets.all(AppPadding.md),
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Exercise', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search exercises...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => controller.searchExercises(value),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  // If searching, show suggestions, else show all categorized by groups
                  // For simplicity, let's just show all library items if search is empty
                  final list = controller.exerciseSuggestions;
                  
                  if (list.isEmpty && !controller.isSearching.value) {
                    // Show a message or a default list
                    return const Center(child: Text('Search for an exercise to log'));
                  }

                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return ListTile(
                        title: Text(item.name),
                        trailing: Text(
                          item.category,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        onTap: () {
                          _showDetailsForm(context, controller, item, repsCtrl, setsCtrl, weightCtrl);
                        },
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  controller.clearSuggestions();
                  Get.back();
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
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
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
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
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }
}
