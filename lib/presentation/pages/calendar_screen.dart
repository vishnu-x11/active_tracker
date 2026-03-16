import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:active_tracker/presentation/controllers/daily_log_controller.dart';
import 'package:active_tracker/config/constants.dart';
import 'package:active_tracker/utils/date_utils.dart' as dateUtil;

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DailyLogController>(
      tag: 'daily_log',
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Calendar'),
            elevation: 0,
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Calendar
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: _calendarFormat,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                  ),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    controller.selectedDate.value = selectedDay;
                  },
                  onFormatChanged: (format) {
                    setState(() => _calendarFormat = format);
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
                const Divider(height: 1),

                // Selected day summary
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final selectedDateStr = dateUtil.DateUtils.getDateKey(date: _selectedDay);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(AppPadding.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateUtil.DateUtils.formatDateKey(selectedDateStr),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),

                          if (!controller.isDailyLogCreated())
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.event_note, size: 48),
                                    SizedBox(height: 8),
                                    Text('No data for this day'),
                                  ],
                                ),
                              ),
                            )
                          else ...[
                            // Goals met summary
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(AppPadding.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Goals: ${controller.getGoalsMetString()}',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(controller.getGoalsSummary()),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Mood
                            if (controller.mood.value.isNotEmpty)
                              Card(
                                child: ListTile(
                                  leading: const Icon(Icons.mood),
                                  title: const Text('Mood'),
                                  trailing: Text(
                                    '${controller.getMoodEmoji()} ${controller.mood.value}',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ),

                            // Notes preview
                            if (controller.notes.value.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppPadding.md),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.notes, size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Notes',
                                            style: Theme.of(context).textTheme.labelMedium,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(controller.notes.value),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
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
