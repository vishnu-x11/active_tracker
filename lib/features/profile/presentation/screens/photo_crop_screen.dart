import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../domain/use_cases/profile_photo.dart';

Future<CropBox?> showPhotoCrop(BuildContext context, Uint8List photo) => Navigator.of(
  context,
  rootNavigator: true,
).push<CropBox>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => PhotoCropScreen(photo: photo)));

class PhotoCropScreen extends StatefulWidget {
  const PhotoCropScreen({super.key, required this.photo});

  final Uint8List photo;

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  static const maxZoom = 5.0;

  ui.Image? _image;
  bool _failed = false;
  double _zoom = 1;
  Offset _offset = Offset.zero;
  double _diameter = 0;

  double _startZoom = 1;
  Offset _startOffset = Offset.zero;
  Offset _startFocal = Offset.zero;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    final codec = await ui.instantiateImageCodec(widget.photo).then<ui.Codec?>((c) => c, onError: (_) => null);
    final frame = await codec?.getNextFrame().then<ui.FrameInfo?>((f) => f, onError: (_) => null);
    codec?.dispose();
    if (!mounted) {
      frame?.image.dispose();
      return;
    }
    setState(() {
      _image = frame?.image;
      _failed = frame == null;
    });
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  double _base(ui.Image image, double d) => d / math.min(image.width, image.height);

  Offset _clamp(Offset o, ui.Image image, double d, double zoom) {
    final k = _base(image, d) * zoom;
    final dx = (image.width * k - d) / 2;
    final dy = (image.height * k - d) / 2;
    return Offset(o.dx.clamp(-dx, dx), o.dy.clamp(-dy, dy));
  }

  void _onStart(ScaleStartDetails details, Offset center) {
    _startZoom = _zoom;
    _startOffset = _offset;
    _startFocal = details.localFocalPoint - center;
  }

  void _onUpdate(ScaleUpdateDetails details, Offset center, double d) {
    final image = _image;
    if (image == null) return;
    final zoom = (_startZoom * details.scale).clamp(1.0, maxZoom);
    final focal = details.localFocalPoint - center;
    final next = focal - (_startFocal - _startOffset) * (zoom / _startZoom);
    setState(() {
      _zoom = zoom;
      _offset = _clamp(next, image, d, zoom);
    });
  }

  CropBox _box(ui.Image image, double d) {
    final k = _base(image, d) * _zoom;
    return CropBox(
      left: (image.width * k / 2 - d / 2 - _offset.dx) / k,
      top: (image.height * k / 2 - d / 2 - _offset.dy) / k,
      size: d / k,
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Cancel',
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Move and scale',
                      textAlign: TextAlign.center,
                      style: AppText.title.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final d = math.max(math.min(c.maxWidth, c.maxHeight) - 48, 120.0);
                  _diameter = d;
                  final center = Offset(c.maxWidth / 2, c.maxHeight / 2);
                  if (image == null) {
                    return Center(
                      child: _failed
                          ? Text("Couldn't open that photo.", style: AppText.body.copyWith(color: Colors.white))
                          : const CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  final k = _base(image, d) * _zoom;
                  final w = image.width * k;
                  final h = image.height * k;
                  return Semantics(
                    label: 'Photo. Pinch to zoom, drag to move. Double tap to reset.',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: (s) => _onStart(s, center),
                      onScaleUpdate: (s) => _onUpdate(s, center, d),
                      onDoubleTap: () => setState(() {
                        _zoom = 1;
                        _offset = Offset.zero;
                      }),
                      child: Stack(
                        children: [
                          Positioned(
                            left: center.dx + _offset.dx - w / 2,
                            top: center.dy + _offset.dy - h / 2,
                            width: w,
                            height: h,
                            child: RawImage(image: image, fit: BoxFit.fill, filterQuality: FilterQuality.medium),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(painter: _CircleMask(diameter: d)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Pinch to zoom, drag to move', style: AppText.small.copyWith(color: Colors.white70)),
                  const SizedBox(height: 14),
                  GradientButton(
                    label: 'Use photo',
                    onPressed: image == null ? null : () => Navigator.pop(context, _box(image, _diameter)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleMask extends CustomPainter {
  const _CircleMask({required this.diameter});

  final double diameter;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final circle = Rect.fromCircle(center: center, radius: diameter / 2);
    canvas
      ..drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(Offset.zero & size)
          ..addOval(circle),
        Paint()..color = Colors.black.withValues(alpha: 0.62),
      )
      ..drawOval(
        circle,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.9),
      );
  }

  @override
  bool shouldRepaint(_CircleMask old) => old.diameter != diameter;
}
