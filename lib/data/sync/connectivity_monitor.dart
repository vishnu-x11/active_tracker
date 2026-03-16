import 'package:connectivity_plus/connectivity_plus.dart';

/// Monitors device connectivity status
class ConnectivityMonitor {
  static final ConnectivityMonitor _instance = ConnectivityMonitor._internal();

  final Connectivity _connectivity = Connectivity();

  bool _isOnline = true;

  factory ConnectivityMonitor() {
    return _instance;
  }

  ConnectivityMonitor._internal();

  /// Initialize connectivity monitoring
  Future<void> init() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;
      print('✅ Connectivity Monitor initialized. Online: $_isOnline');

      // Listen for changes
      _connectivity.onConnectivityChanged.listen((result) {
        _isOnline = result != ConnectivityResult.none;
        print('🔄 Connectivity changed. Online: $_isOnline');
        _onConnectivityChanged();
      });
    } catch (e) {
      print('❌ Error initializing connectivity monitor: $e');
      _isOnline = true; // Assume online on error
    }
  }

  /// Check if device is online
  bool get isOnline => _isOnline;

  /// Get future that completes when online
  Future<void> waitForConnection() async {
    if (_isOnline) return;

    // Wait until online
    while (!_isOnline) {
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  /// Called when connectivity changes
  void _onConnectivityChanged() {
    // Trigger sync when connection is restored
    if (_isOnline) {
      print('📡 Connection restored - triggering sync');
      // Sync will be triggered by SyncManager listener
    }
  }
}