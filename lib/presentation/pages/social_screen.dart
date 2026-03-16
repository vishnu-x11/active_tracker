import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/social/social_controller.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

class SocialScreen extends GetView<SocialController> {
  const SocialScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Friends'),
              Tab(text: 'Challenges'),
            ],
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
          ),
        ),
        body: TabBarView(
          children: [
            _buildFriendsTab(),
            _buildChallengesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsTab() {
    return Obx(() => ListView.builder(
      padding: const EdgeInsets.all(AppPadding.md),
      itemCount: controller.friends.length,
      itemBuilder: (context, index) {
        final friend = controller.friends[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primary.withOpacity(0.2),
            child: Text(friend.avatar, style: const TextStyle(color: AppTheme.primary)),
          ),
          title: Text(friend.name, style: const TextStyle(color: AppTheme.white)),
          subtitle: Text('${friend.streak} Day Streak', style: const TextStyle(color: AppTheme.warning)),
          trailing: Icon(
            Icons.circle,
            size: 12,
            color: friend.isOnline ? AppTheme.success : Colors.grey,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          tileColor: AppTheme.white.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ).marginOnly(bottom: 8);
      },
    ));
  }

  Widget _buildChallengesTab() {
    return Obx(() => ListView.builder(
      padding: const EdgeInsets.all(AppPadding.md),
      itemCount: controller.challenges.length,
      itemBuilder: (context, index) {
        final challenge = controller.challenges[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(challenge.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.white)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text('${challenge.participants} in', style: const TextStyle(color: AppTheme.primary, fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(challenge.description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: challenge.progress,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('JOIN CHALLENGE'),
                  ),
                ),
              ],
            ),
          ).marginOnly(bottom: 8),
        );
      },
    ));
  }
}
