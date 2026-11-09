import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/gym_detail_screen.dart';
import 'presentation/screens/gym_log_screen.dart';
import 'presentation/screens/recovery_screen.dart';

abstract final class GymRoutes {
  static const newSession = '/gym/new';
  static const recovery = '/gym/recovery';
  static String detail(String id) => '/gym/$id';
  static String edit(String id) => '/gym/$id/edit';

  static final routes = <RouteBase>[
    GoRoute(
      path: newSession,
      pageBuilder: (context, state) => const MaterialPage(fullscreenDialog: true, child: GymLogScreen()),
    ),
    GoRoute(path: recovery, builder: (context, state) => const RecoveryScreen()),
    GoRoute(
      path: '/gym/:id',
      builder: (context, state) => GymDetailScreen(id: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'edit',
          pageBuilder: (context, state) =>
              MaterialPage(fullscreenDialog: true, child: GymLogScreen(id: state.pathParameters['id'])),
        ),
      ],
    ),
  ];
}
