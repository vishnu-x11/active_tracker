import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass_field.dart';
import '../../auth_routes.dart';
import '../notifiers/phone_auth_notifier.dart';
import '../widgets/auth_scaffold.dart';

class PhoneNumberScreen extends ConsumerStatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  ConsumerState<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends ConsumerState<PhoneNumberScreen> {
  final _country = TextEditingController(text: '+91');
  final _number = TextEditingController();

  @override
  void dispose() {
    _country.dispose();
    _number.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(phoneAuthProvider.select((s) => s.sends), (prev, next) {
      if (next > (prev ?? 0) && (ModalRoute.of(context)?.isCurrent ?? false)) context.go(AuthRoutes.phoneCode);
    });
    final notifier = ref.read(phoneAuthProvider.notifier);
    final error = ref.watch(phoneAuthProvider.select((s) => s.error));
    final numberError = ref.watch(phoneAuthProvider.select((s) => s.numberError));
    final busy = ref.watch(phoneAuthProvider.select((s) => s.busy));
    final p = context.palette;

    return AuthScaffold(
      icon: Icons.phone_iphone_rounded,
      title: 'Sign in with phone',
      subtitle: "We'll text you a 6-digit code. Standard SMS rates may apply.",
      onBack: () => context.go(AuthRoutes.login),
      children: [
        if (error != null) ...[FormMessage(text: error), const SizedBox(height: 12)],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 104,
              child: GlassField(
                label: 'Code',
                controller: _country,
                onChanged: notifier.setCountryCode,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[+\d]')),
                  LengthLimitingTextInputFormatter(5),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassField(
                label: 'Phone number',
                controller: _number,
                onChanged: notifier.setNumber,
                hint: '98765 43210',
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s-]')),
                  LengthLimitingTextInputFormatter(17),
                ],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => notifier.sendCode(),
              ),
            ),
          ],
        ),
        if (numberError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Text(
              numberError,
              style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: p.danger),
            ),
          ),
        const SizedBox(height: 20),
        GradientButton(label: 'Send code', busy: busy, onPressed: notifier.sendCode),
      ],
    );
  }
}
