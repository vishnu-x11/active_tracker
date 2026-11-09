import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../dates.dart';
import '../storage/app_database.dart';

export '../dates.dart' show dayKey;

final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden in main()'),
);

final newIdProvider = Provider<String Function()>((ref) => const Uuid().v4);

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final currentUidProvider = StreamProvider<String?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges().map((u) => u?.uid).distinct(),
);

final displayNameProvider = Provider<String?>((ref) {
  ref.watch(currentUidProvider);
  return ref.watch(firebaseAuthProvider).currentUser?.displayName;
});

final accountLabelProvider = Provider<String?>((ref) {
  ref.watch(currentUidProvider);
  final user = ref.watch(firebaseAuthProvider).currentUser;
  return user?.email ?? user?.phoneNumber;
});

final todayProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  final timer = Timer(addDays(dateOnly(now), 1).difference(now), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return dateOnly(now);
});

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void set(ThemeMode mode) => state = mode;
}

final selectedDayProvider = NotifierProvider<SelectedDayNotifier, DateTime>(SelectedDayNotifier.new);

class SelectedDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => dateOnly(DateTime.now());

  void select(DateTime day) => state = dateOnly(day);
  void today() => state = dateOnly(DateTime.now());
}
