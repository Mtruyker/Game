/// No-op fallback used outside the browser (e.g. in `flutter test`).
final Map<String, String> _memoryStorage = <String, String>{};

void speak(String text) {}

void stopSpeech() {}

String? readStorage(String key) => _memoryStorage[key];

void writeStorage(String key, String value) => _memoryStorage[key] = value;
