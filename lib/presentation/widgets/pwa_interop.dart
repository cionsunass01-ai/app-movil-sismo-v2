// Conditional import bridge for PWA interop

import 'pwa_interop_stub.dart'
    if (dart.library.js_interop) 'pwa_interop_web.dart';

Future<String> promptInstall() => pwaPromptInstall();

bool isStandalone() => pwaIsStandalone();
