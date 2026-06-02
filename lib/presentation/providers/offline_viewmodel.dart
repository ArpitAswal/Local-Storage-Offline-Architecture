// =============================================================================
// offline_viewmodel.dart
// =============================================================================
// PURPOSE: MVVM ViewModel for the Offline-First demo screens.
//
// RESPONSIBILITIES:
//   • Holds the current RepositoryState and exposes it to the UI
//   • Delegates all data operations to ProductRepository
//   • Maintains an event log for the educational console
//   • Exposes toggle controls (simulate error, network delay)
//
// FLOW:
//   UI tap → ViewModel method → Repository stream → ViewModel updates state
//   → notifyListeners() → UI rebuilds
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/services/offline_repository.dart';

class OfflineViewModel extends ChangeNotifier {
  final ProductRepository _repo = ProductRepository();

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isInitialized = false;
  RepositoryState _state = const RepositoryState();
  bool _simulateNetworkError = false;
  int _networkDelaySeconds = 2;
  final List<String> _eventLog = [];
  StreamSubscription<RepositoryState>? _repoSub;

  // ── Public Getters ─────────────────────────────────────────────────────────
  bool get isInitialized => _isInitialized;
  RepositoryState get state => _state;
  bool get simulateNetworkError => _simulateNetworkError;
  int get networkDelaySeconds => _networkDelaySeconds;
  List<String> get eventLog => List.unmodifiable(_eventLog);

  // ── INITIALIZATION ─────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _repo.initialize();
    _isInitialized = true;
    _addLog('SYSTEM', 'Repository initialized. Hive box opened.');
    _addLog('SYSTEM',
        'Cache status: ${_repo.hasCachedData ? "HIT — cached data found" : "MISS — no cache yet"}');
    notifyListeners();
  }

  // ── FETCH PRODUCTS (starts the cache-first stream) ─────────────────────────
  //
  // FLOW ANNOTATION:
  //   1. Cancel any previous stream subscription (avoid double-fetch)
  //   2. Subscribe to repo.getProducts() — an async* Stream
  //   3. First event arrives instantly (cache emit)
  //   4. Second event arrives after network delay (network emit)
  void fetchProducts() {
    _repoSub?.cancel();
    _addLog('─────', '──────────────────────────────────');
    _addLog('ACTION', 'fetchProducts() called');
    _addLog('STREAM', 'Subscribing to repo.getProducts(simulateError: $_simulateNetworkError, delay: ${_networkDelaySeconds}s)');

    _repoSub = _repo
        .getProducts(
          simulateNetworkError: _simulateNetworkError,
          networkDelaySeconds: _networkDelaySeconds,
        )
        .listen(
          (state) {
            _state = state;

            if (state.networkStatus == NetworkStatus.loading) {
              if (state.source == DataSource.cache) {
                _addLog('YIELD ①',
                    'Cache HIT → ${state.products.length} products from Hive. '
                    'networkStatus=LOADING (background sync started)');
              } else {
                _addLog('YIELD ①',
                    'Cache MISS → empty state. '
                    'networkStatus=LOADING (background sync started)');
              }
            } else if (state.networkStatus == NetworkStatus.success) {
              _addLog('YIELD ②',
                  'Network SUCCESS → ${state.products.length} fresh products. '
                  'Cache updated. lastSync=${state.lastSyncTime?.toLocal().toString().split('.').first}');
            } else if (state.networkStatus == NetworkStatus.failure) {
              _addLog('YIELD ②',
                  'Network FAILURE → "${state.errorMessage}". '
                  'Showing stale cache (graceful degradation).');
            }

            notifyListeners();
          },
          onError: (e) {
            _addLog('ERROR', 'Unhandled stream error: $e');
            notifyListeners();
          },
        );
  }

  // ── CLEAR CACHE ─────────────────────────────────────────────────────────────
  Future<void> clearCache() async {
    await _repo.clearCache();
    _state = const RepositoryState();
    _addLog('CACHE', 'Hive cache cleared. box.delete(\"products_list\")');
    notifyListeners();
  }

  // ── TOGGLE CONTROLS ────────────────────────────────────────────────────────
  void toggleSimulateError() {
    _simulateNetworkError = !_simulateNetworkError;
    _addLog('CONFIG',
        'simulateNetworkError → $_simulateNetworkError. '
        'Next fetch will ${_simulateNetworkError ? "FAIL" : "SUCCEED"}');
    notifyListeners();
  }

  void setNetworkDelay(int seconds) {
    _networkDelaySeconds = seconds;
    _addLog('CONFIG', 'networkDelay → ${seconds}s');
    notifyListeners();
  }

  // ── LOG HELPER ─────────────────────────────────────────────────────────────
  void _addLog(String type, String message) {
    final now = DateTime.now();
    final t = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    _eventLog.insert(0, '[$t] $type: $message');
    notifyListeners();
  }

  void clearLog() {
    _eventLog.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _repoSub?.cancel();
    super.dispose();
  }
}
