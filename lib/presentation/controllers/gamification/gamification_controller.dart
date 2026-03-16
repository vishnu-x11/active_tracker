import 'package:get/get.dart';

class Badge {
  final String title;
  final String icon;
  final bool isUnlocked;

  Badge({required this.title, required this.icon, this.isUnlocked = false});
}

class GamificationController extends GetxController {
  final currentStreak = 5.obs;
  final totalBadges = 12.obs;
  final unlockedBadgesCount = 4.obs;
  
  final badges = <Badge>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadBadges();
  }

  void loadBadges() {
    badges.value = [
      Badge(title: 'Early Bird', icon: '🌅', isUnlocked: true),
      Badge(title: 'Hydration Hero', icon: '💧', isUnlocked: true),
      Badge(title: 'Gym Rat', icon: '💪', isUnlocked: true),
      Badge(title: 'Meal Master', icon: '🍲', isUnlocked: true),
      Badge(title: 'Century Club', icon: '💯', isUnlocked: false),
      Badge(title: 'Iron Man', icon: '⛓️', isUnlocked: false),
    ];
  }
}
