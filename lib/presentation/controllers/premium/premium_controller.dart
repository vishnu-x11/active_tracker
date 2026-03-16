import 'package:get/get.dart';
import 'package:active_tracker/data/local/hive_manager.dart';

class PremiumController extends GetxController {
  final isPremium = false.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkPremiumStatus();
  }

  void checkPremiumStatus() {
    final box = HiveManager.getPremiumSettingsBox();
    isPremium.value = box.get('is_premium', defaultValue: false);
  }

  Future<void> upgradeToPremium() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 2)); // Simulate payment
    
    final box = HiveManager.getPremiumSettingsBox();
    await box.put('is_premium', true);
    isPremium.value = true;
    
    Get.snackbar(
      'Success!',
      'Welcome to Active Health PRO. All features are now unlocked.',
      snackPosition: SnackPosition.BOTTOM,
    );
    isLoading.value = false;
  }
}
