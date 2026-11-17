import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dates.dart';
import '../../../../core/formulas/formulas.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/form_parts.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/entities/pace_zones.dart';
import '../../domain/entities/run_analysis.dart';
import '../../domain/use_cases/run_insights.dart';
import '../../running_routes.dart';
import '../providers.dart';
import '../widgets/insight_parts.dart';

enum ZonePeriod {
  d7('7D', 'this week'),
  m1('1M', 'this month'),
  m3('3M', 'these 3 months'),
  m6('6M', 'these 6 months'),
  ytd('YTD', 'this year'),
  y1('1Y', 'this year'),
  custom('Custom', 'in this period');

  const ZonePeriod(this.label, this.phrase);
  final String label;
  final String phrase;
}

class ZonesScreen extends ConsumerStatefulWidget {
  const ZonesScreen({super.key});

  @override
  ConsumerState<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends ConsumerState<ZonesScreen> {
  ZonePeriod _period = ZonePeriod.m1;
  DateTimeRange? _custom;

  (DateTime, DateTime) _range(DateTime today) => switch (_period) {
    ZonePeriod.d7 => (addDays(today, -6), today),
    ZonePeriod.m1 => (addDays(today, -29), today),
    ZonePeriod.m3 => (addDays(today, -89), today),
    ZonePeriod.m6 => (addDays(today, -179), today),
    ZonePeriod.ytd => (DateTime(today.year), today),
    ZonePeriod.y1 => (addDays(today, -364), today),
    ZonePeriod.custom => (dateOnly(_custom?.start ?? addDays(today, -29)), dateOnly(_custom?.end ?? today)),
  };

  Future<void> _pick(ZonePeriod v) async {
    if (v != ZonePeriod.custom) return setState(() => _period = v);
    final today = ref.read(todayProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 5),
      lastDate: today,
      initialDateRange: _custom ?? DateTimeRange(start: addDays(today, -29), end: today),
    );
    if (picked != null && mounted) {
      setState(() {
        _custom = picked;
        _period = ZonePeriod.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final today = ref.watch(todayProvider);
    final runs = ref.watch(runAnalysesProvider).value ?? const <RunAnalysis>[];
    final zones = ref.watch(paceZonesProvider).value ?? const PaceZones();
    final (from, to) = _range(today);
    final days = to.difference(from).inDays + 1;
    final cur = ZoneReport.seconds(runs, zones, from, to);
    final prev = ZoneReport.seconds(runs, zones, addDays(from, -days), addDays(from, -1));
    final shares = ZoneReport.shares(cur), prevShares = ZoneReport.shares(prev);
    final top = ZoneReport.topZone(cur);
    final change = top == null || ZoneReport.topZone(prev) == null
        ? null
        : ((shares[top - 1] - prevShares[top - 1]) * 100).round();
    final insight = ZoneReport.insight(cur, prev, _period.phrase);
    return Scaffold(
      body: PageBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              FormHeader(
                title: 'Training zones',
                onBack: () => context.pop(),
                trailing: IconButton(
                  tooltip: 'Edit zones',
                  icon: Icon(Icons.edit_rounded, color: p.text),
                  onPressed: () => context.push(RunRoutes.zoneSettings),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final v in ZonePeriod.values)
                    ChoiceChip(label: Text(v.label), selected: v == _period, onSelected: (_) => _pick(v)),
                ],
              ),
              const SizedBox(height: 16),
              Glass(
                radius: 32,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('PACE ZONES · RUN', style: AppText.eyebrow.copyWith(color: p.sub)),
                    const SizedBox(height: 6),
                    Text(
                      top == null ? 'No GPS runs' : '${(shares[top - 1] * 100).round()}% in Zone $top',
                      style: AppText.display.copyWith(fontSize: 28, color: p.text),
                    ),
                    Text(
                      '${shortDate(from)} – ${shortDate(to)}${top == null ? '' : ' · ${PaceZones.names[top - 1]}'}',
                      style: AppText.small.copyWith(color: p.sub),
                    ),
                    if (change != null && change != 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChangeChip(text: '${change.abs()}%', good: change > 0, down: change < 0),
                          const SizedBox(width: 6),
                          Text('vs the period before', style: AppText.small.copyWith(color: p.sub)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    for (var z = 6; z >= 1; z--)
                      _ZoneRow(zone: z, zones: zones, seconds: cur[z - 1], share: shares[z - 1]),
                  ],
                ),
              ),
              if (insight != null) ...[
                const SizedBox(height: 12),
                Glass(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IconTile(icon: Icons.insights_rounded, colors: Metric.run),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your zones at a glance', style: AppText.cardTitle.copyWith(color: p.text)),
                            const SizedBox(height: 4),
                            Text(insight, style: AppText.small.copyWith(color: p.sub)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Glass(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Zones use your pace over each 30 seconds of GPS runs, against a threshold pace of '
                  '${formatPace(zones.thresholdSec.toDouble())} /km${!zones.auto
                      ? ''
                      : RacePredictor.predict(runs, RaceTarget.k10, today).seconds == null
                      ? ', the default until you have 5 GPS runs of 3 km or more'
                      : ', from your predicted 10K'}. '
                  'Heart-rate zones need a heart-rate sensor, which Active Tracker does not connect to.',
                  style: AppText.small.copyWith(color: p.sub),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({required this.zone, required this.zones, required this.seconds, required this.share});

  final int zone;
  final PaceZones zones;
  final double seconds;
  final double share;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Zone $zone, ${PaceZones.names[zone - 1]}, ${zoneTime(seconds)}, ${zones.range(zone)} per km',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: zoneColors[zone - 1], borderRadius: BorderRadius.circular(6)),
                  child: Text('Z$zone', style: AppText.tab.copyWith(color: Colors.white)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    PaceZones.names[zone - 1],
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
                  ),
                ),
                Text(zoneTime(seconds), style: AppText.body.copyWith(color: p.text)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: share,
                      minHeight: 8,
                      color: zoneColors[zone - 1],
                      backgroundColor: p.text.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 92,
                  child: Text(
                    '${zones.range(zone)} /km',
                    textAlign: TextAlign.end,
                    style: AppText.tab.copyWith(color: p.sub),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
