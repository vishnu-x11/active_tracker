import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:active_tracker/presentation/controllers/bmi_controller.dart';
import 'package:active_tracker/config/constants.dart';

class BmiScreen extends StatelessWidget {
  const BmiScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BmiController>(
      tag: 'bmi',
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('BMI & Weight'),
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
                    // Error
                    if (controller.errorMessage.value.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          controller.errorMessage.value,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),

                    // BMI Summary Card
                    _buildBmiCard(context, controller),
                    const SizedBox(height: 16),

                    // Ideal Weight Range
                    _buildIdealWeightCard(context, controller),
                    const SizedBox(height: 16),

                    // BMI Calculator
                    _buildCalculatorCard(context, controller),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildBmiCard(BuildContext context, BmiController controller) {
    final hasBmi = controller.bmi.value > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.lg),
        child: Column(
          children: [
            Text(
              hasBmi ? controller.getBmiString() : '--',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'BMI',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            if (hasBmi) ...[
              Chip(
                label: Text(
                  '${controller.getBmiEmoji()} ${controller.bmiCategory.value}',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                controller.getBmiRange(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                controller.getBmiInterpretation(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ] else
              Text(
                'Calculate your BMI below',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMeasurementTile(context, 'Weight', controller.getWeightString(), Icons.scale),
                const SizedBox(width: 24),
                _buildMeasurementTile(context, 'Height', controller.getHeightString(), Icons.straighten),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementTile(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _buildIdealWeightCard(BuildContext context, BmiController controller) {
    final range = controller.getIdealWeightRange();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ideal Weight Range',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${range['min']?.toStringAsFixed(1)} kg — ${range['max']?.toStringAsFixed(1)} kg',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              controller.getProgressToIdealWeight(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorCard(BuildContext context, BmiController controller) {
    final weightCtrl = TextEditingController(
      text: controller.weight.value > 0 ? controller.weight.value.toString() : '',
    );
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
              'Calculate BMI',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
                suffixText: 'kg',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: heightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Height (m)',
                border: OutlineInputBorder(),
                suffixText: 'm',
                helperText: 'e.g. 1.75 for 175 cm',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  final w = double.tryParse(weightCtrl.text);
                  final h = double.tryParse(heightCtrl.text);
                  if (w != null && h != null && w > 0 && h > 0) {
                    controller.calculateBmi(newWeight: w, newHeight: h);
                  } else {
                    Get.snackbar('Invalid Input', 'Please enter valid weight and height values.');
                  }
                },
                icon: const Icon(Icons.calculate),
                label: const Text('Calculate & Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
