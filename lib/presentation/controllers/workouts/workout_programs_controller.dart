import 'package:get/get.dart';

class WorkoutProgram {
  final int id;
  final String title;
  final String description;
  final String level;
  final int durationWeeks;
  final String category;

  WorkoutProgram({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.durationWeeks,
    required this.category,
  });
}

class WorkoutProgramsController extends GetxController {
  final isLoading = false.obs;
  final programs = <WorkoutProgram>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchPrograms();
  }

  Future<void> fetchPrograms() async {
    try {
      isLoading.value = true;
      // In a real app, we'd fetch from DB. For v4.0 MVP, we'll provide smart defaults.
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate DB fetch
      
      programs.value = [
        WorkoutProgram(
          id: 1,
          title: 'Weight Loss Accelerator',
          description: 'High-intensity interval training designed for maximum fat burn.',
          level: 'Beginner',
          durationWeeks: 4,
          category: 'Weight Loss',
        ),
        WorkoutProgram(
          id: 2,
          title: 'Muscle Mass Builder',
          description: 'Focus on progressive overload and heavy compound movements.',
          level: 'Intermediate',
          durationWeeks: 8,
          category: 'Hypertrophy',
        ),
        WorkoutProgram(
          id: 3,
          title: 'Total Body Toning',
          description: 'Light weights and high reps for lean muscle definition.',
          level: 'All Levels',
          durationWeeks: 6,
          category: 'Toning',
        ),
        WorkoutProgram(
          id: 4,
          title: 'Pro Athlete Strength',
          description: 'Advanced strength and conditioning for peak performance.',
          level: 'Advanced',
          durationWeeks: 12,
          category: 'Strength',
        ),
      ];
    } catch (e) {
      print('❌ Error fetching workout programs: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
