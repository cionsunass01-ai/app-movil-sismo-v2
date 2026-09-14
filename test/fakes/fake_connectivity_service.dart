import 'dart:async';
import 'package:aguacion_app/core/services/connectivity_service.dart';

class FakeConnectivityService implements ConnectivityService {
  NetworkState _state;
  final StreamController<NetworkState> _controller =
      StreamController<NetworkState>.broadcast(sync: true);
  bool _initialized = false;

  FakeConnectivityService([this._state = NetworkState.connected]);

  @override
  NetworkState get currentNetworkState => _state;

  @override
  bool get isConnected => _state == NetworkState.connected;

  @override
  Stream<NetworkState> get onConnectivityChanged => _controller.stream;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    _initialized = true;
    _controller.add(_state);
  }

  void emit(NetworkState newState) {
    _state = newState;
    _controller.add(newState);
  }

  @override
  void dispose() {
    _controller.close();
  }
}
