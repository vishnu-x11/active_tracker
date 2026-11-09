import 'package:go_router/go_router.dart';

import 'presentation/screens/reminders_screen.dart';

abstract final class ReminderRoutes {
  static const reminders = '/reminders';

  static final route = GoRoute(path: reminders, builder: (context, state) => const RemindersScreen());
}
