import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:active_tracker/presentation/controllers/hydration_controller.dart';
import 'package:active_tracker/config/constants.dart';
import 'package:active_tracker/presentation/widgets/date_navigator.dart';

class HydrationScreen extends StatelessWidget {
  const HydrationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HydrationController>(
      tag: 'hydration',
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Hydration'),
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
                DateNavigator(
                  selectedDate: controller.selectedDate.value,
                  onPrevious: controller.previousDay,
                  onNext: controller.nextDay,
                  onToday: controller.goToday,
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return RefreshIndicator(
                      onRefresh: controller.loadHydrationData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppPadding.md),
                        child: Column(
                          children: [
                            // Progress Circle
                            _buildProgressCircle(context, controller),
                            const SizedBox(height: 24),

                            // Motivational Message
                            Text(
                              controller.getMotivationalMessage(),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 24),

                            // Quick Log Buttons
                            Text(
                              'Quick Log',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildQuickLogButton(context, '🥃 Glass\n250 ml', () => controller.logQuickWater('glass')),
                                const SizedBox(width: 8),
                                _buildQuickLogButton(context, '🍶 Bottle\n500 ml', () => controller.logQuickWater('bottle')),
                                const SizedBox(width: 8),
                                _buildQuickLogButton(context, '🪣 Liter\n1000 ml', () => controller.logQuickWater('liter')),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Custom Amount
                            _buildCustomAmountCard(context, controller),
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

  Widget _buildProgressCircle(BuildContext context, HydrationController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.lg),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: controller.waterProgress.value,
                    strokeWidth: 12,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      controller.isGoalMet()
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.water_drop, size: 32, color: Colors.blue),
                    const SizedBox(height: 4),
                    Text(
                      controller.getWaterLoggedString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'of ${controller.getWaterGoalString()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              controller.getRemainingWaterString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              controller.getGlassesProgressString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLogButton(BuildContext context, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppPadding.md),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAmountCard(BuildContext context, HydrationController controller) {
    final customCtrl = TextEditingController();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custom Amount',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: customCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (ml)',
                      border: OutlineInputBorder(),
                      suffixText: 'ml',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () {
                    final ml = double.tryParse(customCtrl.text);
                    if (ml != null && ml > 0) {
                      controller.logWater(ml);
                      customCtrl.clear();
                    }
                  },
                  child: const Text('Log'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
