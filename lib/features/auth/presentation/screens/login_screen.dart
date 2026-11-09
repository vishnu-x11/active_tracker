import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass_field.dart';
import '../../auth_routes.dart';
import '../notifiers/login_notifier.dart';
import '../states/login_state.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/method_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.registered = false});

  final bool registered;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(loginProvider.notifier);
    final emailError = ref.watch(loginProvider.select((s) => s.emailError));
    final passwordError = ref.watch(loginProvider.select((s) => s.passwordError));
    final error = ref.watch(loginProvider.select((s) => s.error));
    final busy = ref.watch(loginProvider.select((s) => s.busy));
    final p = context.palette;

    return AuthScaffold(
      icon: Icons.local_fire_department_rounded,
      title: 'Welcome back',
      subtitle: 'Sign in to keep your workouts, water and protein in one place.',
      footer: AuthFooterLink(lead: 'New here?', action: 'Create account', onTap: () => context.go(AuthRoutes.signUp)),
      children: [
        if (widget.registered && error == null) ...[
          const FormMessage(text: 'Account created. Sign in to continue.', good: true),
          const SizedBox(height: 12),
        ],
        if (error != null) ...[FormMessage(text: error), const SizedBox(height: 12)],
        AutofillGroup(
          child: Column(
            children: [
              GlassField(
                label: 'Email',
                controller: _email,
                onChanged: notifier.setEmail,
                error: emailError,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              GlassField(
                label: 'Password',
                controller: _password,
                onChanged: notifier.setPassword,
                error: passwordError,
                obscureText: _hidePassword,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => notifier.signIn(),
                suffix: IconButton(
                  tooltip: _hidePassword ? 'Show password' : 'Hide password',
                  icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: p.sub),
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go(AuthRoutes.reset),
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            child: Text(
              'Forgot password?',
              style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.accentText),
            ),
          ),
        ),
        const SizedBox(height: 4),
        GradientButton(
          label: 'Sign in',
          busy: busy == LoginBusy.email,
          onPressed: busy == LoginBusy.none ? notifier.signIn : null,
        ),
        const OrDivider(),
        MethodButton(
          leading: const GoogleMark(),
          label: 'Continue with Google',
          busy: busy == LoginBusy.google,
          onPressed: busy == LoginBusy.none ? notifier.signInWithGoogle : null,
        ),
        const SizedBox(height: 12),
        MethodButton(
          leading: Icon(Icons.phone_iphone_rounded, size: 20, color: p.text),
          label: 'Continue with phone',
          onPressed: busy == LoginBusy.none ? () => context.go(AuthRoutes.phone) : null,
        ),
      ],
    );
  }
}
