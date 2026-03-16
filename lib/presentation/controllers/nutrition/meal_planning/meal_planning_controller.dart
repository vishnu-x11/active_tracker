import 'package:get/get.dart';

class MealRecipe {
  final int id;
  final String title;
  final String description;
  final int calories;
  final int protein;
  final String category;
  final String time;

  MealRecipe({
    required this.id,
    required this.title,
    required this.description,
    required this.calories,
    required this.protein,
    required this.category,
    required this.time,
  });
}

class MealPlanningController extends GetxController {
  final isLoading = false.obs;
  final recipes = <MealRecipe>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchRecipes();
  }

  Future<void> fetchRecipes() async {
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 800));
      
      recipes.value = [
        MealRecipe(
          id: 1,
          title: 'Quinoa & Avocado Bowl',
          description: 'A nutrient-dense bowl perfect for post-workout recovery.',
          calories: 450,
          protein: 15,
          category: 'Vegetarian',
          time: '15 min',
        ),
        MealRecipe(
          id: 2,
          title: 'Grilled Salmon with Asparagus',
          description: 'Rich in Omega-3 and high-quality protein.',
          calories: 380,
          protein: 35,
          category: 'Pescatarian',
          time: '25 min',
        ),
        MealRecipe(
          id: 3,
          title: 'Lemon Herb Chicken Breast',
          description: 'Lean protein meal for muscle building and maintenance.',
          calories: 320,
          protein: 42,
          category: 'High Protein',
          time: '20 min',
        ),
        MealRecipe(
          id: 4,
          title: 'Protein-Packed Greek Yogurt',
          description: 'Quick breakfast or snack with honey and nuts.',
          calories: 220,
          protein: 18,
          category: 'Breakfast',
          time: '5 min',
        ),
      ];
    } catch (e) {
      print('❌ Error fetching recipes: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
