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
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      margin: const EdgeInsets.only(top: 16, bottom: 8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(getCategoryIcon(category), size: 18, color: Theme.of(context).colorScheme.primary),
                                          const SizedBox(width: 8),
                                          Text(
                                            category.toUpperCase(),
                                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                              color: Theme.of(context).colorScheme.primary,
                                              letterSpacing: 1.2,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ...exercises.map((ex) => Card(
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                          child: Icon(getCategoryIcon(category), size: 16, color: Theme.of(context).colorScheme.secondary),
                                        ),
                                        title: Text(ex.exerciseType),
                                        subtitle: Text('${ex.reps} reps × ${ex.sets} sets'),
                                        trailing: ex.weight != null
                                            ? Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${ex.weight!.toStringAsFixed(1)} kg',
                                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                                                ),
                                              )
                                            : null,
                                      ),
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
    final searchCtrl = TextEditingController();

    // Reset controller state
    controller.clearSelection();
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
                      return InkWell(
                        onTap: () => controller.selectCategory(category),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            category,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
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
