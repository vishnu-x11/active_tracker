import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass_field.dart';
import '../../auth_routes.dart';
import '../notifiers/phone_auth_notifier.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/otp_boxes.dart';

class PhoneCodeScreen extends ConsumerStatefulWidget {
  const PhoneCodeScreen({super.key});

  @override
  ConsumerState<PhoneCodeScreen> createState() => _PhoneCodeScreenState();
}

class _PhoneCodeScreenState extends ConsumerState<PhoneCodeScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(phoneAuthProvider.select((s) => s.code), (_, code) {
      if (code != _code.text) _code.text = code;
    });
    final notifier = ref.read(phoneAuthProvider.notifier);
    final error = ref.watch(phoneAuthProvider.select((s) => s.error));
    final busy = ref.watch(phoneAuthProvider.select((s) => s.busy));
    final phone = ref.watch(phoneAuthProvider.select((s) => s.phoneE164)) ?? '';
    final p = context.palette;

    return AuthScaffold(
      icon: Icons.sms_rounded,
      title: 'Enter the code',
      subtitle: 'We sent a 6-digit code to $phone.',
      onBack: () => context.go(AuthRoutes.phone),
      children: [
        if (error != null) ...[FormMessage(text: error), const SizedBox(height: 12)],
        OtpBoxes(controller: _code, onChanged: notifier.setCode, onCompleted: notifier.verify, hasError: error != null),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              onPressed: () => context.go(AuthRoutes.phone),
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              child: Text(
                'Change number',
                style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.accentText),
              ),
            ),
            const _ResendButton(),
          ],
        ),
        const SizedBox(height: 12),
        GradientButton(label: 'Verify', busy: busy, onPressed: notifier.verify),
      ],
    );
  }
}

class _ResendButton extends ConsumerWidget {
  const _ResendButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final left = ref.watch(phoneAuthProvider.select((s) => s.secondsLeft));
    final canResend = ref.watch(phoneAuthProvider.select((s) => s.canResend));
    if (left > 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('Resend code in 0:${left.toString().padLeft(2, '0')}', style: AppText.body.copyWith(color: p.sub)),
      );
    }
    return TextButton(
      onPressed: canResend ? ref.read(phoneAuthProvider.notifier).resend : null,
      style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
      child: Text(
        'Resend code',
        style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.accentText),
      ),
    );
  }
}
