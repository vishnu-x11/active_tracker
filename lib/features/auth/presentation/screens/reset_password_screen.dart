import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass_field.dart';
import '../../auth_routes.dart';
import '../notifiers/reset_notifier.dart';
import '../widgets/auth_scaffold.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(resetProvider.notifier);
    final s = ref.watch(resetProvider);

    return AuthScaffold(
      icon: Icons.lock_reset_rounded,
      title: 'Reset password',
      subtitle: "Enter your account's email and we'll send you a link to choose a new password.",
      onBack: () => context.go(AuthRoutes.login),
      footer: AuthFooterLink(lead: 'Remembered it?', action: 'Sign in', onTap: () => context.go(AuthRoutes.login)),
      children: [
        if (s.sentTo != null) ...[
          FormMessage(text: 'Check your inbox at ${s.sentTo}. Follow the link, then sign in.', good: true),
          const SizedBox(height: 12),
        ],
        if (s.error != null) ...[FormMessage(text: s.error!), const SizedBox(height: 12)],
        GlassField(
          label: 'Email',
          controller: _email,
          onChanged: notifier.setEmail,
          error: s.emailError,
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => notifier.send(),
        ),
        const SizedBox(height: 20),
        GradientButton(
          label: s.sentTo == null ? 'Send reset link' : 'Send again',
          busy: s.busy,
          onPressed: notifier.send,
        ),
      ],
    );
  }
}
