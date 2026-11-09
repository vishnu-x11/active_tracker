import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/core_providers.dart';
import 'remote_store.dart';
import 'sync_engine.dart';

final dataRevisionProvider = NotifierProvider<DataRevision, int>(DataRevision.new);

class DataRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final remoteStoreProvider = Provider<RemoteStore>((ref) => FirestoreRemoteStore(FirebaseFirestore.instance));

final syncEngineProvider = Provider<SyncEngine>(
  (ref) => SyncEngine(ref.watch(appDatabaseProvider), ref.watch(remoteStoreProvider)),
);

typedef SyncStatus = ({DateTime? lastSynced, String? error, bool running});

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(SyncController.new);

class SyncController extends Notifier<SyncStatus> {
  Timer? _debounce;
  Timer? _periodic;
  StreamSubscription<Object>? _net;
  AppLifecycleListener? _life;
  bool _started = false;

  static const debounce = Duration(seconds: 1);
  static const every = Duration(minutes: 2);

  @override
  SyncStatus build() {
    ref.onDispose(_stop);
    return (lastSynced: null, error: null, running: false);
  }

  static const firstDelay = Duration(seconds: 2);

  void start() {
    if (_started) return;
    _started = true;
    _debounce = Timer(firstDelay, () => unawaited(syncNow()));
    ref.listen(currentUidProvider, (prev, next) {
      final launching = _debounce?.isActive ?? false;
      if (!launching && prev?.value != next.value && next.value != null) unawaited(syncNow());
    });
    _periodic = Timer.periodic(every, (_) => unawaited(syncNow()));
    _net = Connectivity().onConnectivityChanged.listen((r) {
      if (r != ConnectivityResult.none) unawaited(syncNow());
    });
    _life = AppLifecycleListener(onResume: () => unawaited(syncNow()));
  }

  void _stop() {
    _debounce?.cancel();
    _periodic?.cancel();
    unawaited(_net?.cancel());
    _life?.dispose();
  }

  void nudge() {
    if (!_started) return;
    _debounce?.cancel();
    _debounce = Timer(debounce, () => unawaited(syncNow()));
  }

  Future<bool> restoreProfile(String uid) async {
    try {
      final engine = ref.read(syncEngineProvider);
      return await engine.restoreProfile(uid).timeout(const Duration(seconds: 8));
    } catch (e) {
      developer.log('Profile restore skipped', error: e, name: 'sync');
      return false;
    }
  }

  Future<void> syncNow() async {
    if (state.running) return;
    final uid = ref.read(currentUidProvider).value;
    if (uid == null) return;
    state = (lastSynced: state.lastSynced, error: null, running: true);
    try {
      final report = await ref.read(syncEngineProvider).sync(uid);
      if (!ref.mounted) return;
      if (report.pulled > 0) ref.read(dataRevisionProvider.notifier).bump();
      state = (lastSynced: DateTime.now(), error: null, running: false);
    } catch (e, st) {
      developer.log('Sync failed', error: e, stackTrace: st, name: 'sync');
      if (ref.mounted) state = (lastSynced: state.lastSynced, error: 'Not synced yet. Will retry.', running: false);
    }
  }
}
