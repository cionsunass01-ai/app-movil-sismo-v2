// Web implementation accessing window.aguacionMapStatus

import 'dart:js_interop' as js;

@js.JS()
extension type AguacionMapStatusJs(js.JSObject _) implements js.JSObject {
  external js.JSBoolean? get isReady;
  external js.JSBoolean? get isLoading;
  external js.JSNumber? get progress;
  external js.JSString? get source;
}

@js.JS('aguacionMapStatus')
external AguacionMapStatusJs? get _aguacionMapStatus;

class WebMapStorageStatusImpl {
  static bool get isReady {
    try {
      return _aguacionMapStatus?.isReady?.toDart ?? false;
    } catch (_) {
      return false;
    }
  }

  static bool get isLoading {
    try {
      return _aguacionMapStatus?.isLoading?.toDart ?? false;
    } catch (_) {
      return false;
    }
  }

  static int get progress {
    try {
      return _aguacionMapStatus?.progress?.toDartInt ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static String get source {
    try {
      return _aguacionMapStatus?.source?.toDart ?? 'none';
    } catch (_) {
      return 'none';
    }
  }
}
