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

Future<void> signOut(BuildContext context) async {
  final container = ProviderScope.containerOf(context);
  final messenger = ScaffoldMessenger.of(context);
  final result = await container.read(signOutProvider)();
  if (result case Err(:final failure)) {
    messenger.showSnackBar(SnackBar(content: Text(failure.message)));
  }
}
