import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/entities/auth_rules.dart';

class OtpBoxes extends StatefulWidget {
  const OtpBoxes({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onCompleted,
    this.hasError = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onCompleted;
  final bool hasError;

  @override
  State<OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<OtpBoxes> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Verification code, ${AuthRules.codeLength} digits',
      child: Stack(
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([widget.controller, _focus]),
            builder: (context, _) {
              final text = widget.controller.text;
              return Row(
                children: [
                  for (var i = 0; i < AuthRules.codeLength; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: DecoratedBox(
                        position: DecorationPosition.foreground,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: widget.hasError
                              ? Border.all(color: p.danger, width: 2)
                              : _focus.hasFocus && i == text.length.clamp(0, AuthRules.codeLength - 1)
                              ? Border.all(color: Metric.cta.last, width: 2)
                              : null,
                        ),
                        child: Glass(
                          kind: GlassKind.control,
                          radius: 16,
                          child: SizedBox(
                            height: 60,
                            child: Center(
                              child: Text(
                                i < text.length ? text[i] : '',
                                style: AppText.display.copyWith(fontSize: 26, color: p.text),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: AuthRules.codeLength,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: '', border: InputBorder.none),
                onChanged: (v) {
                  widget.onChanged(v);
                  if (v.length == AuthRules.codeLength) widget.onCompleted();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
