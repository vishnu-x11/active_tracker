import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/core_providers.dart';
import '../core/theme/app_palette.dart';
import '../core/widgets/buttons.dart';
import '../features/activity/activity_routes.dart';
import '../features/auth/auth_routes.dart';
import '../features/gym/gym_routes.dart';
import '../features/hydration/hydration_routes.dart';
import '../features/progress/progress_routes.dart';
import '../features/protein/protein_routes.dart';
import '../features/reminders/reminders_routes.dart';
import '../features/running/running_routes.dart';
import '../features/home/home_routes.dart';
import '../features/profile/presentation/notifiers/profile_notifier.dart';
import '../features/profile/profile_routes.dart';
import 'log_sheet.dart';
import 'session_redirect.dart';
import 'shell.dart';
import 'sign_out_button.dart';
import 'splash_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(currentUidProvider, (_, _) => refresh.value++);
  ref.listen(profileProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => sessionRedirect(
      sessionStatus(uid: ref.read(currentUidProvider), profile: ref.read(profileProvider)),
      state.matchedLocation,
    ),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashPage()),
      ...AuthRoutes.routes,
      ...ProfileRoutes.routes(onboardingAction: const SignOutButton()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [HomeRoutes.route]),
          StatefulShellBranch(routes: [ActivityRoutes.route]),
          StatefulShellBranch(
            routes: [
              ProgressRoutes.tab(
                rootNavigatorKey,
                actions: [
                  Builder(
                    builder: (context) => GlassIconButton(
                      icon: Icons.accessibility_new_rounded,
                      tooltip: 'Muscle recovery',
                      onPressed: () => context.push(GymRoutes.recovery),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              ProfileRoutes.tab(
                accountRows: [
                  Builder(
                    builder: (context) => ProfileAccountRow(
                      icon: Icons.notifications_none_rounded,
                      title: 'Reminders',
                      onTap: () => context.push(ReminderRoutes.reminders),
                    ),
                  ),
                  Builder(
                    builder: (context) => ProfileAccountRow(
                      icon: Icons.logout_rounded,
                      title: 'Sign out',
                      danger: true,
                      onTap: () => signOut(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.log,
        pageBuilder: (context, state) => LogSheetPage(key: state.pageKey, options: logOptions),
      ),
      ...GymRoutes.routes,
      ...RunRoutes.routes(),
      ...HydrationRoutes.routes,
      ProteinRoutes.route,
      ReminderRoutes.route,
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

final List<LogOption> logOptions = [
  (
    title: 'Gym session',
    hint: 'Time + muscle groups',
    icon: Icons.fitness_center_rounded,
    colors: Metric.burn,
    route: GymRoutes.newSession,
    live: false,
  ),
  (
    title: 'Run',
    hint: 'Distance, time, pace',
    icon: Icons.directions_run_rounded,
    colors: Metric.run,
    route: RunRoutes.newRun,
    live: false,
  ),
  (
    title: 'Water',
    hint: 'Quick add ml',
    icon: Icons.water_drop_rounded,
    colors: Metric.water,
    route: HydrationRoutes.water,
    live: false,
  ),
  (
    title: 'Protein',
    hint: 'Grams or foods',
    icon: Icons.egg_alt_rounded,
    colors: Metric.protein,
    route: ProteinRoutes.protein,
    live: false,
  ),
  (
    title: 'Record run with GPS',
    hint: 'Live distance, pace and route',
    icon: Icons.my_location_rounded,
    colors: Metric.protein,
    route: RunRoutes.record,
    live: true,
  ),
];
