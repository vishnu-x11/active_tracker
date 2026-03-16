import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:active_tracker/presentation/controllers/daily_log_controller.dart';
import 'package:active_tracker/config/constants.dart';
import 'package:active_tracker/presentation/widgets/date_navigator.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DailyLogController>(
      tag: 'daily_log',
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notes'),
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

                    final notesCtrl = TextEditingController(text: controller.notes.value);

                    return Padding(
                      padding: const EdgeInsets.all(AppPadding.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Info row
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Last updated: ${controller.getLastUpdateTime()}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Notes TextField
                          Expanded(
                            child: TextField(
                              controller: notesCtrl,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: InputDecoration(
                                hintText: controller.getNotesPlaceholder(),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.all(AppPadding.md),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Save Button
                          FilledButton.icon(
                            onPressed: () {
                              controller.updateNotes(notesCtrl.text);
                              Get.snackbar(
                                'Saved',
                                'Your notes have been saved',
                                snackPosition: SnackPosition.BOTTOM,
                                duration: const Duration(seconds: 2),
                              );
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Save Notes'),
                          ),
                        ],
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
}
