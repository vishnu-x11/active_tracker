import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../core/theme/app_palette.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/providers.dart';

class SignOutButton extends ConsumerWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return TextButton(
      style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
      onPressed: () => signOut(context),
      child: Text(
        'Sign out',
        style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.accentText),
      ),
    );
  }
}

Future<bool> confirmSignOut(BuildContext context) async {
  final p = context.palette;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: p.pageTop,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text('Sign out?', style: AppText.title.copyWith(color: p.text)),
      content: Text(
        'You can sign back in at any time to see your logs.',
        style: AppText.body.copyWith(color: p.sub),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: TextStyle(color: p.text)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Sign out', style: TextStyle(fontWeight: FontWeight.w600, color: p.danger)),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<void> signOut(BuildContext context) async {
  if (!await confirmSignOut(context) || !context.mounted) return;
  final container = ProviderScope.containerOf(context);
  final messenger = ScaffoldMessenger.of(context);
  final result = await container.read(signOutProvider)();
  if (result case Err(:final failure)) {
    messenger.showSnackBar(SnackBar(content: Text(failure.message)));
  }
}
