/// Browser-only features (speech synthesis, local storage) behind a
/// conditional import, so the game logic can also run in VM tests.
library;

export 'browser_services_stub.dart'
  if (dart.library.js_interop) 'browser_services_web.dart';
