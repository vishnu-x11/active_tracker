import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_palette.dart';
import '../../domain/entities/track_point.dart';

final mapTilesProvider = Provider<bool>((ref) => true);

class RouteMap extends ConsumerStatefulWidget {
  const RouteMap({super.key, required this.points, this.follow = false, this.interactive = false, this.here});

  final List<TrackPoint> points;
  final bool follow;
  final bool interactive;

  final TrackPoint? here;

  @override
  ConsumerState<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends ConsumerState<RouteMap> {
  static BitmapDescriptor? _startDot;
  static BitmapDescriptor? _endDot;

  GoogleMapController? _map;

  LatLng? get _target {
    if (widget.here case final h?) return LatLng(h.lat, h.lng);
    if (widget.points.lastOrNull case final t?) return LatLng(t.lat, t.lng);
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (_startDot == null || _endDot == null) _loadDots();
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  Future<void> _loadDots() async {
    _startDot ??= await _dot(Metric.startDot);
    _endDot ??= await _dot(const Color(0xFF0E1018));
    if (mounted) setState(() {});
  }

  static Future<BitmapDescriptor> _dot(Color color) async {
    const px = 54;
    final recorder = ui.PictureRecorder();
    const c = Offset(px / 2, px / 2);
    Canvas(recorder)
      ..drawCircle(c, px / 2, Paint()..color = Colors.white)
      ..drawCircle(c, px / 2 - 9, Paint()..color = color);
    final image = await recorder.endRecording().toImage(px, px);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return BitmapDescriptor.bytes(png!.buffer.asUint8List(), width: 18, height: 18);
  }

  @override
  void didUpdateWidget(RouteMap old) {
    super.didUpdateWidget(old);
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
    if (!ref.watch(mapTilesProvider) || target == null) return ColoredBox(color: p.mapBg);
    final line = [for (final t in widget.points) LatLng(t.lat, t.lng)];
    final interactive = widget.interactive;
    return RepaintBoundary(
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: widget.follow ? target : line.firstOrNull ?? target, zoom: 16),
        onMapCreated: _onCreated,
        style: p.mapBg == AppPalette.dark.mapBg ? _darkStyle : null,
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
              color: Metric.burnDot,
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
        },
      ),
    );
  }
}

const _darkStyle = '''[
{"elementType":"geometry","stylers":[{"color":"#1e2422"}]},
{"elementType":"labels.text.fill","stylers":[{"color":"#8a948f"}]},
{"elementType":"labels.text.stroke","stylers":[{"color":"#1e2422"}]},
{"featureType":"poi","stylers":[{"visibility":"off"}]},
{"featureType":"transit","stylers":[{"visibility":"off"}]},
{"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c3431"}]},
{"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#222927"}]},
{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3a4440"}]},
{"featureType":"water","elementType":"geometry","stylers":[{"color":"#121816"}]},
{"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#1a2a22"}]}
]''';
