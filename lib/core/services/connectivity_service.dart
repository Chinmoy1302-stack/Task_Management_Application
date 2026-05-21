import 'package:connectivity_plus/connectivity_plus.dart';

/// Checks device network connectivity for offline-first task operations.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Emits whenever the device connectivity changes.
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  Future<bool> get isOffline async {
    final results = await _connectivity.checkConnectivity();
    return isOfflineFromResults(results);
  }

  bool isOfflineFromResults(List<ConnectivityResult> results) {
    if (results.isEmpty) return true;
    return results.every((result) => result == ConnectivityResult.none);
  }
}
