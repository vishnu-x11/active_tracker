import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  bool get restartsInBackground;

  Future<void> stopRecording();

  Future<void> openSettings();

  Future<void> openLocationSettings();
}

class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource();

  static const _service = MethodChannel('active_tracker/run_service');
  static final Stream<dynamic> _serviceEvents = const EventChannel('active_tracker/run_fixes').receiveBroadcastStream();

  static bool get _nativeRecorder => defaultTargetPlatform == TargetPlatform.android;

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

  static const _maxHeadingErrorDeg = 45.0;

  static GpsFix _fix(Position p) {
    final headingOk =
        p.hasHeading &&
        p.heading >= 0 &&
        (!p.hasHeadingAccuracy || p.headingAccuracy <= 0 || p.headingAccuracy <= _maxHeadingErrorDeg);
    return GpsFix(
      _point(p),
      accuracy: p.accuracy,
      speed: p.speed < 0 ? 0 : p.speed,
      heading: headingOk ? p.heading : null,
    );
  }

  @override
  bool get restartsInBackground => _nativeRecorder;

  @override
  Stream<GpsFix> fixes({bool background = false, bool rawGps = false}) {
    if (background && _nativeRecorder) return _recorderFixes(rawGps);
    return Geolocator.getPositionStream(locationSettings: _settings(background, rawGps)).map(_fix);
  }

  Stream<GpsFix> _recorderFixes(bool raw) {
    StreamSubscription<dynamic>? sub;
    late final StreamController<GpsFix> out;
    out = StreamController<GpsFix>(
      onListen: () async {
        sub = _serviceEvents.listen((e) {
          if (_fromMap(e) case final f?) out.add(f);
        }, onError: out.addError);
        try {
          final args = {'raw': raw};
          final listening = await _service.invokeMethod<bool>('listen', args) ?? false;
          if (listening) return;
          final started = await _service.invokeMethod<bool>('start', args) ?? false;
          if (!started && !out.isClosed) out.addError(StateError('Run recording service could not start'));
        } on PlatformException catch (e) {
          if (!out.isClosed) out.addError(e);
        }
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }

  static GpsFix? _fromMap(Object? e) {
    if (e is! Map) return null;
    final lat = e['lat'], lng = e['lng'], t = e['t'];
    if (lat is! num || lng is! num || t is! num) return null;
    final heading = e['heading'];
    final headingAcc = e['headingAcc'];
    final headingOk = heading is num && heading >= 0 && (headingAcc is! num || headingAcc <= _maxHeadingErrorDeg);
    final speed = e['speed'];
    final alt = e['alt'];
    return GpsFix(
      TrackPoint(lat: lat.toDouble(), lng: lng.toDouble(), alt: alt is num ? alt.toDouble() : null, t: t.toInt()),
      accuracy: (e['acc'] as num?)?.toDouble() ?? 999,
      speed: speed is num && speed > 0 ? speed.toDouble() : 0,
      heading: headingOk ? heading.toDouble() : null,
    );
  }

  @override
  Future<void> stopRecording() async {
    if (!_nativeRecorder) return;
    try {
      await _service.invokeMethod<void>('stop');
    } on PlatformException catch (_) {}
  }

  static LocationSettings _settings(bool background, bool rawGps) => switch (defaultTargetPlatform) {
    TargetPlatform.android => AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      forceLocationManager: rawGps,
      intervalDuration: const Duration(seconds: 1),
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
      return _fix(p);
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
