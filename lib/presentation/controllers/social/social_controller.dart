import 'package:get/get.dart';

class Friend {
  final String name;
  final String avatar;
  final int streak;
  final bool isOnline;

  Friend({required this.name, required this.avatar, required this.streak, this.isOnline = false});
}

class CommunityChallenge {
  final String title;
  final String description;
  final int participants;
  final double progress;

  CommunityChallenge({required this.title, required this.description, required this.participants, required this.progress});
}

class SocialController extends GetxController {
  final friends = <Friend>[].obs;
  final challenges = <CommunityChallenge>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSocialData();
  }

  void loadSocialData() {
    friends.value = [
      Friend(name: 'Alex Johnson', avatar: 'AJ', streak: 12, isOnline: true),
      Friend(name: 'Sarah Miller', avatar: 'SM', streak: 5, isOnline: false),
      Friend(name: 'Mike Ross', avatar: 'MR', streak: 21, isOnline: true),
    ];

    challenges.value = [
      CommunityChallenge(
        title: '30-Day Step Challenge',
        description: 'Complete 10k steps every day for 30 days.',
        participants: 1250,
        progress: 0.45,
      ),
      CommunityChallenge(
        title: 'Hydration Sprint',
        description: 'Drink 3L water daily for a week.',
        participants: 850,
        progress: 0.8,
      ),
    ];
  }
}
