import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formulas/formulas.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/glass_field.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/segmented.dart';
import '../../domain/entities/profile.dart';
import '../../domain/use_cases/edit_profile.dart';
import '../notifiers/profile_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.accountRows = const []});

  final List<Widget> accountRows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final profile = ref.watch(profileProvider).value;
    if (profile == null) return const Center(child: CircularProgressIndicator());
    final name = ref.watch(displayNameProvider);
    final auth = ref.watch(accountLabelProvider);
    final bmiValue = bmi(weightKg: profile.weightKg, heightCm: profile.heightCm);
    final kg = profile.weightKg.toStringAsFixed(profile.weightKg % 1 == 0 ? 0 : 1);
    final notifier = ref.read(profileProvider.notifier);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, tabBarInset),
        children: [
          Text(
            'Account and targets',
            style: AppText.small.copyWith(fontWeight: FontWeight.w500, color: p.sub),
          ),
          Text('Profile', style: AppText.display.copyWith(color: p.text)),
          const SizedBox(height: 16),
          Glass(
            radius: 32,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: Metric.burn),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _initials(name),
                        style: AppText.title.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name ?? 'Your account', style: AppText.cardTitle.copyWith(fontSize: 18, color: p.text)),
                          if (auth != null) Text(auth, style: AppText.small.copyWith(color: p.sub)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: p.hair),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Stat(
                      label: 'Weight',
                      value: kg,
                      unit: 'kg',
                      onTap: () => _edit(context, ref, ProfileField.weight, kg),
                    ),
                    _Stat(
                      label: 'Height',
                      value: profile.heightCm.toStringAsFixed(0),
                      unit: 'cm',
                      onTap: () => _edit(context, ref, ProfileField.height, profile.heightCm.toStringAsFixed(0)),
                    ),
                    _Stat(label: 'BMI', value: bmiValue.toStringAsFixed(1), unit: _bmiLabel(bmiValue)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Changing weight updates future burn estimates; past sessions keep the weight they were logged with.',
                  style: AppText.small.copyWith(color: p.sub),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('DAILY TARGETS', style: AppText.eyebrow.copyWith(color: p.sub)),
          const SizedBox(height: 8),
          Glass(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _Row(
                  icon: Icons.local_fire_department_rounded,
                  colors: Metric.burn,
                  title: 'Active burn',
                  note: 'Gym + running',
                  value: '${profile.burnTargetKcal} kcal',
                  onTap: () => _edit(context, ref, ProfileField.burnTarget, '${profile.burnTargetKcal}'),
                ),
                _Row(
                  icon: Icons.egg_alt_rounded,
                  colors: Metric.protein,
                  title: 'Protein',
                  note: '${profile.proteinGPerKg} g per kg',
                  value: '${proteinTargetG(weightKg: profile.weightKg, gPerKg: profile.proteinGPerKg)} g',
                  onTap: () => _edit(context, ref, ProfileField.proteinRatio, '${profile.proteinGPerKg}'),
                ),
                _Row(
                  icon: Icons.water_drop_rounded,
                  colors: Metric.water,
                  title: 'Water',
                  note: '${profile.waterMlPerKg} ml per kg',
                  value:
                      '${(waterTargetMl(weightKg: profile.weightKg, workoutDay: false, mlPerKg: profile.waterMlPerKg) / 1000).toStringAsFixed(1)} L',
                  onTap: () => _edit(context, ref, ProfileField.waterPerKg, '${profile.waterMlPerKg}'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const IconTile(icon: Icons.bolt_rounded, colors: Metric.water, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '+500 ml on workout days',
                              style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
                            ),
                            Text(
                              profile.workoutWaterBoost ? 'On days with a gym session or run' : 'Off',
                              style: AppText.small.copyWith(color: p.sub),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: profile.workoutWaterBoost,
                        activeThumbColor: Colors.white,
                        activeTrackColor: Metric.cta.last,
                        onChanged: (v) => notifier.change((p) => p.copyWith(workoutWaterBoost: v)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('APPEARANCE', style: AppText.eyebrow.copyWith(color: p.sub)),
          const SizedBox(height: 8),
          Glass(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Theme',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
                ),
                Text(
                  profile.theme == ThemePreference.system ? 'Follows your phone' : 'Always ${profile.theme.name}',
                  style: AppText.small.copyWith(color: p.sub),
                ),
                const SizedBox(height: 12),
                GlassSegmented<ThemePreference>(
                  options: const [
                    (ThemePreference.system, 'System'),
                    (ThemePreference.light, 'Light'),
                    (ThemePreference.dark, 'Dark'),
                  ],
                  value: profile.theme,
                  onChanged: (t) => notifier.change((p) => p.copyWith(theme: t)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('ACCOUNT', style: AppText.eyebrow.copyWith(color: p.sub)),
          const SizedBox(height: 8),
          Glass(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ...accountRows,
                const _Row(
                  icon: Icons.straighten_rounded,
                  colors: Metric.run,
                  title: 'Units',
                  note: null,
                  value: 'kg · cm · km',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '·';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  static String _bmiLabel(double b) => b < 18.5 ? 'Under' : (b < 25 ? 'Healthy' : (b < 30 ? 'Over' : 'Obese'));

  static Future<void> _edit(BuildContext context, WidgetRef ref, ProfileField field, String current) async {
    final (title, unit) = switch (field) {
      ProfileField.weight => ('Weight', 'kg'),
      ProfileField.height => ('Height', 'cm'),
      ProfileField.burnTarget => ('Daily burn target', 'kcal'),
      ProfileField.proteinRatio => ('Protein per kg', 'g'),
      ProfileField.waterPerKg => ('Water per kg', 'ml'),
    };
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSheet(title: title, unit: unit, field: field, initial: current),
    );
  }
}

class _EditSheet extends ConsumerStatefulWidget {
  const _EditSheet({required this.title, required this.unit, required this.field, required this.initial});

  final String title;
  final String unit;
  final ProfileField field;
  final String initial;

  @override
  ConsumerState<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends ConsumerState<_EditSheet> {
  late final _c = TextEditingController(text: widget.initial);
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final problem = await ref.read(profileProvider.notifier).edit(widget.field, _c.text);
    if (!mounted) return;
    if (problem == null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _error = problem;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final whole = widget.field == ProfileField.burnTarget || widget.field == ProfileField.waterPerKg;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Glass(
        kind: GlassKind.bar,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: AppText.title.copyWith(color: context.palette.text)),
              const SizedBox(height: 14),
              GlassField(
                label: widget.title,
                controller: _c,
                unit: widget.unit,
                error: _error,
                autofocus: true,
                keyboardType: TextInputType.numberWithOptions(decimal: !whole),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(whole ? r'\d' : r'[\d.,]')),
                  LengthLimitingTextInputFormatter(6),
                ],
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 16),
              GradientButton(label: 'Save', busy: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.unit, this.onTap});

  final String label;
  final String value;
  final String unit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Semantics(
        button: onTap != null,
        label: '$label $value $unit${onTap == null ? '' : ', edit'}',
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.tab.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: p.sub),
                      ),
                    ),
                    if (onTap != null) ...[const SizedBox(width: 4), Icon(Icons.edit_rounded, size: 11, color: p.sub)],
                  ],
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      text: value,
                      children: [
                        TextSpan(
                          text: ' $unit',
                          style: AppText.small.copyWith(color: p.sub),
                        ),
                      ],
                    ),
                    style: AppText.display.copyWith(fontSize: 22, color: p.text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.colors,
    required this.title,
    required this.note,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final List<Color> colors;
  final String title;
  final String? note;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            IconTile(icon: icon, colors: colors, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
                  ),
                  if (note != null) Text(note!, style: AppText.small.copyWith(color: p.sub)),
                ],
              ),
            ),
            Text(
              value,
              style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: p.text),
            ),
            if (onTap != null) Icon(Icons.chevron_right_rounded, color: p.sub),
          ],
        ),
      ),
    );
  }
}

class ProfileAccountRow extends StatelessWidget {
  const ProfileAccountRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: danger ? p.danger : p.text),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: danger ? p.danger : p.text),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.sub),
          ],
        ),
      ),
    );
  }
}
