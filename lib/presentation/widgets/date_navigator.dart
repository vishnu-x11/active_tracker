
import 'package:active_tracker/utils/date_utils.dart';
import 'package:flutter/material.dart' hide DateUtils;

class DateNavigator extends StatelessWidget {
  const DateNavigator({super.key,
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final dateKey = DateUtils.getDateKey(date: selectedDate);
    final formattedDate = DateUtils.formatDateKey(dateKey);
    final isToday = DateUtils.isToday(dateKey);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
            tooltip: 'Previous day',
          ),

          // Date display with today button
          GestureDetector(
            onTap: isToday ? null : onToday,
            child: Column(
              children: [
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (!isToday)
                  Text(
                    'Tap for today',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),

          // Next button
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
            tooltip: 'Next day',
          ),
        ],
      ),
    );
  }
}