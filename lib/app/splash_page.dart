import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../core/theme/app_palette.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/buttons.dart';
import '../core/widgets/glass.dart';
import '../features/profile/presentation/notifiers/profile_notifier.dart';
import 'sign_out_button.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final error = ref.watch(profileProvider.select((v) => v.hasError ? v.error : null));
    return Scaffold(
      body: PageBackdrop(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const IconTile(icon: Icons.local_fire_department_rounded, colors: Metric.cta, size: 72),
                  const SizedBox(height: 20),
                  Text('Active Tracker', style: AppText.display.copyWith(color: p.text)),
                  const SizedBox(height: 24),
                  if (error == null)
                    SizedBox.square(
                      dimension: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.6, color: Metric.cta.last),
                    )
                  else ...[
                    Text(
                      error is Failure ? error.message : "Couldn't open your profile.",
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(color: p.sub),
                    ),
                    const SizedBox(height: 16),
                    GradientButton(label: 'Try again', onPressed: () => ref.invalidate(profileProvider)),
                    const SizedBox(height: 8),
                    const SignOutButton(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
