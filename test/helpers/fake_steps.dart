import 'dart:async';

import 'package:active_tracker/features/running/data/data_sources/step_source.dart';

class FakeSteps implements StepSource {
  FakeSteps({this.allowed = false});

  bool allowed;
  final controller = StreamController<int>.broadcast();

  @override
  Future<bool> ensureAccess() async => allowed;

  @override
  Stream<int> steps() => controller.stream;
}
