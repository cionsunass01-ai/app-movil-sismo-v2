// Stub implementation for non-web platforms (Android, iOS)

class WebMapStorageStatusImpl {
  static bool get isReady => true;
  static bool get isLoading => false;
  static int get progress => 100;
  static String get source => 'native';
}
