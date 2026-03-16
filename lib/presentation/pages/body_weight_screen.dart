import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:active_tracker/presentation/controllers/bmi_controller.dart';
import 'package:active_tracker/config/constants.dart';

class BodyWeightScreen extends StatelessWidget {
  const BodyWeightScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BmiController>(
      tag: 'bmi',
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Body Weight Log'),
            elevation: 0,
          ),
          body: SafeArea(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppPadding.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Weight Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppPadding.lg),
                        child: Row(
                          children: [
                            const Icon(Icons.scale, size: 40),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Weight',
                                  style: Theme.of(context).textTheme.labelMedium,
                                ),
                                Text(
                                  controller.weight.value > 0
                                      ? controller.getWeightString()
                                      : '-- kg',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Change',
                                  style: Theme.of(context).textTheme.labelMedium,
                                ),
                                Text(
                                  controller.getWeightChangeString(),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Log Weight Card
                    _buildLogWeightCard(context, controller),
                    const SizedBox(height: 16),

                    // History
                    Text(
                      'Weight History',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (controller.weightHistory.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.show_chart, size: 48),
                              SizedBox(height: 8),
                              Text('No weight history yet'),
                              Text('Log your weight to start tracking'),
                            ],
                          ),
                        ),
                      )
                    else
                      ...controller.weightHistory.map(
                        (log) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.circle, size: 12),
                            title: Text('${log.weight.toStringAsFixed(1)} kg'),
                            subtitle: Text(log.dateKey),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildLogWeightCard(BuildContext context, BmiController controller) {
    final weightCtrl = TextEditingController();
    final heightCtrl = TextEditingController(
      text: controller.height.value > 0 ? controller.height.value.toString() : '',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log Today\'s Weight',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
                suffixText: 'kg',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: heightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Height (m)',
                border: OutlineInputBorder(),
                suffixText: 'm',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final w = double.tryParse(weightCtrl.text);
                  final h = double.tryParse(heightCtrl.text);
                  if (w != null && h != null && w > 0 && h > 0) {
                    controller.calculateBmi(newWeight: w, newHeight: h);
                    Get.back();
                  } else {
                    Get.snackbar('Invalid Input', 'Please enter valid weight and height.');
                  }
                },
                child: const Text('Save Weight'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
