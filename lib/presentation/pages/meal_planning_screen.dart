import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/nutrition/meal_planning/meal_planning_controller.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

class MealPlanningScreen extends GetView<MealPlanningController> {
  const MealPlanningScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intelligent Meal Planning'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppPadding.md),
          itemCount: controller.recipes.length,
          itemBuilder: (context, index) {
            final recipe = controller.recipes[index];
            return _buildRecipeCard(context, recipe);
          },
        );
      }),
    );
  }

  Widget _buildRecipeCard(BuildContext context, MealRecipe recipe) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppPadding.md),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppTheme.white.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () {
          Get.snackbar('Recipe Details', 'Detail view for ${recipe.title} will be available in the next update.');
        },
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.md),
          child: Row(
            children: [
              // Image / Category Icon
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.restaurant, color: AppTheme.primary, size: 32),
              ),
              const SizedBox(width: AppPadding.md),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.category,
                      style: const TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.white),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(recipe.time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(width: 12),
                        const Icon(Icons.local_fire_department_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${recipe.calories} kcal', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
