import 'package:flutter_tts/flutter_tts.dart';

abstract interface class Speaker {
  Future<void> say(String text);

  Future<void> stop();
}

class TtsSpeaker implements Speaker {
  TtsSpeaker();

  FlutterTts? _tts;
  Future<void> _queue = Future.value();

  Future<FlutterTts> _engine() async {
    if (_tts case final t?) return t;
    final t = FlutterTts();
    await t.awaitSpeakCompletion(true);
    await t.setSpeechRate(0.5);
    await t.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
      IosTextToSpeechAudioCategoryOptions.duckOthers,
      IosTextToSpeechAudioCategoryOptions.interruptSpokenAudioAndMixWithOthers,
    ], IosTextToSpeechAudioMode.voicePrompt);
    return _tts = t;
  }

  @override
  Future<void> say(String text) => _queue = _queue.then((_) async {
    try {
      await (await _engine()).speak(text);
    } catch (_) {}
  });

  @override
  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}
