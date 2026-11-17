import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formulas/formulas.dart';
import '../../../../core/result.dart';
import '../../../../core/sync/sync_controller.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/form_parts.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/glass_field.dart';
import '../../domain/entities/pace_zones.dart';
import '../../domain/use_cases/run_metrics.dart';
import '../providers.dart';
import '../widgets/insight_parts.dart';

class ZoneSettingsScreen extends ConsumerWidget {
  const ZoneSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedPaceZonesProvider);
    final live = ref.watch(paceZonesProvider);
    return Scaffold(
      body: PageBackdrop(
        child: SafeArea(
          child: switch ((saved, live)) {
            (AsyncData(value: final s), AsyncData(value: final l)) => _Form(saved: s, auto: l.thresholdSec),
            (AsyncError(:final error), _) || (_, AsyncError(:final error)) => Center(
              child: Text(error is Failure ? error.message : "Couldn't load your zones."),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.saved, required this.auto});

  final PaceZones saved;
  final int auto;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late bool _auto = widget.saved.auto;
  late final _threshold = TextEditingController(text: formatPace(widget.saved.thresholdSec.toDouble()));
  late final _bounds = [
    for (final b in widget.saved.copyWith(auto: false).effective) TextEditingController(text: formatPace(b.toDouble())),
  ];
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _threshold.dispose();
    for (final c in _bounds) {
      c.dispose();
    }
    super.dispose();
  }

  void _fillFromThreshold() {
    final t = RunMetrics.seconds(_threshold.text);
    if (t == null) return;
    for (final (i, b) in PaceZones.autoBounds(t).indexed) {
      _bounds[i].text = formatPace(b.toDouble());
    }
    setState(() => _error = null);
  }

  Future<void> _save() async {
    final PaceZones next;
    if (_auto) {
      next = widget.saved.copyWith(auto: true);
    } else {
      final t = RunMetrics.seconds(_threshold.text);
      final b = [for (final c in _bounds) RunMetrics.seconds(c.text)];
      if (t == null || b.contains(null)) {
        setState(() => _error = 'Type every pace as m:ss, for example 5:30.');
        return;
      }
      next = PaceZones(auto: false, thresholdSec: t, bounds: [for (final v in b) v!]);
    }
    setState(() => _busy = true);
    final r = await ref.read(savePaceZonesProvider)(next);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (r) {
      case Ok():
        ref.invalidate(savedPaceZonesProvider);
        ref.read(syncControllerProvider.notifier).nudge();
        context.pop();
      case Err(:final failure):
        setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shown = _auto ? PaceZones(thresholdSec: widget.auto) : null;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              FormHeader(title: 'Pace zones', onBack: () => context.pop()),
              const SizedBox(height: 16),
              Glass(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Auto-calculate my ranges', style: AppText.body.copyWith(color: p.text)),
                      subtitle: Text(
                        'Uses the pace of your predicted 10K, or 6:00 /km until there are enough GPS runs.',
                        style: AppText.small.copyWith(color: p.sub),
                      ),
                      value: _auto,
                      onChanged: (v) => setState(() {
                        _auto = v;
                        _error = null;
                      }),
                    ),
                    const SizedBox(height: 8),
                    if (shown != null)
                      _Value(label: 'Threshold pace', value: '${formatPace(shown.thresholdSec.toDouble())} /km')
                    else
                      GlassField(
                        label: 'Threshold pace',
                        controller: _threshold,
                        unit: '/km',
                        hint: 'm:ss',
                        keyboardType: TextInputType.datetime,
                        onChanged: (_) => setState(() => _error = null),
                        suffix: TextButton(onPressed: _fillFromThreshold, child: const Text('Fill zones')),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Glass(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var z = 6; z >= 1; z--) ...[
                      Row(
                        children: [
                          Container(
                            width: 30,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: zoneColors[z - 1], borderRadius: BorderRadius.circular(6)),
                            child: Text('Z$z', style: AppText.tab.copyWith(color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  PaceZones.names[z - 1],
                                  style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
                                ),
                                if (shown != null)
                                  Text('${shown.range(z)} /km', style: AppText.small.copyWith(color: p.sub)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (shown == null && z > 1) ...[
                        const SizedBox(height: 8),
                        GlassField(
                          label: 'Zone $z is faster than',
                          controller: _bounds[6 - z],
                          unit: '/km',
                          hint: 'm:ss',
                          keyboardType: TextInputType.datetime,
                          onChanged: (_) => setState(() => _error = null),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        SaveBar(
          error: _error,
          button: GradientButton(label: 'Save pace zones', busy: _busy, onPressed: _busy ? null : _save),
        ),
      ],
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppText.body.copyWith(color: p.sub)),
        ),
        Text(value, style: AppText.number.copyWith(color: p.text)),
      ],
    );
  }
}
