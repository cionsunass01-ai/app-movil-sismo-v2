import 'web_map_storage_status_stub.dart'
    if (dart.library.js_interop) 'web_map_storage_status_web.dart';

class WebMapStorageStatus {
  static bool get isReady => WebMapStorageStatusImpl.isReady;
  static bool get isLoading => WebMapStorageStatusImpl.isLoading;
  static int get progress => WebMapStorageStatusImpl.progress;
  static String get source => WebMapStorageStatusImpl.source;
}
