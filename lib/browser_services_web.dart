import 'package:web/web.dart' as web;

void speak(String text) {
  try {
    web.window.speechSynthesis.cancel();
    final utterance = web.SpeechSynthesisUtterance(text)..lang = 'ru-RU'..rate = .91;
    web.window.speechSynthesis.speak(utterance);
  } catch (_) {
    // Some browsers do not expose speech synthesis.
  }
}

void stopSpeech() {
  try {
    web.window.speechSynthesis.cancel();
  } catch (_) {
    // Some browsers do not expose speech synthesis.
  }
}

String? readStorage(String key) {
  try {
    return web.window.localStorage.getItem(key);
  } catch (_) {
    // Storage may be unavailable (e.g. private mode).
    return null;
  }
}

void writeStorage(String key, String value) {
  try {
    web.window.localStorage.setItem(key, value);
  } catch (_) {
    // Progress simply won't persist.
  }
}
