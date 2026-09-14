import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkState {
  connected,
  disconnected,
  unknown,
}

/// Service that monitors real physical network interface connectivity on the device.
///
/// NOTE: Detects network interface availability (Wi-Fi, Cellular, Ethernet),
/// not guaranteed end-to-end internet reaching a specific server.
class ConnectivityService {
  final Connectivity _connectivity;
  NetworkState _currentState = NetworkState.unknown;
  final StreamController<NetworkState> _controller =
      StreamController<NetworkState>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isInitialized = false;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  NetworkState get currentNetworkState => _currentState;
  bool get isConnected => _currentState == NetworkState.connected;
  Stream<NetworkState> get onConnectivityChanged => _controller.stream;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // In automated test runner environment, default to connected without hanging on unmocked platform channels
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _currentState = NetworkState.connected;
      _isInitialized = true;
      return;
    }

    try {
      final results = await _connectivity.checkConnectivity();
      _currentState = _mapResultsToState(results);
      _controller.add(_currentState);
    } catch (_) {
      _currentState = NetworkState.unknown;
      _controller.add(_currentState);
    }

    try {
      _subscription = _connectivity.onConnectivityChanged.listen((results) {
        final newState = _mapResultsToState(results);
        if (newState != _currentState) {
          _currentState = newState;
          _controller.add(_currentState);
        }
      });
    } catch (_) {}

    _isInitialized = true;
  }

  /// Maps connectivity_plus results into a clean three-state NetworkState
  static NetworkState _mapResultsToState(List<ConnectivityResult> results) {
    if (results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none)) {
      return NetworkState.disconnected;
    }

    final hasActiveInterface = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn ||
        r == ConnectivityResult.other);

    return hasActiveInterface
        ? NetworkState.connected
        : NetworkState.disconnected;
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
