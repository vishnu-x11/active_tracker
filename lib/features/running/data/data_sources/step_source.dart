import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

abstract interface class StepSource {
  Future<bool> ensureAccess();

  Stream<int> steps();
}

class PedometerStepSource implements StepSource {
  const PedometerStepSource();

  Permission get _permission =>
      defaultTargetPlatform == TargetPlatform.iOS ? Permission.sensors : Permission.activityRecognition;

  @override
  Future<bool> ensureAccess() async {
    try {
      final status = await _permission.status;
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied || status.isRestricted) return false;
      return (await _permission.request()).isGranted;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<int> steps() => Pedometer.stepCountStream.map((e) => e.steps);
}
