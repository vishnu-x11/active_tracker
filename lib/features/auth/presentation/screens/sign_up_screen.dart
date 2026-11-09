import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass_field.dart';
import '../../auth_routes.dart';
import '../notifiers/sign_up_notifier.dart';
import '../widgets/auth_scaffold.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(signUpProvider.select((s) => s.done), (_, done) {
      if (done) context.go(AuthRoutes.loginAfterSignUp);
    });
    final notifier = ref.read(signUpProvider.notifier);
    final s = ref.watch(signUpProvider);
    final p = context.palette;

    return AuthScaffold(
      icon: Icons.person_add_alt_1_rounded,
      title: 'Create account',
      subtitle: 'Use your email. You can also sign in with Google or your phone instead.',
      onBack: () => context.go(AuthRoutes.login),
      footer: AuthFooterLink(lead: 'Have an account?', action: 'Sign in', onTap: () => context.go(AuthRoutes.login)),
      children: [
        if (s.error != null) ...[FormMessage(text: s.error!), const SizedBox(height: 12)],
        AutofillGroup(
          child: Column(
            children: [
              GlassField(
                label: 'Name',
                controller: _name,
                onChanged: notifier.setName,
                error: s.nameError,
                hint: 'Your name',
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              GlassField(
                label: 'Email',
                controller: _email,
                onChanged: notifier.setEmail,
                error: s.emailError,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              GlassField(
                label: 'Password (at least 6 characters)',
                controller: _password,
                onChanged: notifier.setPassword,
                error: s.passwordError,
                obscureText: _hidePassword,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => notifier.submit(),
                suffix: IconButton(
                  tooltip: _hidePassword ? 'Show password' : 'Hide password',
                  icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: p.sub),
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GradientButton(label: 'Create account', busy: s.busy, onPressed: notifier.submit),
      ],
    );
  }
}
