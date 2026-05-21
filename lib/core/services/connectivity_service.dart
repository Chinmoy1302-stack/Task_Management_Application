import 'package:connectivity_plus/connectivity_plus.dart';

/// Checks device network connectivity for offline-first task operations.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> get isOffline async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.none) || results.isEmpty;
  }
}
