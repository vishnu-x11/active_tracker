import 'package:active_tracker/features/running/data/data_sources/speaker.dart';

class FakeSpeaker implements Speaker {
  final said = <String>[];

  @override
  Future<void> say(String text) async => said.add(text);

  @override
  Future<void> stop() async {}
}
