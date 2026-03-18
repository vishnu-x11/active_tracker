import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:active_tracker/presentation/controllers/daily_log_controller.dart';
import 'package:active_tracker/config/constants.dart';
import 'package:active_tracker/presentation/widgets/date_navigator.dart';

class DailyLogScreen extends StatelessWidget {
  const DailyLogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DailyLogController>(
      tag: 'daily_log',
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Daily Log'),
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
                // Date Navigator
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
                      onRefresh: controller.refreshDailyLog,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppPadding.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Goals Summary Card
                            _buildGoalsSummaryCard(context, controller),
                            const SizedBox(height: 16),

                            // Goals Status Grid
                            _buildGoalsGrid(context, controller),
                            const SizedBox(height: 16),

                            // Mood Section
                            _buildMoodSection(context, controller),
                            const SizedBox(height: 16),

                            // Notes Section
                            _buildNotesSection(context, controller),
                            const SizedBox(height: 16),

                            // Achievement Message
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(AppPadding.md),
                                child: Row(
                                  children: [
                                    const Icon(Icons.emoji_events, size: 28),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        controller.getDailyAchievementMessage(),
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalsSummaryCard(BuildContext context, DailyLogController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Goals Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.getGoalsSummary(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                '${controller.getGoalsMetCount()}/5',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsGrid(BuildContext context, DailyLogController controller) {
    final goals = [
      {'key': 'calories', 'label': 'Calories', 'icon': Icons.restaurant},
      {'key': 'protein', 'label': 'Protein', 'icon': Icons.egg_alt},
      {'key': 'water', 'label': 'Hydration', 'icon': Icons.water_drop},
      {'key': 'workout', 'label': 'Workout', 'icon': Icons.fitness_center},
      {'key': 'calories_burned', 'label': 'Burned', 'icon': Icons.local_fire_department},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.8,
      ),
      itemCount: goals.length,
      itemBuilder: (context, i) {
        final goal = goals[i];
        final isMet = controller.isGoalMet(goal['key'] as String);
        return Card(
          color: isMet
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.sm),
            child: Row(
              children: [
                Icon(
                  goal['icon'] as IconData,
                  color: isMet
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        goal['label'] as String,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        isMet ? '✅ Done' : '⏳ Pending',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodSection(BuildContext context, DailyLogController controller) {
    final moods = AppConstants.moods;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Mood',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: moods.map((m) {
                final isSelected = controller.mood.value == m;
                return GestureDetector(
                  onTap: () => controller.updateMood(m),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Text(
                          m == 'happy' ? '😊' : m == 'neutral' ? '😐' : '😔',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m[0].toUpperCase() + m.substring(1),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, DailyLogController controller) {
    final notesController = TextEditingController(text: controller.notes.value);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: controller.getNotesPlaceholder(),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (value) => controller.updateNotes(value),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: () => controller.updateNotes(notesController.text),
                child: const Text('Save Notes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
