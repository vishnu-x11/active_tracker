import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_palette.dart';
import '../../domain/entities/track_point.dart';

final mapTilesProvider = Provider<bool>((ref) => true);

const mapPlaceholder = 'assets/images/map_placeholder.jpg';

bool mapHasTiles(Uint8List png, {double minBytesPerPixel = 0.04}) {
  if (png.length < 24) return false;
  final header = ByteData.sublistView(png, 16, 24);
  final pixels = header.getUint32(0) * header.getUint32(4);
  return pixels > 0 && png.length / pixels >= minBytesPerPixel;
}

Future<void> waitForTiles(GoogleMapController map, {Duration max = const Duration(seconds: 8)}) async {
  final end = DateTime.now().add(max);
  while (DateTime.now().isBefore(end)) {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final Uint8List? png;
    try {
      png = await map.takeSnapshot();
    } catch (_) {
      return;
    }
    if (png != null && mapHasTiles(png)) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return;
    }
  }
}

class MapLoading extends StatelessWidget {
  const MapLoading({super.key, this.spinning = true});

  final bool spinning;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        mapPlaceholder,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => ColoredBox(color: context.palette.mapBg),
      ),
      const ColoredBox(color: Color(0x660B1220)),
      if (spinning) const Center(child: CircularProgressIndicator(color: Colors.white)),
    ],
  );
}

class MapCover extends StatelessWidget {
  const MapCover({super.key, required this.ready, required this.onGone});

  final bool ready;
  final VoidCallback onGone;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: ready,
    child: AnimatedOpacity(
      opacity: ready ? 0 : 1,
      duration: const Duration(milliseconds: 350),
      onEnd: () {
        if (ready) onGone();
      },
      child: MapLoading(spinning: !ready),
    ),
  );
}

final _dots = <Color, BitmapDescriptor>{};

Future<BitmapDescriptor> mapDot(Color color, {Color edge = Colors.white, int size = 18}) async {
  if (_dots[color] case final d?) return d;
  const px = 54;
  final recorder = ui.PictureRecorder();
  const c = Offset(px / 2, px / 2);
  Canvas(recorder)
    ..drawCircle(c, px / 2, Paint()..color = edge)
    ..drawCircle(c, px / 2 - 9, Paint()..color = color);
  final image = await recorder.endRecording().toImage(px, px);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return _dots[color] = BitmapDescriptor.bytes(
    png!.buffer.asUint8List(),
    width: size.toDouble(),
    height: size.toDouble(),
  );
}

const medalColors = [Color(0xFFFFC93C), Color(0xFFC9D1DC), Color(0xFFD9955A)];

final _medals = <int, BitmapDescriptor>{};

Future<BitmapDescriptor> mapMedal(int rank) async {
  if (_medals[rank] case final d?) return d;
  const px = 72;
  final recorder = ui.PictureRecorder();
  const c = Offset(px / 2, px / 2);
  final canvas = Canvas(recorder)
    ..drawCircle(c, px / 2, Paint()..color = Colors.white)
    ..drawCircle(c, px / 2 - 6, Paint()..color = medalColors[(rank - 1).clamp(0, 2)]);
  final tp = TextPainter(
    text: TextSpan(
      text: '$rank',
      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFF3A2A00)),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  final image = await recorder.endRecording().toImage(px, px);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return _medals[rank] = BitmapDescriptor.bytes(png!.buffer.asUint8List(), width: 26, height: 26);
}

typedef MapMedal = ({TrackPoint at, int rank, String title});

class RouteMap extends ConsumerStatefulWidget {
  const RouteMap({
    super.key,
    required this.points,
    this.follow = false,
    this.interactive = false,
    this.here,
    this.medals = const [],
  });

  final List<TrackPoint> points;
  final bool follow;
  final bool interactive;
  final List<MapMedal> medals;

  final TrackPoint? here;

  @override
  ConsumerState<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends ConsumerState<RouteMap> {
  static const followZoom = 17.0;
  static BitmapDescriptor? _startDot;
  static BitmapDescriptor? _endDot;

  GoogleMapController? _map;
  bool _ready = false;
  bool _coverGone = false;

  LatLng? get _target {
    if (widget.here case final h?) return LatLng(h.lat, h.lng);
    if (widget.points.lastOrNull case final t?) return LatLng(t.lat, t.lng);
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (_startDot == null || _endDot == null) _loadDots();
    if (widget.medals.isNotEmpty) _loadMedals();
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  Future<void> _loadMedals() async {
    for (final m in widget.medals) {
      await mapMedal(m.rank);
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadDots() async {
    _startDot ??= await mapDot(Metric.startDot);
    _endDot ??= await mapDot(const Color(0xFF0E1018));
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(RouteMap old) {
    super.didUpdateWidget(old);
    if (widget.medals.length != old.medals.length) _loadMedals();
    if (widget.follow) {
      final t = _target;
      if (t != null && (old.here != widget.here || old.points.lastOrNull != widget.points.lastOrNull)) {
        _map?.animateCamera(CameraUpdate.newLatLng(t));
      }
    } else if (old.points.length != widget.points.length) {
      _frame();
    }
  }

  void _onCreated(GoogleMapController c) {
    _map = c;
    waitForTiles(c).then((_) {
      if (mounted) setState(() => _ready = true);
    });
    if (!widget.follow) Future<void>.delayed(const Duration(milliseconds: 300), _frame);
  }

  void _frame() {
    final pts = widget.points;
    if (!mounted || _map == null || pts.length < 2) return;
    var (s, w, n, e) = (pts.first.lat, pts.first.lng, pts.first.lat, pts.first.lng);
    for (final p in pts) {
      if (p.lat < s) s = p.lat;
      if (p.lat > n) n = p.lat;
      if (p.lng < w) w = p.lng;
      if (p.lng > e) e = p.lng;
    }
    _map!.moveCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: LatLng(s, w), northeast: LatLng(n, e)), 40));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final target = _target;
    if (!ref.watch(mapTilesProvider)) return ColoredBox(color: p.mapBg);
    if (target == null) return const MapLoading();
    final line = [for (final t in widget.points) LatLng(t.lat, t.lng)];
    final interactive = widget.interactive;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.follow ? target : line.firstOrNull ?? target,
              zoom: widget.follow ? followZoom : 16,
            ),
            onMapCreated: _onCreated,
            mapType: MapType.hybrid,
            myLocationEnabled: widget.follow && widget.here != null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            buildingsEnabled: false,
            indoorViewEnabled: false,
            trafficEnabled: false,
            zoomGesturesEnabled: interactive,
            scrollGesturesEnabled: interactive,
            rotateGesturesEnabled: interactive,
            tiltGesturesEnabled: interactive,
            padding: widget.follow ? EdgeInsets.zero : const EdgeInsets.fromLTRB(0, 40, 0, 30),
            polylines: {
              if (line.length >= 2) ...{
                Polyline(
                  polylineId: const PolylineId('halo'),
                  points: line,
                  width: 9,
                  color: Colors.white.withValues(alpha: 0.7),
                  jointType: JointType.round,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                ),
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: line,
                  width: 5,
                  color: Metric.cta.last,
                  jointType: JointType.round,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                  zIndex: 1,
                ),
              },
            },
            markers: {
              if (line.isNotEmpty && _startDot != null)
                Marker(
                  markerId: const MarkerId('start'),
                  position: line.first,
                  icon: _startDot!,
                  anchor: const Offset(0.5, 0.5),
                ),
              if (line.length > 1 && !widget.follow && _endDot != null)
                Marker(
                  markerId: const MarkerId('end'),
                  position: line.last,
                  icon: _endDot!,
                  anchor: const Offset(0.5, 0.5),
                ),
              for (final (i, m) in widget.medals.indexed)
                if (_medals[m.rank] case final icon?)
                  Marker(
                    markerId: MarkerId('medal_$i'),
                    position: LatLng(m.at.lat, m.at.lng),
                    icon: icon,
                    anchor: const Offset(0.5, 0.5),
                    zIndexInt: 2,
                    infoWindow: InfoWindow(title: m.title, snippet: 'Lifetime'),
                  ),
            },
          ),
        ),
        if (!_coverGone) MapCover(ready: _ready, onGone: () => setState(() => _coverGone = true)),
      ],
    );
  }
}
