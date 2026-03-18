import 'package:active_tracker/data/models/sqlite/food_log.dart';
import 'package:active_tracker/presentation/widgets/date_navigator.dart';
import 'package:active_tracker/presentation/widgets/error_alert.dart';
import 'package:active_tracker/presentation/widgets/log_entry.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:get/get.dart';
import 'package:active_tracker/presentation/controllers/nutrition_controller.dart';
import 'package:active_tracker/presentation/controllers/auth_controller.dart';
import 'package:active_tracker/config/theme.dart';
import 'package:active_tracker/config/constants.dart';
import 'package:active_tracker/utils/date_utils.dart';

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

                    if (controller.errorMessage.value.isNotEmpty) {
                      return ErrorAlert(message: controller.errorMessage.value);
                    }

                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryCard(context, controller),
                            const SizedBox(height: 24),
                            _buildMealSection(context, controller, 'Breakfast', Icons.wb_sunny_outlined),
                            _buildMealSection(context, controller, 'Lunch', Icons.light_mode_outlined),
                            _buildMealSection(context, controller, 'Dinner', Icons.nights_stay_outlined),
                            _buildMealSection(context, controller, 'Snack', Icons.apple_outlined),
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

  Widget _buildSummaryCard(BuildContext context, NutritionController controller) {
    return Card(
      elevation: 0,
      color: AppTheme.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppTheme.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTotalStat('Calories', '${controller.totalCalories.value.toStringAsFixed(0)}', 'kcal'),
                _buildTotalStat('Protein', '${controller.totalProtein.value.toStringAsFixed(0)}', 'g'),
                _buildTotalStat('Carbs', '${controller.totalCarbs.value.toStringAsFixed(0)}', 'g'),
                _buildTotalStat('Fat', '${controller.totalFat.value.toStringAsFixed(0)}', 'g'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalStat(String label, String value, String unit) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.white)),
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.white.withOpacity(0.5))),
      ],
    );
  }

  Widget _buildMealSection(BuildContext context, NutritionController controller, String mealName, IconData icon) {
    final logs = controller.groupedLogs[mealName] ?? [];
    double mealCalories = logs.fold(0, (sum, log) => sum + log.calories);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(mealName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              children: [
                Text('${mealCalories.toStringAsFixed(0)} kcal', style: TextStyle(color: AppTheme.white.withOpacity(0.6))),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                  onPressed: () => _showAddFoodDialog(context, controller, mealType: mealName),
                ),
              ],
            ),
          ],
        ),
        if (logs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('No $mealName logged', style: TextStyle(color: AppTheme.white.withOpacity(0.3), fontSize: 14)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return LogEntry(
                icon: Icons.fastfood_outlined,
                title: log.foodName,
                subtitle: '${log.quantity.toStringAsFixed(0)}${log.unit ?? 'g'} | ${log.calories.toStringAsFixed(0)} kcal',
                onEdit: () => _showAddFoodDialog(context, controller, foodLog: log, mealType: mealName),
                onDelete: () => controller.deleteFoodLog(log.id!),
              );
            },
          ),
        const Divider(height: 32),
      ],
    );
  }

  void _showAddFoodDialog(BuildContext context, NutritionController controller, {FoodLog? foodLog, String mealType = 'Breakfast'}) {
    final nameController = TextEditingController(text: foodLog?.foodName ?? '');
    final caloriesController = TextEditingController(text: foodLog?.calories.toString() ?? '');
    final proteinController = TextEditingController(text: foodLog?.protein.toString() ?? '');
    final fatController = TextEditingController(text: foodLog?.fat.toString() ?? '');
    final carbsController = TextEditingController(text: foodLog?.carbs.toString() ?? '');
    final weightController = TextEditingController(text: foodLog?.quantity.toString() ?? '100');
    final RxString selectedMealType = (foodLog?.mealType ?? mealType).obs;

    // Base values for calculation (per 100g/unit)
    double baseCal = (foodLog != null && foodLog.quantity > 0) ? foodLog.calories / (foodLog.quantity / 100) : 0;
    double baseProt = (foodLog != null && foodLog.quantity > 0) ? foodLog.protein / (foodLog.quantity / 100) : 0;
    double baseFat = (foodLog != null && foodLog.quantity > 0) ? foodLog.fat / (foodLog.quantity / 100) : 0;
    double baseCarb = (foodLog != null && foodLog.quantity > 0) ? foodLog.carbs / (foodLog.quantity / 100) : 0;

    void updateCalcs() {
      final weight = double.tryParse(weightController.text) ?? 0;
      if (weight > 0) {
        caloriesController.text = (baseCal * (weight / 100)).toStringAsFixed(1);
        proteinController.text = (baseProt * (weight / 100)).toStringAsFixed(1);
        fatController.text = (baseFat * (weight / 100)).toStringAsFixed(1);
        carbsController.text = (baseCarb * (weight / 100)).toStringAsFixed(1);
      }
    }

    nameController.addListener(() {
      controller.searchFood(nameController.text.trim());
    });

    weightController.addListener(updateCalcs);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(foodLog == null ? 'Add Food' : 'Edit Log'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Search food...', suffixIcon: Icon(Icons.search)),
              ),
              
              Obx(() {
                if (controller.foodSuggestions.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: controller.foodSuggestions.map((item) => ListTile(
                    dense: true,
                    title: Text(item.name),
                    subtitle: Text('${item.calories} kcal | P: ${item.protein}g'),
                    onTap: () {
                      baseCal = item.calories;
                      baseProt = item.protein;
                      baseFat = item.fat;
                      baseCarb = item.carbs;
                      nameController.text = item.name;
                      updateCalcs();
                      controller.clearSuggestions();
                    },
                  )).toList(),
                );
              }),
              
              const SizedBox(height: 16),
              Obx(() => DropdownButtonFormField<String>(
                value: selectedMealType.value,
                decoration: const InputDecoration(labelText: 'Meal Type'),
                items: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (val) => selectedMealType.value = val!,
              )),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Weight (g)'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: caloriesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: proteinController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Protein'))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final log = FoodLog(
                id: foodLog?.id,
                userId: foodLog?.userId ?? Get.find<AuthController>().userId.value,
                dateKey: foodLog?.dateKey ?? DateUtils.getDateKey(date: controller.selectedDate.value),
                foodName: nameController.text,
                calories: double.tryParse(caloriesController.text) ?? 0,
                protein: double.tryParse(proteinController.text) ?? 0,
                fat: double.tryParse(fatController.text) ?? 0,
                carbs: double.tryParse(carbsController.text) ?? 0,
                quantity: double.tryParse(weightController.text) ?? 100,
                mealType: selectedMealType.value,
                unit: 'g',
                timestamp: foodLog?.timestamp ?? DateTime.now().millisecondsSinceEpoch,
                createdAt: foodLog?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
                updatedAt: DateTime.now().millisecondsSinceEpoch,
              );

              if (foodLog == null) {
                controller.addFoodLog(
                  foodName: log.foodName,
                  calories: log.calories,
                  protein: log.protein,
                  fat: log.fat,
                  carbs: log.carbs,
                  quantity: log.quantity,
                  mealType: log.mealType,
                  unit: 'g',
                );
              } else {
                controller.updateFoodLog(log);
              }
              Navigator.pop(context);
            },
            child: Text(foodLog == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }
}