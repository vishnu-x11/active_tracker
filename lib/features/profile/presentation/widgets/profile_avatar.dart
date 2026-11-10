import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/use_cases/profile_photo.dart';
import '../notifiers/profile_notifier.dart';
import '../screens/photo_crop_screen.dart';

class ProfileAvatar extends ConsumerStatefulWidget {
  const ProfileAvatar({super.key, this.size = 64});

  final double size;

  @override
  ConsumerState<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends ConsumerState<ProfileAvatar> {
  String? _encoded;
  Uint8List? _bytes;
  bool _busy = false;

  Uint8List? _decode(String? encoded) {
    if (encoded != _encoded) {
      _encoded = encoded;
      _bytes = encoded == null ? null : base64Decode(encoded);
    }
    return _bytes;
  }

  static String initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '·';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  Future<void> _choose() async {
    final hasPhoto = ref.read(profileProvider).value?.photo != null;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoSheet(hasPhoto: hasPhoto),
    );
    if (action == null || !mounted) return;
    setState(() => _busy = true);
    final n = ref.read(profileProvider.notifier);
    final error = switch (action) {
      'camera' => await n.pickPhoto(PhotoSource.camera, _frame),
      'gallery' => await n.pickPhoto(PhotoSource.gallery, _frame),
      _ => await n.removePhoto(),
    };
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  Future<CropBox?> _frame(Uint8List photo) async => mounted ? showPhotoCrop(context, photo) : null;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = widget.size;
    final bytes = _decode(ref.watch(profileProvider.select((v) => v.value?.photo)));
    final url = ref.watch(photoUrlProvider);
    final name = ref.watch(displayNameProvider);
    final ImageProvider? image = bytes != null ? MemoryImage(bytes) : (url != null ? NetworkImage(url) : null);
    return Semantics(
      button: true,
      label: 'Profile photo. Change photo',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _busy ? null : _choose,
        child: SizedBox.square(
          dimension: s + 6,
          child: Stack(
            children: [
              Container(
                width: s,
                height: s,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: Metric.burn),
                  shape: BoxShape.circle,
                  image: image == null ? null : DecorationImage(image: image, fit: BoxFit.cover),
                ),
                child: _busy
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : (image == null
                          ? Text(
                              initials(name),
                              style: AppText.title.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
                            )
                          : null),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: Metric.cta),
                    shape: BoxShape.circle,
                    border: Border.all(color: p.pageTop, width: 2),
                  ),
                  child: const Icon(Icons.photo_camera_rounded, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoSheet extends StatelessWidget {
  const _PhotoSheet({required this.hasPhoto});

  final bool hasPhoto;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget option(String value, IconData icon, String label, {bool danger = false}) => ListTile(
      leading: Icon(icon, color: danger ? p.danger : p.text),
      title: Text(
        label,
        style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: danger ? p.danger : p.text),
      ),
      onTap: () => Navigator.pop(context, value),
    );
    return Glass(
      kind: GlassKind.bar,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(color: p.hair, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                child: Text('Profile photo', style: AppText.title.copyWith(color: p.text)),
              ),
              option('camera', Icons.photo_camera_outlined, 'Take photo'),
              option('gallery', Icons.photo_library_outlined, 'Choose from gallery'),
              if (hasPhoto) option('remove', Icons.delete_outline_rounded, 'Remove photo', danger: true),
            ],
          ),
        ),
      ),
    );
  }
}
