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
  List<Map<dynamic, dynamic>> _pendingOutbox = [];
  bool _isSyncingOutbox = false;

  // ── Public Getters ─────────────────────────────────────────────────────────
  bool get isInitialized => _isInitialized;
  RepositoryState get state => _state;
  bool get simulateNetworkError => _simulateNetworkError;
  int get networkDelaySeconds => _networkDelaySeconds;
  List<String> get eventLog => List.unmodifiable(_eventLog);
  List<Map<dynamic, dynamic>> get pendingOutbox => List.unmodifiable(_pendingOutbox);
  int get pendingOutboxCount => _pendingOutbox.length;
  bool get isSyncingOutbox => _isSyncingOutbox;

  // ── INITIALIZATION ─────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _repo.initialize();
    _pendingOutbox = _repo.getPendingOutbox();
    _isInitialized = true;
    _addLog('SYSTEM', 'Repository initialized. Hive boxes opened.');
    _addLog('SYSTEM',
        'Cache status: ${_repo.hasCachedData ? "HIT — cached data found" : "MISS — no cache yet"}');
    _addLog('SYSTEM', 'Outbox status: ${_pendingOutbox.isEmpty ? "Empty" : "${_pendingOutbox.length} pending actions"}');
    notifyListeners();
  }

  // ── FETCH PRODUCTS (starts the cache-first stream) ─────────────────────────
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
            _pendingOutbox = _repo.getPendingOutbox();

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

  // ── FAVORITE & OUTBOX ACTIONS ──────────────────────────────────────────────
  Future<void> toggleFavorite(int productId) async {
    _addLog('ACTION', 'toggleFavorite(productId: $productId) called');

    // 1. Trigger write to Hive cache and add to outbox
    await _repo.toggleFavoriteOffline(productId);

    // 2. Perform Optimistic UI Update directly on local state
    _pendingOutbox = _repo.getPendingOutbox();
    final updatedList = _state.products.map((p) {
      if (p.id == productId) {
        final newVal = !p.isFavorite;
        _addLog('CACHE', 'Optimistic cache write: Product $productId isFavorite → $newVal. Action queued to outbox.');
        return p.copyWith(isFavorite: newVal);
      }
      return p;
    }).toList();

    _state = _state.copyWith(products: updatedList);
    notifyListeners();

    // 3. Auto-trigger background outbox synchronization
    await syncPendingOutbox();
  }

  Future<void> syncPendingOutbox() async {
    if (_isSyncingOutbox) return;
    final queue = _repo.getPendingOutbox();
    if (queue.isEmpty) return;

    _isSyncingOutbox = true;
    _addLog('SYNC', 'Starting sync of ${queue.length} pending actions in outbox...');
    notifyListeners();

    try {
      await _repo.syncOutbox(_simulateNetworkError);
      _pendingOutbox = _repo.getPendingOutbox();
      _addLog('SYNC', 'Sync successful. Outbox queue synchronized and cleared.');
    } catch (e) {
      _pendingOutbox = _repo.getPendingOutbox();
      _addLog('ERROR', 'Sync failed: ${e.toString().replaceFirst('Exception: ', '')}. Items remain in Outbox.');
    } finally {
      _isSyncingOutbox = false;
      notifyListeners();
    }
  }

  // ── CLEAR CACHE ─────────────────────────────────────────────────────────────
  Future<void> clearCache() async {
    await _repo.clearCache();
    _state = const RepositoryState();
    _pendingOutbox = [];
    _addLog('CACHE', 'Hive cache and sync outbox cleared.');
    notifyListeners();
  }

  // ── TOGGLE CONTROLS ────────────────────────────────────────────────────────
  void toggleSimulateError() {
    _simulateNetworkError = !_simulateNetworkError;
    _addLog('CONFIG',
        'simulateNetworkError → $_simulateNetworkError. '
        'Next fetch/sync will ${_simulateNetworkError ? "FAIL" : "SUCCEED"}');
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
