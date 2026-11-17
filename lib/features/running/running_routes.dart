import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/run_detail_screen.dart';
import 'presentation/screens/predictions_screen.dart';
import 'presentation/screens/records_screen.dart';
import 'presentation/screens/run_log_screen.dart';
import 'presentation/screens/run_record_screen.dart';
import 'presentation/screens/run_replay_screen.dart';
import 'presentation/screens/workouts_screen.dart';
import 'presentation/screens/zone_settings_screen.dart';
import 'presentation/screens/zones_screen.dart';

abstract final class RunRoutes {
  static const newRun = '/run/new';
  static const record = '/run/record';
  static String detail(String id) => '/run/$id';

  static String justRecorded(String id) => '/run/$id?justRecorded=1';
  static String edit(String id) => '/run/$id/edit';
  static String replay(String id) => '/run/$id/replay';

  static String fromRecording(String draftId) => '/run/new?recording=$draftId';

  static const records = '/run/records';
  static const predictions = '/run/predictions';
  static const zones = '/run/zones';
  static const zoneSettings = '/run/zones/edit';
  static const workouts = '/run/workouts';

  static List<RouteBase> routes() => [
    GoRoute(
      path: record,
      pageBuilder: (context, state) => const MaterialPage(fullscreenDialog: true, child: RunRecordScreen()),
    ),
    GoRoute(path: records, builder: (context, state) => const RecordsScreen()),
    GoRoute(path: predictions, builder: (context, state) => const PredictionsScreen()),
    GoRoute(
      path: zones,
      builder: (context, state) => const ZonesScreen(),
      routes: [GoRoute(path: 'edit', builder: (context, state) => const ZoneSettingsScreen())],
    ),
    GoRoute(path: workouts, builder: (context, state) => const WorkoutsScreen()),
    GoRoute(
      path: newRun,
      pageBuilder: (context, state) =>
          MaterialPage(fullscreenDialog: true, child: RunLogScreen(id: state.uri.queryParameters['recording'])),
    ),
    GoRoute(
      path: '/run/:id',
      builder: (context, state) => RunDetailScreen(
        id: state.pathParameters['id']!,
        justRecorded: state.uri.queryParameters['justRecorded'] == '1',
      ),
      routes: [
        GoRoute(
          path: 'edit',
          pageBuilder: (context, state) =>
              MaterialPage(fullscreenDialog: true, child: RunLogScreen(id: state.pathParameters['id'])),
        ),
        GoRoute(
          path: 'replay',
          pageBuilder: (context, state) =>
              MaterialPage(fullscreenDialog: true, child: RunReplayScreen(id: state.pathParameters['id']!)),
        ),
      ],
    ),
  ];
}
