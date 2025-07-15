import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityService extends ChangeNotifier {
  bool _isConnected = true;
  bool _isChecking = false;

  bool get isConnected => _isConnected;
  bool get isChecking => _isChecking;

  // Singleton pattern
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  // Initialize connectivity monitoring
  Future<void> initialize() async {
    await checkConnectivity();
    // Start listening to connectivity changes
    InternetConnectionChecker.instance.onStatusChange.listen((status) {
      _isConnected = status == InternetConnectionStatus.connected;
      notifyListeners();
      debugPrint(
          'Connectivity changed: ${_isConnected ? 'Connected' : 'Disconnected'}');
    });
  }

  // Check current connectivity status
  Future<bool> checkConnectivity() async {
    _isChecking = true;
    notifyListeners();

    try {
      final result = await InternetConnectionChecker.instance.connectionStatus;
      _isConnected = result == InternetConnectionStatus.connected;

      // Also try a simple DNS lookup as backup
      if (_isConnected) {
        try {
          final lookupResult = await InternetAddress.lookup('google.com');
          _isConnected =
              lookupResult.isNotEmpty && lookupResult[0].rawAddress.isNotEmpty;
        } on SocketException catch (_) {
          _isConnected = false;
        }
      }
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isConnected = false;
    }

    _isChecking = false;
    notifyListeners();
    return _isConnected;
  }

  // Force refresh connectivity status
  Future<void> refreshConnectivity() async {
    await checkConnectivity();
  }
}
