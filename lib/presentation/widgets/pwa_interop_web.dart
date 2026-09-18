// Web implementation of PWA interop using dart:js_interop

import 'dart:js_interop' as js;

@js.JS('promptPwaInstall')
external js.JSPromise<js.JSString> _promptPwaInstall();

@js.JS('isPwaStandalone')
external js.JSBoolean _isPwaStandalone();

Future<String> pwaPromptInstall() async {
  try {
    final promise = _promptPwaInstall();
    final result = await promise.toDart;
    return result.toDart;
  } catch (_) {
    return 'not_supported';
  }
}

bool pwaIsStandalone() {
  try {
    return _isPwaStandalone().toDart;
  } catch (_) {
    return false;
  }
}
