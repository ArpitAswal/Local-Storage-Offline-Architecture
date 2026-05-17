import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

/// [SharedPreferencesService] - A thread-safe Singleton service that manages
/// light-weight persistence using modern Flutter SharedPreferences APIs.
class SharedPreferencesService {
  // ───────────────────────────────────────────────────────────────────────────
  // 1. Private Constructor & Singleton Instance
  // Ensures only one instance of the service exists across the application.
  // ───────────────────────────────────────────────────────────────────────────
  SharedPreferencesService._internal();
  static final SharedPreferencesService instance = SharedPreferencesService._internal();

  // Modern SharedPreferences APIs
  SharedPreferencesWithCache? _prefsWithCache;
  final SharedPreferencesAsync _prefsAsync = SharedPreferencesAsync();

  /// Initializes the service, runs legacy migrations, and establishes caches.
  Future<void> init() async {
    // FLOW: Step 1 - Fetch the legacy instance to check for data migration.
    final SharedPreferences legacyPrefs = await SharedPreferences.getInstance();

    // FLOW: Step 2 - Safely migrate old data to the new SharedPreferencesAsync format.
    await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
      legacySharedPreferencesInstance: legacyPrefs,
      sharedPreferencesAsyncOptions: const SharedPreferencesOptions(),
      migrationCompletedKey: 'migrationCompleted',
    );

    // FLOW: Step 3 - Initialize the cached version (SharedPreferencesWithCache)
    // targeting specific allow-listed keys.
    _prefsWithCache = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: <String>{'counter'},
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. SharedPreferencesWithCache Methods
  // Operates on synchronous in-memory cache for ultra-fast reads.
  // ───────────────────────────────────────────────────────────────────────────

  /// Gets the cached counter value synchronously.
  int getCounterWithCache() {
    // FLOW: If not initialized, fallback to 0. Else read directly from memory cache.
    if (_prefsWithCache == null) return 0;
    return _prefsWithCache!.getInt('counter') ?? 0;
  }

  /// Sets the cached counter value synchronously and triggers an async write in the background.
  Future<void> setCounterWithCache(int value) async {
    if (_prefsWithCache == null) return;
    // FLOW: Update memory cache instantly and write to disk asynchronously.
    await _prefsWithCache!.setInt('counter', value);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. SharedPreferencesAsync Methods
  // Bypasses local caching entirely. Performs direct asynchronous disk/platform queries.
  // ───────────────────────────────────────────────────────────────────────────

  /// Fetches the external counter value directly from persistent storage.
  Future<int> getExternalCounterAsync() async {
    // FLOW: Query the system platform channels asynchronously.
    final int? value = await _prefsAsync.getInt('externalCounter');
    return value ?? 0;
  }

  /// Sets the external counter value asynchronously.
  Future<void> setExternalCounterAsync(int value) async {
    // FLOW: Write directly to platform persistent storage.
    await _prefsAsync.setInt('externalCounter', value);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. Utility Operations
  // ───────────────────────────────────────────────────────────────────────────

  /// Clears all keys in both cached and async persistent storage.
  Future<void> clearAll() async {
    // FLOW: Clear the async store by specifying the allowed keys.
    await _prefsAsync.clear(allowList: <String>{'externalCounter', 'migrationCompleted'});
    
    // FLOW: Clear the cached store.
    if (_prefsWithCache != null) {
      await _prefsWithCache!.clear();
    }
  }
}
