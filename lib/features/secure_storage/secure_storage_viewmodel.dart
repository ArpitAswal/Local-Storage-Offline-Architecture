import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'secure_storage_service.dart';

/// [SecureStorageViewModel] - MVVM state holder for the Secure Storage screens.
///
/// Wraps [SecureStorageService] calls, maintains UI state, and pushes
/// updates to the View layer via ChangeNotifier.
///
/// Key concepts demonstrated:
///   - write() encrypts a key-value pair using hardware-backed AES-256
///   - read() decrypts and returns the value for a given key
///   - readAll() lists the entire encrypted vault
///   - containsKey() checks key existence without reading the value
///   - delete() removes one encrypted entry
///   - deleteAll() wipes the entire secure vault (use on logout)
class SecureStorageViewModel extends ChangeNotifier {
  final SecureStorageService _service = SecureStorageService.instance;

  // ──────────────────────────────────────────────────────────────────────────
  // Private State
  // ──────────────────────────────────────────────────────────────────────────
  bool _isInitialized = false;

  /// All key-value pairs currently in the secure vault (decrypted for display).
  Map<String, String> _vaultEntries = {};

  /// The last value retrieved by a single read() call (shown in the UI).
  String? _lastReadValue;
  String? _lastReadKey;

  /// Whether the last containsKey() check returned true or false.
  bool? _lastContainsResult;
  String? _lastContainsKey;

  /// Scrollable terminal-style log of every API call executed.
  final List<String> _consoleLogs = [];

  bool _isLoading = false;
  bool _isDemoRunning = false;

  // ──────────────────────────────────────────────────────────────────────────
  // Public Getters
  // ──────────────────────────────────────────────────────────────────────────
  bool get isInitialized => _isInitialized;
  Map<String, String> get vaultEntries => _vaultEntries;
  String? get lastReadValue => _lastReadValue;
  String? get lastReadKey => _lastReadKey;
  bool? get lastContainsResult => _lastContainsResult;
  String? get lastContainsKey => _lastContainsKey;
  List<String> get consoleLogs => _consoleLogs;
  bool get isLoading => _isLoading;
  bool get isDemoRunning => _isDemoRunning;
  int get totalKeys => _vaultEntries.length;

  // ──────────────────────────────────────────────────────────────────────────
  // Initialization
  // ──────────────────────────────────────────────────────────────────────────

  /// Loads the current vault snapshot so the UI shows existing entries on open.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      notifyListeners();

      // FLOW: readAll() calls FlutterSecureStorage.readAll() which queries:
      //   Android → Android KeyStore decrypts all entries from SharedPreferences
      //   iOS     → Queries Keychain for all items tagged to this app bundle
      _vaultEntries = await _service.readAll();
      _isInitialized = true;

      _addLog('SYSTEM', 'FlutterSecureStorage initialized. Vault has ${_vaultEntries.length} stored key(s).');
      _addLog(
        'SYSTEM',
        'Android: RSA OAEP + AES-GCM via KeyStore | iOS: Keychain (accessibility: unlocked)',
      );
    } catch (e) {
      _addLog('ERROR', 'Initialization failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // WRITE
  // ──────────────────────────────────────────────────────────────────────────

  /// Encrypts [value] and stores it under [key] in the secure vault.
  ///
  /// If the key already exists, the value is overwritten (silently).
  Future<void> writeValue({required String key, required String value}) async {
    if (key.trim().isEmpty || value.trim().isEmpty) {
      _addLog('WARNING', 'Write aborted: both key and value are required.');
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // FLOW: Android → RSA OAEP wraps AES key → AES-GCM encrypts value
      //        iOS    → Encrypts value and stores in Keychain
      await _service.write(key: key.trim(), value: value.trim());

      // Reload the vault to reflect the new entry
      await _refreshVault();

      _addLog(
        'WRITE',
        'await storage.write(key: "${key.trim()}", value: "***") → encrypted & stored.',
      );
    } catch (e) {
      _addLog('ERROR', 'Write failed for key "$key": $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // READ (Single)
  // ──────────────────────────────────────────────────────────────────────────

  /// Reads and decrypts the value stored under [key].
  /// Updates [lastReadValue] and [lastReadKey] for display in the UI.
  Future<void> readValue({required String key}) async {
    if (key.trim().isEmpty) {
      _addLog('WARNING', 'Read aborted: key cannot be empty.');
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // FLOW: Android → retrieves RSA-wrapped AES key from KeyStore → decrypts
      //        iOS    → queries Keychain by key name → returns decrypted string
      final value = await _service.read(key: key.trim());

      _lastReadKey = key.trim();
      _lastReadValue = value;

      if (value != null) {
        _addLog(
          'READ',
          'await storage.read(key: "${key.trim()}") → value found & decrypted ✓',
        );
      } else {
        _addLog(
          'READ',
          'await storage.read(key: "${key.trim()}") → null (key not found in vault)',
        );
      }
    } catch (e) {
      _addLog('ERROR', 'Read failed for key "$key": $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CONTAINS KEY
  // ──────────────────────────────────────────────────────────────────────────

  /// Checks if [key] exists in the vault without reading or exposing the value.
  Future<void> checkContainsKey({required String key}) async {
    if (key.trim().isEmpty) {
      _addLog('WARNING', 'containsKey aborted: key cannot be empty.');
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // FLOW: Performs a presence-only check without decrypting the value.
      // More efficient than read() when you only need to verify existence.
      final exists = await _service.containsKey(key: key.trim());

      _lastContainsKey = key.trim();
      _lastContainsResult = exists;

      _addLog(
        'CHECK',
        'await storage.containsKey(key: "${key.trim()}") → $exists',
      );
    } catch (e) {
      _addLog('ERROR', 'containsKey failed for "$key": $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DELETE (Single)
  // ──────────────────────────────────────────────────────────────────────────

  /// Permanently removes [key] and its encrypted value from the vault.
  Future<void> deleteValue({required String key}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // FLOW: Android → removes entry from KeyStore + SharedPreferences
      //        iOS    → removes the Keychain item for this key
      await _service.delete(key: key);

      await _refreshVault();

      // Clear the read result if it was for this key
      if (_lastReadKey == key) {
        _lastReadValue = null;
        _lastReadKey = null;
      }
      if (_lastContainsKey == key) {
        _lastContainsResult = null;
        _lastContainsKey = null;
      }

      _addLog(
        'DELETE',
        'await storage.delete(key: "$key") → key removed from encrypted vault.',
      );
    } catch (e) {
      _addLog('ERROR', 'Delete failed for key "$key": $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DELETE ALL
  // ──────────────────────────────────────────────────────────────────────────

  /// Wipes the entire secure vault — ALL keys and values permanently deleted.
  ///
  /// ⚠️ Use this on user logout to prevent token leakage between accounts.
  Future<void> deleteAll() async {
    try {
      _isLoading = true;
      notifyListeners();

      // FLOW: Deletes ALL entries from Keychain/KeyStore
      await _service.deleteAll();

      _vaultEntries = {};
      _consoleLogs.clear();
      _lastReadValue = null;
      _lastReadKey = null;
      _lastContainsResult = null;
      _lastContainsKey = null;

      _addLog('DELETE ALL', 'await storage.deleteAll() → entire encrypted vault wiped.');
    } catch (e) {
      _addLog('ERROR', 'deleteAll failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Refreshes the in-memory vault snapshot from the encrypted storage.
  Future<void> _refreshVault() async {
    _vaultEntries = await _service.readAll();
  }

  /// Adds a timestamped log line to the terminal console (newest first).
  void _addLog(String type, String message) {
    final now = DateTime.now();
    final t = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    _consoleLogs.insert(0, '[$t] $type: $message');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // KEYSTORE DEC_FAILURE SIMULATION
  // ──────────────────────────────────────────────────────────────────────────

  /// Simulates a KeyStore / Keychain decryption failure (PlatformException) and auto-recovery.
  Future<void> simulateDecryptionFailureDemo() async {
    if (_isDemoRunning) return;
    _isDemoRunning = true;
    _isLoading = true;
    _addLog('DEMO', 'Simulating KeyStore decryption failure...');
    notifyListeners();

    try {
      // Step 1: Pre-populate dummy tokens
      await _service.write(key: 'auth_token', value: 'secret_token_123_abc');
      await _refreshVault();
      _addLog('DEMO', 'Vault pre-populated with "auth_token".');
      await Future.delayed(const Duration(milliseconds: 600));

      // Step 2: Simulate reading and failing due to lockscreen configuration change
      _addLog('DEMO', 'Reading "auth_token" with hardware KeyStore decryption...');
      await Future.delayed(const Duration(milliseconds: 600));

      // We deliberately throw the exception to simulate hardware decryption fail
      throw PlatformException(
        code: 'KeystoreException',
        message: 'Failed to decrypt: KeyPermanentlyInvalidatedException: Key permanently invalidated because secure lock screen signature has changed.',
      );
    } on PlatformException catch (e) {
      _addLog('ERROR', '${e.code}: ${e.message}');
      await Future.delayed(const Duration(milliseconds: 600));
      _addLog('SYSTEM', 'Recovery protocol triggered: calling storage.deleteAll()...');
      
      // Execute the recovery: wipe all keys so subsequent reads do not crash
      await _service.deleteAll();
      await _refreshVault();
      
      // Clear temporary states
      _lastReadValue = null;
      _lastReadKey = null;

      _addLog('SYSTEM', 'Vault wiped successfully! Device state recovered cleanly.');
      _addLog('SYSTEM', 'User session terminated. Redirecting to Login/Auth page.');
    } finally {
      _isDemoRunning = false;
      _isLoading = false;
      notifyListeners();
    }
  }
}
