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
  bool _isInitialized = false;

  /// Whether the service has been initialized.
  bool get isInitialized => _isInitialized;

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
    _isInitialized = true;
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

  /// Removes a specific key from both the async and cache stores.
  Future<void> removeKey(String key) async {
    // Remove from async store (works for any key).
    await _prefsAsync.remove(key);
    // Remove from cache store if the key is in its allowList.
    try {
      await _prefsWithCache?.remove(key);
    } catch (_) {
      // Key may not be in the cache allowList — that's OK.
    }
  }

  /// Simulates a type mismatch scenario for educational purposes.
  /// Stores an integer under a key, then reads it as a String.
  /// Returns a descriptive result string showing what happened.
  Future<String> simulateTypeMismatch() async {
    // Write an int value to the async store
    await _prefsAsync.setInt('demo_type_key', 42);
    
    // Read it back as a String — SharedPreferences returns null on type mismatch
    final String? wrongTypeResult = await _prefsAsync.getString('demo_type_key');
    
    // Read it back correctly as an int
    final int? correctTypeResult = await _prefsAsync.getInt('demo_type_key');

    // Clean up after demo
    await _prefsAsync.remove('demo_type_key');

    return 'Stored: setInt(\'demo_type_key\', 42)\n'
        'Read as String: getString(\'demo_type_key\') → ${wrongTypeResult ?? 'null'} (wrong type!)\n'
        'Read as int:    getInt(\'demo_type_key\')    → $correctTypeResult ✓ (correct type)\n\n'
        'SharedPreferences returns NULL on type mismatch instead of crashing.\n'
        'Always use the correct getter and null-check the return value!';
  }
}
