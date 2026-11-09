import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_palette.dart';
import '../../domain/entities/track_point.dart';

final mapTilesProvider = Provider<bool>((ref) => true);

class RouteMap extends ConsumerWidget {
  const RouteMap({super.key, required this.points, this.follow = false, this.interactive = false, this.here});

  final List<TrackPoint> points;
  final bool follow;
  final bool interactive;

  final TrackPoint? here;

  static const _fallback = LatLng(12.9716, 77.5946);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final showTiles = ref.watch(mapTilesProvider);
    final line = [for (final t in points) LatLng(t.lat, t.lng)];
    final me = here == null ? null : LatLng(here!.lat, here!.lng);
    final center = me ?? (line.isEmpty ? _fallback : line.last);
    final fit = !follow && line.length >= 2
        ? CameraFit.coordinates(coordinates: line, padding: const EdgeInsets.fromLTRB(40, 90, 40, 70))
        : null;
    return RepaintBoundary(
      child: ColoredBox(
        color: p.mapBg,
        child: FlutterMap(
          key: follow ? null : ValueKey(line.length),
          options: MapOptions(
            initialCenter: center,
            initialZoom: 16,
            initialCameraFit: fit,
            interactionOptions: InteractionOptions(flags: interactive ? InteractiveFlag.all : InteractiveFlag.none),
            backgroundColor: p.mapBg,
          ),
          children: [
            if (showTiles)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.active_tracker',
              ),
            if (line.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(points: line, strokeWidth: 9, color: Colors.white.withValues(alpha: 0.7)),
                  Polyline(points: line, strokeWidth: 5, color: Metric.burnDot),
                ],
              ),
            if (line.isNotEmpty)
              MarkerLayer(
                markers: [
                  Marker(
                    point: line.first,
                    width: 18,
                    height: 18,
                    child: const _Dot(color: Metric.startDot),
                  ),
                  if (line.length > 1 && me == null)
                    Marker(
                      point: line.last,
                      width: 18,
                      height: 18,
                      child: const _Dot(color: Color(0xFF0E1018)),
                    ),
                ],
              ),
            if (me != null)
              MarkerLayer(
                markers: [Marker(point: me, width: 26, height: 26, child: const _Here())],
              ),
            if (follow && (me != null || line.isNotEmpty)) _Follow(target: me ?? line.last),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
    ),
  );
}

class _Here extends StatelessWidget {
  const _Here();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Metric.waterDot,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: [BoxShadow(color: Metric.waterDot.withValues(alpha: 0.45), blurRadius: 12, spreadRadius: 4)],
    ),
  );
}

class _Follow extends StatefulWidget {
  const _Follow({required this.target});

  final LatLng target;

  @override
  State<_Follow> createState() => _FollowState();
}

class _FollowState extends State<_Follow> {
  @override
  void didUpdateWidget(_Follow old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target) {
      final camera = MapController.maybeOf(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) camera?.move(widget.target, camera.camera.zoom);
      });
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
