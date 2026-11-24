import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sync/sync_controller.dart';
import '../core/widgets/app_dialog.dart';

Future<bool> confirmClearData(BuildContext context) async =>
    await showAppDialog(
      context,
      icon: Icons.delete_forever_rounded,
      title: 'Clear all your data?',
      message: 'Clearing data will permanently delete user data linked with this account.',
      cancel: 'Cancel',
      confirm: 'Clear',
      danger: true,
      confirmFirst: true,
    ) ??
    false;

Future<void> clearData(BuildContext context) async {
  if (!await confirmClearData(context) || !context.mounted) return;
  final container = ProviderScope.containerOf(context);
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  var busy = true;
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator())),
    ).whenComplete(() => busy = false),
  );
  final error = await container.read(syncControllerProvider.notifier).clearAll();
  if (busy && navigator.mounted) navigator.pop();
  messenger.showSnackBar(SnackBar(content: Text(error ?? 'Your data was cleared.')));
}
