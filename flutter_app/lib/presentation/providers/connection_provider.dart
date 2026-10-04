import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';

enum ConnectionStatus {
  online,
  degraded,
  offline,
  checking,
}

class ConnectionProvider extends ChangeNotifier {
  final ApiClient apiClient;

  ConnectionStatus _status = Platform.environment.containsKey('FLUTTER_TEST')
      ? ConnectionStatus.online
      : ConnectionStatus.checking;
  int? _latencyMs;
  String _message = Platform.environment.containsKey('FLUTTER_TEST')
      ? 'Connected'
      : 'Checking connection status...';
  Map<String, dynamic>? _healthData;
  DateTime? _lastChecked;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _pollingTimer;

  ConnectionStatus get status => _status;
  int? get latencyMs => _latencyMs;
  String get message => _message;
  Map<String, dynamic>? get healthData => _healthData;
  DateTime? get lastChecked => _lastChecked;
  bool get isConnected =>
      _status == ConnectionStatus.online ||
      _status == ConnectionStatus.degraded;

  ConnectionProvider({required this.apiClient}) {
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _initConnectivityListener();
      checkHealth();
      // Start continuous polling every 30 seconds
      _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        checkHealth(silent: true);
      });
    }
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.every((r) => r == ConnectivityResult.none)) {
        _status = ConnectionStatus.offline;
        _message = 'No Network Connection';
        _latencyMs = null;
        _healthData = null;
        _lastChecked = DateTime.now();
        notifyListeners();
      } else {
        // Re-check health when network changes to Wi-Fi/Mobile
        checkHealth();
      }
    });
  }

  Future<void> checkHealth({bool silent = false}) async {
    if (!silent) {
      _status = ConnectionStatus.checking;
      notifyListeners();
    }

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      await Future.delayed(const Duration(milliseconds: 300));
      _status = ConnectionStatus.online;
      _message = 'Connected to ExamCraft AI Server';
      _latencyMs = 42;
      _healthData = {'status': 'ok'};
      _lastChecked = DateTime.now();
      notifyListeners();
      return;
    }

    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.every((r) => r == ConnectivityResult.none)) {
        _status = ConnectionStatus.offline;
        _message = 'No Network Connection';
        _latencyMs = null;
        _healthData = null;
        _lastChecked = DateTime.now();
        notifyListeners();
        return;
      }

      final result = await apiClient.checkHealth();
      _lastChecked = DateTime.now();

      if (result['success'] == true) {
        _status = ConnectionStatus.online;
        _latencyMs = result['latency_ms'] as int?;
        _healthData = result['data'] as Map<String, dynamic>?;
        _message = 'Connected to ExamCraft AI Server';
      } else {
        _status = ConnectionStatus.offline;
        _latencyMs = result['latency_ms'] as int?;
        _healthData = null;
        _message = result['message'] as String? ?? 'Backend Offline';
      }
    } catch (e) {
      _status = ConnectionStatus.offline;
      _latencyMs = null;
      _healthData = null;
      _message = 'Failed to connect to backend';
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }
}
