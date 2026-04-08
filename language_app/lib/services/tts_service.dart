import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;

  static Future<void> init(String language) async {
    final locales = {
      'hindi': 'hi-IN',
      'marathi': 'mr-IN',
      'english': 'en-IN',
    };
    await _tts.setLanguage(locales[language] ?? 'hi-IN');
    await _tts.setSpeechRate(0.4);  // slow — better for learners
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  static Future<void> speak(String text) async {
    if (!_initialized) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  static Future<void> stop() async {
    await _tts.stop();
  }

  static void dispose() {
    _tts.stop();
  }
}