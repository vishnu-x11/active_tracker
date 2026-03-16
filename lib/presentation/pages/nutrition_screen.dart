import 'package:active_tracker/presentation/widgets/date_navigator.dart';
import 'package:active_tracker/presentation/widgets/empty_state.dart';
import 'package:active_tracker/presentation/widgets/error_alert.dart';
import 'package:active_tracker/presentation/widgets/log_entry.dart';
import 'package:active_tracker/presentation/widgets/stats_row.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:active_tracker/presentation/controllers/nutrition_controller.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NutritionController>(
      tag: 'nutrition',
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Nutrition'),
            elevation: 0,
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Date Navigator
                DateNavigator(
                  selectedDate: controller.selectedDate.value,
                  onPrevious: controller.previousDay,
                  onNext: controller.nextDay,
                  onToday: controller.goToday,
                ),

                Expanded(
                  child: Obx(() {
                    // Loading state
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Error state
                    if (controller.errorMessage.value.isNotEmpty) {
                      return ErrorAlert(message: controller.errorMessage.value);
                    }

                    // Empty state
                    if (controller.foodLogs.isEmpty) {
                      return EmptyState(
                        icon: Icons.fastfood,
                        message: 'No food logs',
                        subMessage: 'Tap the + button to add your first meal',
                      );
                    }

                    // Content
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Totals Card
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Daily Totals',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    StatsRow(
                                      label1: 'Calories',
                                      value1: '${controller.totalCalories.value.toStringAsFixed(0)} kcal',
                                      label2: 'Protein',
                                      value2: '${controller.totalProtein.value.toStringAsFixed(0)}g',
                                    ),
                                    const SizedBox(height: 16),
                                    StatsRow(
                                      label1: 'Fat',
                                      value1: '${controller.totalFat.value.toStringAsFixed(0)}g',
                                      label2: 'Carbs',
                                      value2: '${controller.totalCarbs.value.toStringAsFixed(0)}g',
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Food Logs
                            Text(
                              'Food Logs',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),

                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: controller.foodLogs.length,
                              itemBuilder: (context, index) {
                                final log = controller.foodLogs[index];
                                return LogEntry(
                                  icon: Icons.fastfood,
                                  title: log.foodName,
                                  subtitle: '${log.calories} kcal | P: ${log.protein}g',
                                  onDelete: () => controller.deleteFoodLog(log.id!),
                                );
                              },
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
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddFoodDialog(context, controller),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showAddFoodDialog(BuildContext context, NutritionController controller) {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final fatController = TextEditingController();
    final carbsController = TextEditingController();

    // Add listener for search
    nameController.addListener(() {
      controller.searchFood(nameController.text.trim());
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Food Log'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Food name',
                  suffixIcon: Icon(Icons.search),
                ),
              ),
              
              // Suggestions List
              Obx(() {
                if (controller.foodSuggestions.isEmpty) return const SizedBox.shrink();
                
                return Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.foodSuggestions.length,
                    itemBuilder: (context, index) {
                      final item = controller.foodSuggestions[index];
                      return ListTile(
                        dense: true,
                        title: Text(item.name),
                        subtitle: Text('${item.calories} kcal | P: ${item.protein}g'),
                        onTap: () {
                          // Auto-fill fields
                          nameController.text = item.name;
                          caloriesController.text = item.calories.toString();
                          proteinController.text = item.protein.toString();
                          fatController.text = item.fat.toString();
                          carbsController.text = item.carbs.toString();
                          
                          // Clear suggestions
                          controller.clearSuggestions();
                        },
                      );
                    },
                  ),
                );
              }),
              
              const Divider(),
              
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Calories'),
              ),
              TextField(
                controller: proteinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Protein (g)'),
              ),
              TextField(
                controller: fatController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Fat (g)'),
              ),
              TextField(
                controller: carbsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Carbs (g)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.clearSuggestions();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.addFoodLog(
                foodName: nameController.text,
                calories: double.tryParse(caloriesController.text) ?? 0,
                protein: double.tryParse(proteinController.text) ?? 0,
                fat: double.tryParse(fatController.text) ?? 0,
                carbs: double.tryParse(carbsController.text) ?? 0,
                quantity: 1,
              );
              controller.clearSuggestions();
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}