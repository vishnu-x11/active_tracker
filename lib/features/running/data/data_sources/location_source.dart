import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/gps_fix.dart';
import '../../domain/entities/track_point.dart';

export '../../domain/entities/gps_fix.dart';

enum LocationProblem { serviceOff, denied, deniedForever }

abstract interface class LocationSource {
  Future<LocationProblem?> ensureAccess();

  Future<TrackPoint?> current();

  Stream<GpsFix> fixes({bool background = false, bool rawGps = false});

  Stream<bool> serviceEnabled();

  Future<GpsFix?> poll({bool rawGps = false});

  Future<bool> serviceOn();

  Future<void> openSettings();

  Future<void> openLocationSettings();
}

class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource();

  static const _freshFor = Duration(seconds: 30);
  static const _freshAccuracyM = 20;

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
    if (last != null && DateTime.now().difference(last.timestamp) < _freshFor && last.accuracy <= _freshAccuracyM) {
      return _point(last);
    }
    try {
      return _point(
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            timeLimit: Duration(seconds: 15),
          ),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<GpsFix> fixes({bool background = false, bool rawGps = false}) => Geolocator.getPositionStream(
    locationSettings: _settings(background, rawGps),
  ).map((p) => GpsFix(_point(p), accuracy: p.accuracy, speed: p.speed < 0 ? 0 : p.speed));

  static LocationSettings _settings(bool background, bool rawGps) => switch (defaultTargetPlatform) {
    TargetPlatform.android => AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      forceLocationManager: rawGps,
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
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      activityType: ActivityType.fitness,
      pauseLocationUpdatesAutomatically: false,
      allowBackgroundLocationUpdates: background,
      showBackgroundLocationIndicator: background,
    ),
    _ => const LocationSettings(accuracy: LocationAccuracy.best),
  };

  @override
  Future<GpsFix?> poll({bool rawGps = false}) async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: defaultTargetPlatform == TargetPlatform.android
            ? AndroidSettings(
                accuracy: LocationAccuracy.bestForNavigation,
                forceLocationManager: rawGps,
                timeLimit: const Duration(seconds: 8),
              )
            : const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, timeLimit: Duration(seconds: 8)),
      );
      return GpsFix(_point(p), accuracy: p.accuracy, speed: p.speed < 0 ? 0 : p.speed);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<bool> serviceEnabled() => Geolocator.getServiceStatusStream().map((s) => s == ServiceStatus.enabled);

  @override
  Future<bool> serviceOn() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
