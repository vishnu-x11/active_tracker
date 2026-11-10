import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/track_point.dart';

enum LocationProblem { serviceOff, denied, deniedForever }

class GpsFix {
  const GpsFix(this.point, {this.accuracy = 0, this.speed = 0});

  final TrackPoint point;
  final double accuracy;
  final double speed;
}

abstract interface class LocationSource {
  Future<LocationProblem?> ensureAccess();

  Future<TrackPoint?> current();

  Stream<GpsFix> fixes({bool background = false});

  Future<void> openSettings();
}

class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource();

  static const _freshFor = Duration(minutes: 2);

  @override
  Future<LocationProblem?> ensureAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationProblem.serviceOff;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    return switch (p) {
      LocationPermission.denied || LocationPermission.unableToDetermine => LocationProblem.denied,
      LocationPermission.deniedForever => LocationProblem.deniedForever,
      _ => null,
    };
  }

  static TrackPoint _point(Position p) =>
      TrackPoint(lat: p.latitude, lng: p.longitude, alt: p.altitude, t: p.timestamp.millisecondsSinceEpoch);

  @override
  Future<TrackPoint?> current() async {
    final last = await Geolocator.getLastKnownPosition();
    if (last != null && DateTime.now().difference(last.timestamp) < _freshFor && last.accuracy <= 50) {
      return _point(last);
    }
    try {
      return _point(
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 20)),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<GpsFix> fixes({bool background = false}) => Geolocator.getPositionStream(
    locationSettings: _settings(background),
  ).map((p) => GpsFix(_point(p), accuracy: p.accuracy, speed: p.speed < 0 ? 0 : p.speed));

  static LocationSettings _settings(bool background) => switch (defaultTargetPlatform) {
    TargetPlatform.android => AndroidSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
      intervalDuration: const Duration(seconds: 1),
      foregroundNotificationConfig: background
          ? const ForegroundNotificationConfig(
              notificationTitle: 'Recording your run',
              notificationText: 'Active Tracker keeps recording while the screen is off.',
              notificationChannelName: 'Run recording',
              enableWakeLock: true,
              setOngoing: true,
            )
          : null,
    ),
    TargetPlatform.iOS => AppleSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
      activityType: ActivityType.fitness,
      pauseLocationUpdatesAutomatically: false,
      allowBackgroundLocationUpdates: background,
      showBackgroundLocationIndicator: background,
    ),
    _ => const LocationSettings(accuracy: LocationAccuracy.best),
  };

  @override
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }
}
