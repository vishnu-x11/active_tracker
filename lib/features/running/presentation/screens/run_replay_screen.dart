import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/formulas/formulas.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../domain/entities/run.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/use_cases/run_replay.dart';
import '../providers.dart';
import '../widgets/route_map.dart';

class RunReplayScreen extends ConsumerWidget {
  const RunReplayScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(runProvider(id)).value;
    final points = ref.watch(runTrackProvider(id)).value;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: run == null || points == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _Replay(run: run, points: points, tiles: ref.watch(mapTilesProvider)),
    );
  }
}

class _Replay extends StatefulWidget {
  const _Replay({required this.run, required this.points, required this.tiles});

  final Run run;
  final List<TrackPoint> points;
  final bool tiles;

  @override
  State<_Replay> createState() => _ReplayState();
}

class _ReplayState extends State<_Replay> with SingleTickerProviderStateMixin {
  static const mapEveryMs = 100;
  static const tilt = 60.0;
  static const minZoom = 13.0;
  static const maxZoom = 18.0;

  late final RunReplay _replay = RunReplay(widget.points);
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: _replay.duration())
    ..addListener(_onFrame)
    ..addStatusListener((s) => setState(() {}));
  late final List<LatLng> _line = [for (final p in widget.points) LatLng(p.lat, p.lng)];

  GoogleMapController? _map;
  BitmapDescriptor? _headDot;
  BitmapDescriptor? _startDot;
  int _lastMapMs = 0;
  List<LatLng> _drawn = const [];
  LatLng? _head;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDots());
    if (_replay.playable) _ctrl.forward();
  }

  Future<void> _loadDots() async {
    final head = await mapDot(Colors.white, edge: const Color(0xFF0E1018), size: 20);
    final start = await mapDot(Metric.startDot);
    if (!mounted) return;
    setState(() {
      _headDot = head;
      _startDot = start;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _map?.dispose();
    super.dispose();
  }

  LatLngBounds get _bounds {
    final pts = widget.points;
    var (s, w, n, e) = (pts.first.lat, pts.first.lng, pts.first.lat, pts.first.lng);
    for (final p in pts) {
      if (p.lat < s) s = p.lat;
      if (p.lat > n) n = p.lat;
      if (p.lng < w) w = p.lng;
      if (p.lng > e) e = p.lng;
    }
    return LatLngBounds(southwest: LatLng(s, w), northeast: LatLng(n, e));
  }

  static double _latRad(double lat) {
    final sin = math.sin(lat * math.pi / 180);
    return math.log((1 + sin) / (1 - sin)) / 2;
  }

  CameraPosition _camera(Size size) {
    final b = _bounds;
    final latSpan = (_latRad(b.northeast.latitude) - _latRad(b.southwest.latitude)) / math.pi;
    final lngSpan = ((b.northeast.longitude - b.southwest.longitude) % 360) / 360;
    double fit(double px, double fraction) => fraction <= 0 ? maxZoom : math.log(px * 0.6 / 256 / fraction) / math.ln2;
    final zoom = math.min(fit(size.width, lngSpan), fit(size.height, latSpan)).clamp(minZoom, maxZoom);
    final span = b.northeast.latitude - b.southwest.latitude;
    return CameraPosition(
      target: LatLng(
        (b.northeast.latitude + b.southwest.latitude) / 2 + span * 0.12,
        (b.northeast.longitude + b.southwest.longitude) / 2,
      ),
      zoom: zoom,
      tilt: tilt,
    );
  }

  void _onFrame() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final finished = _ctrl.status == AnimationStatus.completed;
    if (!finished && now - _lastMapMs < mapEveryMs) return;
    _lastMapMs = now;
    final f = _replay.at(_ctrl.value);
    final head = LatLng(f.lat, f.lng);
    setState(() {
      _head = head;
      _drawn = finished ? _line : [..._line.take(f.index), head];
    });
  }

  Polyline _polyline(String id, List<LatLng> pts, {required Color color, required int width, int z = 0}) => Polyline(
    polylineId: PolylineId(id),
    points: pts,
    width: width,
    color: color,
    jointType: JointType.round,
    startCap: Cap.roundCap,
    endCap: Cap.roundCap,
    zIndex: z,
  );

  void _toggle() {
    if (_ctrl.isAnimating) {
      _ctrl.stop();
    } else if (_ctrl.status == AnimationStatus.completed) {
      _ctrl.forward(from: 0);
    } else {
      _ctrl.forward();
    }
    setState(() {});
  }

  void _seek(double v) {
    _ctrl.value = v.clamp(0.0, 1.0);
    _lastMapMs = 0;
    _onFrame();
  }

  @override
  Widget build(BuildContext context) {
    final line = _line;
    final playing = _ctrl.isAnimating;
    return Stack(
      children: [
        Positioned.fill(
          child: widget.tiles && line.isNotEmpty
              ? LayoutBuilder(
                  builder: (context, c) => GoogleMap(
                    initialCameraPosition: _camera(c.biggest),
                    mapType: MapType.hybrid,
                    onMapCreated: (m) => _map = m,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    buildingsEnabled: true,
                    tiltGesturesEnabled: true,
                    polylines: {
                      if (line.length >= 2)
                        _polyline('ghost', line, color: Colors.white.withValues(alpha: 0.35), width: 4),
                      if (_drawn.length >= 2) _polyline('route', _drawn, color: Metric.burnDot, width: 7, z: 1),
                    },
                    markers: {
                      if (_startDot != null)
                        Marker(
                          markerId: const MarkerId('start'),
                          position: line.first,
                          icon: _startDot!,
                          anchor: const Offset(0.5, 0.5),
                          zIndexInt: 1,
                        ),
                      if (_headDot != null && _head != null)
                        Marker(
                          markerId: const MarkerId('head'),
                          position: _head!,
                          icon: _headDot!,
                          anchor: const Offset(0.5, 0.5),
                          zIndexInt: 2,
                        ),
                    },
                  ),
                )
              : const ColoredBox(color: Color(0xFF16231B)),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xE60B1220), Color(0x990B1220), Color(0x000B1220)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    final f = _replay.at(_ctrl.value);
                    return Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppLogo(size: 26),
                            SizedBox(width: 8),
                            Text(
                              'ACTIVE TRACKER',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.run.title,
                          style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _Stat(
                              label: 'Pace',
                              value: f.paceSecPerKm == null ? '–:––' : formatPace(f.paceSecPerKm!),
                              unit: '/km',
                            ),
                            _Stat(label: 'Distance', value: (f.meters / 1000).toStringAsFixed(2), unit: 'km'),
                            _Stat(
                              label: 'Elevation',
                              value: f.altitude == null ? '–' : '${f.altitude!.round()}',
                              unit: 'm',
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xE60B1220), Color(0x000B1220)],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                child: Row(
                  children: [
                    _RoundButton(icon: Icons.close_rounded, tooltip: 'Close', onTap: () => context.pop()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _ctrl,
                        builder: (context, _) => _Scrubber(value: _ctrl.value, onSeek: _seek),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _RoundButton(
                      icon: playing
                          ? Icons.pause_rounded
                          : (_ctrl.status == AnimationStatus.completed
                                ? Icons.replay_rounded
                                : Icons.play_arrow_rounded),
                      tooltip: playing ? 'Pause' : 'Play',
                      onTap: _replay.playable ? _toggle : null,
                      filled: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      container: true,
      label: '$label $value $unit',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            label,
            style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: Colors.white70),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppText.display.copyWith(
                fontSize: 32,
                color: Colors.white,
                fontFeatures: AppText.number.fontFeatures,
              ),
            ),
          ),
          Text(
            unit,
            style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    ),
  );
}

class _Scrubber extends StatelessWidget {
  const _Scrubber({required this.value, required this.onSeek});

  final double value;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      void at(Offset local) => onSeek(local.dx / c.maxWidth);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => at(d.localPosition),
        onHorizontalDragUpdate: (d) => at(d.localPosition),
        child: SizedBox(
          height: 44,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 5,
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Metric.burnDot),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onTap, this.filled = false});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: filled ? Colors.white : Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: 52,
          child: Icon(icon, size: 28, color: filled ? const Color(0xFF0E1018) : Colors.white),
        ),
      ),
    ),
  );
}
