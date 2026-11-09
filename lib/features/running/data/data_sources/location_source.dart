import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/track_point.dart';

enum LocationProblem { serviceOff, denied, deniedForever }

abstract interface class LocationSource {
  Future<LocationProblem?> ensureAccess();

  Future<TrackPoint?> current();

  Stream<TrackPoint> fixes({double maxAccuracyM = 25, bool background = false});

  Future<void> openSettings();
}

class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource();

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
    if (last != null) return _point(last);
    try {
      return _point(
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<TrackPoint> fixes({double maxAccuracyM = 25, bool background = false}) =>
      Geolocator.getPositionStream(locationSettings: _settings(background))
          .where((p) => p.accuracy <= maxAccuracyM)
          .map(
            (p) =>
                TrackPoint(lat: p.latitude, lng: p.longitude, alt: p.altitude, t: p.timestamp.millisecondsSinceEpoch),
          );

  static LocationSettings _settings(bool background) {
    if (!background) return const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 3);
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Recording your run',
          notificationText: 'Active Tracker keeps recording while the screen is off.',
          notificationChannelName: 'Run recording',
          enableWakeLock: true,
          setOngoing: true,
        ),
      ),
      TargetPlatform.iOS => AppleSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      ),
      _ => const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 3),
    };
  }

  @override
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }
}
