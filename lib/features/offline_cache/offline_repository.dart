// =============================================================================
// offline_repository.dart
// =============================================================================
// PURPOSE: Demonstrates the Offline-First Repository Pattern.
//
// ARCHITECTURE:
//   UI ──► ViewModel ──► Repository ──► [Cache (Hive) + Remote API (mock)]
//
// PATTERN: Cache-First with Background Refresh
//   1. yield cached data immediately (user sees content instantly)
//   2. fetch from "network" in background
//   3. yield fresh data and update cache
//   4. On network failure, yield the stale cache (graceful degradation)
//
// This exact pattern is used in:
//   • Spotify  — shows playlists from cache before network loads
//   • Gmail    — shows last emails from cache, syncs in background
//   • Instagram— shows cached feed instantly while refreshing
//   • Uber     — shows last map state while live data loads
//
// PACKAGES USED:
//   hive       — local cache (NoSQL box)
//   dart:async — async* generator (Stream with multiple yield events)
// =============================================================================

import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL: Product
//
// Represents a product fetched from a remote API.
// In a production app, this would be annotated with @JsonSerializable.
// We store it in Hive as a JSON string (Map) — no TypeAdapter needed.
// ─────────────────────────────────────────────────────────────────────────────
class Product {
  final int id;
  final String name;
  final String category;
  final double price;
  final double rating;
  final int stock;
  final bool isNew;
  final String description;
  final bool isFavorite;
  final String source; // 'cache' or 'network'

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.stock,
    required this.isNew,
    required this.description,
    this.isFavorite = false,
    this.source = 'network',
  });

  // Serialize to JSON Map for Hive storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'rating': rating,
        'stock': stock,
        'isNew': isNew,
        'description': description,
        'isFavorite': isFavorite,
      };

  // Deserialise from Hive JSON Map
  factory Product.fromJson(Map<dynamic, dynamic> json, {String source = 'cache'}) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      stock: json['stock'] as int,
      isNew: json['isNew'] as bool,
      description: json['description'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      source: source,
    );
  }

  Product copyWith({String? source, bool? isFavorite}) => Product(
        id: id,
        name: name,
        category: category,
        price: price,
        rating: rating,
        stock: stock,
        isNew: isNew,
        description: description,
        isFavorite: isFavorite ?? this.isFavorite,
        source: source ?? this.source,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// REPOSITORY STATE
// Wraps the data + metadata about where it came from and whether
// a network request is in progress or failed.
// ─────────────────────────────────────────────────────────────────────────────
enum DataSource { cache, network, empty }
enum NetworkStatus { idle, loading, success, failure }

class RepositoryState {
  final List<Product> products;
  final DataSource source;
  final NetworkStatus networkStatus;
  final String? errorMessage;
  final DateTime? lastSyncTime;

  const RepositoryState({
    this.products = const [],
    this.source = DataSource.empty,
    this.networkStatus = NetworkStatus.idle,
    this.errorMessage,
    this.lastSyncTime,
  });

  bool get hasCache => products.isNotEmpty && source == DataSource.cache;
  bool get hasNetworkData => products.isNotEmpty && source == DataSource.network;
  bool get isEmpty => products.isEmpty;
  bool get isLoading => networkStatus == NetworkStatus.loading;

  RepositoryState copyWith({
    List<Product>? products,
    DataSource? source,
    NetworkStatus? networkStatus,
    String? errorMessage,
    DateTime? lastSyncTime,
    bool clearError = false,
  }) {
    return RepositoryState(
      products: products ?? this.products,
      source: source ?? this.source,
      networkStatus: networkStatus ?? this.networkStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOCK REMOTE API
//
// Simulates a real HTTP endpoint with:
//   • Configurable network delay (simulates slow connection)
//   • Configurable failure rate (simulates offline/server errors)
//   • Fresh product data with a timestamp so you can see when data refreshed
// ─────────────────────────────────────────────────────────────────────────────
class MockProductApi {
  // Simulate a realistic API call with delay
  static Future<List<Product>> fetchProducts({
    required bool simulateError,
    required int delaySeconds,
  }) async {
    await Future.delayed(Duration(seconds: delaySeconds));

    if (simulateError) {
      throw Exception('Network error: Unable to reach server (simulated)');
    }

    final now = DateTime.now();
    final timeTag = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    // Fresh data from the "server" — includes current time so user
    // can see when it was actually fetched from "network"
    return [
      Product(
        id: 1,
        name: 'Premium Wireless Headphones',
        category: 'Electronics',
        price: 299.99,
        rating: 4.8,
        stock: 42,
        isNew: true,
        description: '🌐 [Fetched at $timeTag] Sony WH-1000XM5 with 30hr battery',
      ),
      Product(
        id: 2,
        name: 'Running Shoes Pro',
        category: 'Sports',
        price: 129.99,
        rating: 4.6,
        stock: 18,
        isNew: false,
        description: '🌐 [Fetched at $timeTag] Lightweight carbon-plate running shoe',
      ),
      Product(
        id: 3,
        name: 'Smart Watch Ultra',
        category: 'Electronics',
        price: 449.99,
        rating: 4.9,
        stock: 7,
        isNew: true,
        description: '🌐 [Fetched at $timeTag] Apple Watch Series 9 with crash detection',
      ),
      Product(
        id: 4,
        name: 'Coffee Grinder Burr',
        category: 'Kitchen',
        price: 89.99,
        rating: 4.4,
        stock: 31,
        isNew: false,
        description: '🌐 [Fetched at $timeTag] Conical burr grinder, 40 grind settings',
      ),
      Product(
        id: 5,
        name: 'Ergonomic Office Chair',
        category: 'Furniture',
        price: 599.99,
        rating: 4.7,
        stock: 5,
        isNew: true,
        description: '🌐 [Fetched at $timeTag] Herman Miller Aeron, lumbar support',
      ),
      Product(
        id: 6,
        name: 'Yoga Mat Premium',
        category: 'Sports',
        price: 45.99,
        rating: 4.5,
        stock: 64,
        isNew: false,
        description: '🌐 [Fetched at $timeTag] 6mm thick, non-slip natural rubber',
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OFFLINE-FIRST REPOSITORY
//
// This is the heart of the pattern. The Repository is the ONLY class that
// knows about both the cache (Hive) and the remote API.
//
// The ViewModel and UI are completely unaware of WHERE data comes from.
// They just observe the Stream<RepositoryState> and react to changes.
//
// HOW THE CACHE-FIRST STREAM WORKS:
//
//   getProducts() returns a Stream<RepositoryState> using async* + yield.
//
//   async* creates a generator function — it can yield multiple values
//   over time, unlike a regular async function that returns once.
//
//   SEQUENCE:
//   ┌─────────────────────────────────────────────────────────────┐
//   │ 1. yield: {source: cache, networkStatus: loading}           │ ← instant
//   │    → UI shows cached products immediately (no spinner!)     │
//   │                                                             │
//   │ 2. [background] await API call (2-4 seconds)                │
//   │    → While waiting, UI shows stale cache + loading badge    │
//   │                                                             │
//   │ 3a. yield: {source: network, networkStatus: success}        │ ← fresh data
//   │     → UI refreshes with new data + saves to Hive            │
//   │                                                             │
//   │ 3b. yield: {source: cache, networkStatus: failure}          │ ← error path
//   │     → UI shows stale cache + error message (graceful!)      │
//   └─────────────────────────────────────────────────────────────┘
// ─────────────────────────────────────────────────────────────────────────────
class ProductRepository {
  static const String _boxName = 'offline_products_cache';
  static const String _cacheKey = 'products_list';
  static const String _syncTimeKey = 'last_sync_time';
  static const String _outboxBoxName = 'offline_sync_outbox';

  late Box _box;
  late Box _outboxBox;
  bool _isBoxOpen = false;
  bool _isOutboxOpen = false;

  // ── INITIALIZATION ─────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (!_isBoxOpen) {
      _box = await Hive.openBox(_boxName);
      _isBoxOpen = true;
    }
    if (!_isOutboxOpen) {
      _outboxBox = await Hive.openBox(_outboxBoxName);
      _isOutboxOpen = true;
    }
  }

  // ── READ CACHE ─────────────────────────────────────────────────────────────
  List<Product> _readCache() {
    final raw = _box.get(_cacheKey);
    if (raw == null) return [];
    final list = raw as List;
    return list
        .map((item) => Product.fromJson(item as Map, source: 'cache'))
        .toList();
  }

  bool get hasCachedData => _box.containsKey(_cacheKey);

  DateTime? get lastSyncTime {
    final ts = _box.get(_syncTimeKey) as String?;
    return ts != null ? DateTime.tryParse(ts) : null;
  }

  // ── WRITE CACHE ─────────────────────────────────────────────────────────────
  Future<void> _writeCache(List<Product> products) async {
    await _box.put(
      _cacheKey,
      products.map((p) => p.toJson()).toList(),
    );
    await _box.put(_syncTimeKey, DateTime.now().toIso8601String());
  }

  // ── CLEAR CACHE ────────────────────────────────────────────────────────────
  Future<void> clearCache() async {
    await _box.delete(_cacheKey);
    await _box.delete(_syncTimeKey);
    if (_isOutboxOpen) {
      await _outboxBox.clear();
    }
  }

  // ── PENDING OUTBOX METHODS ──────────────────────────────────────────────────
  List<Map<dynamic, dynamic>> getPendingOutbox() {
    if (!_isOutboxOpen) return [];
    return _outboxBox.values
        .map((e) => Map<dynamic, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> toggleFavoriteOffline(int productId) async {
    await initialize();

    // 1. Optimistic Cache Update
    final cached = _readCache();
    final index = cached.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final oldProduct = cached[index];
      final newFavoriteState = !oldProduct.isFavorite;
      cached[index] = oldProduct.copyWith(isFavorite: newFavoriteState);
      await _writeCache(cached);

      // 2. Queue the write to the outbox
      final actionId = DateTime.now().millisecondsSinceEpoch.toString();
      await _outboxBox.put(actionId, {
        'id': actionId,
        'productId': productId,
        'action': 'toggle_favorite',
        'value': newFavoriteState,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> syncOutbox(bool simulateError) async {
    await initialize();
    final keys = _outboxBox.keys.toList();
    if (keys.isEmpty) return;

    // Simulate minor networking latency
    await Future.delayed(const Duration(milliseconds: 1500));

    if (simulateError) {
      throw Exception('Network error: Unable to reach sync endpoint (simulated)');
    }

    // Process all pending items in outbox and remove them upon successful sync
    for (final key in keys) {
      await _outboxBox.delete(key);
    }
  }

  // Helper to apply outbox adjustments to fresh network data
  List<Product> _applyPendingOutbox(List<Product> products) {
    if (!_isOutboxOpen || _outboxBox.isEmpty) return products;

    final pending = getPendingOutbox();
    final result = List<Product>.from(products);

    for (final item in pending) {
      final productId = item['productId'] as int;
      final value = item['value'] as bool;
      final idx = result.indexWhere((p) => p.id == productId);
      if (idx != -1) {
        result[idx] = result[idx].copyWith(isFavorite: value);
      }
    }
    return result;
  }

  // ── CORE: CACHE-FIRST STREAM ───────────────────────────────────────────────
  //
  // This async* generator is the implementation of the offline-first pattern.
  // It yields multiple RepositoryState events to its listener over time.
  //
  // async* = asynchronous generator — a function that can yield multiple
  //          values over time, each value creating a new stream event.
  //
  // yield  = emit one value to the stream and suspend until the listener
  //          is ready for the next one.
  //
  // yield* = delegate to another stream/iterable, forwarding all its events.
  Stream<RepositoryState> getProducts({
    bool simulateNetworkError = false,
    int networkDelaySeconds = 2,
  }) async* {
    await initialize();

    final cachedProducts = _readCache();

    // ── STEP 1: Yield cache immediately ──────────────────────────────────────
    // Even if the cache is empty, we yield it immediately so the UI can
    // render its "no cache" state while the network call is in progress.
    //
    // Key insight: We set networkStatus = loading so the UI shows a
    // "Syncing..." indicator alongside the cached data (not a full-screen
    // janky spinner).
    yield RepositoryState(
      products: cachedProducts.map((p) => p.copyWith(source: 'cache')).toList(),
      source: cachedProducts.isEmpty ? DataSource.empty : DataSource.cache,
      networkStatus: NetworkStatus.loading,
      lastSyncTime: lastSyncTime,
    );

    // ── STEP 2: Fetch from network (background) ───────────────────────────────
    try {
      final freshProducts = await MockProductApi.fetchProducts(
        simulateError: simulateNetworkError,
        delaySeconds: networkDelaySeconds,
      );

      // Apply pending outbox offline modifications to fresh data so they aren't lost
      final mergedProducts = _applyPendingOutbox(freshProducts);

      // ── STEP 3a: Success — update cache and yield fresh data ──────────────
      await _writeCache(mergedProducts);

      yield RepositoryState(
        products: mergedProducts.map((p) => p.copyWith(source: 'network')).toList(),
        source: DataSource.network,
        networkStatus: NetworkStatus.success,
        lastSyncTime: lastSyncTime,
      );
    } catch (e) {
      // ── STEP 3b: Failure — yield stale cache with error ───────────────────
      // This is GRACEFUL DEGRADATION: even with no network, the user
      // still sees their last cached data instead of a blank screen.
      yield RepositoryState(
        products: cachedProducts.map((p) => p.copyWith(source: 'cache')).toList(),
        source: cachedProducts.isEmpty ? DataSource.empty : DataSource.cache,
        networkStatus: NetworkStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
        lastSyncTime: lastSyncTime,
      );
    }
  }
}
