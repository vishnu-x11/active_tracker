import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:active_tracker/presentation/controllers/onboarding_controller.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OnboardingController>(
      tag: 'onboarding',
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: Obx(() => Text('Step ${controller.currentStep.value + 1}/6')),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress bar
                  Obx(() => LinearProgressIndicator(
                    value: (controller.currentStep.value + 1) / 6,
                    minHeight: 8,
                  )),
                  const SizedBox(height: 32),

                  // Dynamic form based on step
                  Obx(() {
                    switch (controller.currentStep.value) {
                      case 0:
                        return _buildNameStep(controller, context);
                      case 1:
                        return _buildAgeStep(controller, context);
                      case 2:
                        return _buildWeightStep(controller, context);
                      case 3:
                        return _buildHeightStep(controller, context);
                      case 4:
                        return _buildGoalStep(controller, context);
                      case 5:
                        return _buildBurnedCaloriesStep(controller, context);
                      default:
                        return const SizedBox.shrink();
                    }
                  }),

                  const SizedBox(height: 40),

                  // Navigation buttons
                  Obx(() => Row(
                    children: [
                      if (controller.currentStep.value > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: controller.previousStep,
                            child: const Text('Back'),
                          ),
                        ),
                      if (controller.currentStep.value > 0)
                        const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: controller.isLoading.value ? null : (
                              controller.currentStep.value == 5
                                  ? controller.completeOnboarding
                                  : controller.nextStep
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  controller.currentStep.value == 5 ? 'Finish' : 'Next',
                                ),
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNameStep(OnboardingController controller, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What's your name?",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('name'),
          initialValue: controller.userName.value,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) => controller.userName.value = value,
        ),
      ],
    );
  }

  Widget _buildAgeStep(OnboardingController controller, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "How old are you?",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('age'),
          initialValue: controller.userAge.value == 0 ? '' : controller.userAge.value.toString(),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter your age',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            controller.userAge.value = int.tryParse(value) ?? 0;
          },
        ),
      ],
    );
  }

  Widget _buildWeightStep(OnboardingController controller, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What's your weight? (kg)",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('weight'),
          initialValue: controller.userWeight.value == 0.0 ? '' : controller.userWeight.value.toString(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Enter weight in kg',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            controller.userWeight.value = double.tryParse(value) ?? 0.0;
          },
        ),
      ],
    );
  }

  Widget _buildHeightStep(OnboardingController controller, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What's your height? (cm)",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('height'),
          initialValue: controller.userHeight.value == 0.0 ? '' : controller.userHeight.value.toString(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Enter height in cm',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            controller.userHeight.value = double.tryParse(value) ?? 0.0;
          },
        ),
      ],
    );
  }

  Widget _buildGoalStep(OnboardingController controller, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What's your fitness goal?",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Obx(() => Column(
          children: [
            _goalOption(
              context,
              'Weight Loss',
              1,
              controller.goalType.value,
                  () => controller.goalType.value = 1,
            ),
            _goalOption(
              context,
              'Muscle Gain',
              2,
              controller.goalType.value,
                  () => controller.goalType.value = 2,
            ),
            _goalOption(
              context,
              'Stay Fit',
              3,
              controller.goalType.value,
                  () => controller.goalType.value = 3,
            ),
            _goalOption(
              context,
              'Health & Wellness',
              4,
              controller.goalType.value,
                  () => controller.goalType.value = 4,
            ),
          ],
        )),
      ],
    );
  }

  Widget _goalOption(
      BuildContext context,
      String label,
      int value,
      int groupValue,
      VoidCallback onTap,
      ) {
    final bool isSelected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              // ignore: deprecated_member_use
              Radio<int>(
                value: value,
                // ignore: deprecated_member_use
                groupValue: groupValue,
                // ignore: deprecated_member_use
                onChanged: (_) => onTap(),
              ),
              const SizedBox(width: 16),
              Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBurnedCaloriesStep(OnboardingController controller, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Set your daily workout goal",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          "How many calories do you want to burn daily?",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        TextFormField(
          key: const ValueKey('burnedCalories'),
          initialValue: controller.burnedCalorieGoal.value.toStringAsFixed(0),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'e.g. 500',
            suffixText: 'kcal',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            controller.burnedCalorieGoal.value = double.tryParse(value) ?? 500.0;
          },
        ),
        const SizedBox(height: 32),
        // Add a visual indicator as requested
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.local_fire_department, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Target",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Obx(() => Text(
                      "${controller.burnedCalorieGoal.value.toStringAsFixed(0)} kcal per day",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}