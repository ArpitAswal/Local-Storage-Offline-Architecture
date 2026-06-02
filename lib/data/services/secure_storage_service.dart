import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

/// [SecureStorageService] - Singleton service wrapping FlutterSecureStorage.
///
/// FlutterSecureStorage stores data using platform-native hardware-backed encryption:
///   • Android: RSA OAEP (key cipher) + AES-GCM (storage cipher) via Android KeyStore
///   • iOS / macOS: Apple Keychain Services (hardware-backed on devices with Secure Enclave)
///   • Windows: Data Protection API (DPAPI) — user-account-scoped encryption
///   • Linux: libsecret (GNOME Keyring / KWallet)
///   • Web: WebCrypto API (browser private key, HTTPS only)
///
/// Unlike SharedPreferences or Hive, data stored here is:
///   - Encrypted at rest with AES-256 by default
///   - Inaccessible from other apps (sandboxed by OS)
///   - NOT readable even on rooted/jailbroken devices without the key
///   - Survives app reinstalls on iOS (Keychain persists across installs)
class SecureStorageService {
  // ──────────────────────────────────────────────────────────────────────────
  // 1. Singleton Pattern
  // ──────────────────────────────────────────────────────────────────────────
  SecureStorageService._internal();
  static final SecureStorageService instance = SecureStorageService._internal();

  // ──────────────────────────────────────────────────────────────────────────
  // 2. FlutterSecureStorage Instance
  //
  // FLOW: AndroidOptions() defaults to:
  //   - keyCipherAlgorithm: RSA_ECB_OAEPwithSHA_256andMGF1Padding
  //   - storageCipherAlgorithm: AES_GCM_NoPadding
  //   - migrateOnAlgorithmChange: true (auto-migrates old encrypted data)
  //
  // This is the most secure default available for Android 6.0+ (API 23+).
  // ──────────────────────────────────────────────────────────────────────────
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      // RSA OAEP wraps the AES key — no biometric required for key access
      // AES-GCM provides authenticated encryption (integrity + confidentiality)
      // migrateOnAlgorithmChange ensures old data is re-encrypted automatically
      migrateOnAlgorithmChange: true,
    ),
    iOptions: IOSOptions(
      // 'unlocked' means values accessible ONLY when device is unlocked.
      // Other options: first_unlock (accessible after first unlock post-reboot)
      accessibility: KeychainAccessibility.unlocked,
    ),
  );

  // ──────────────────────────────────────────────────────────────────────────
  // 3. WRITE — Store a key-value pair with full encryption
  // ──────────────────────────────────────────────────────────────────────────

  /// Writes [value] under [key] in the encrypted storage.
  ///
  /// FLOW:
  /// - Android: Encrypts value with AES-GCM, wraps key with RSA OAEP in KeyStore
  /// - iOS: Writes to Keychain with accessibility = unlocked
  /// - If key already exists, it is silently overwritten (no duplicate error)
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. READ — Decrypt and return a value by key
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns the decrypted value for [key], or null if the key doesn't exist.
  ///
  /// FLOW:
  /// - Android: Retrieves the RSA-wrapped AES key from KeyStore, decrypts value
  /// - iOS: Queries Keychain for the key, returns decrypted string
  /// - Returns null if key was never written — always check for null!
  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 5. READ ALL — Returns every key-value pair currently stored
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns a Map of ALL stored key-value pairs (decrypted).
  ///
  /// Useful for displaying the full vault contents in the UI.
  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 6. CHECK KEY EXISTENCE — Non-destructive existence check
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns true if [key] exists in secure storage without reading the value.
  ///
  /// More efficient than read() when you only need to verify presence.
  Future<bool> containsKey({required String key}) async {
    return await _storage.containsKey(key: key);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 7. DELETE — Remove a single encrypted key-value pair
  // ──────────────────────────────────────────────────────────────────────────

  /// Permanently deletes [key] and its encrypted value from secure storage.
  ///
  /// FLOW: On Android, also removes the corresponding AES key from the KeyStore.
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 8. DELETE ALL — Wipe the entire encrypted vault
  // ──────────────────────────────────────────────────────────────────────────

  /// Clears ALL keys and values from secure storage (factory wipe).
  ///
  /// ⚠️ WARNING: This is irreversible. Use only for sign-out / account deletion.
  /// In production apps, call this on user logout to prevent token leaks.
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 9. ROBUST ERROR HANDLING & RECOVERY
  // ──────────────────────────────────────────────────────────────────────────

  /// Reads a value securely, catching PlatformExceptions (KeyStore corruption/invalidation).
  ///
  /// If decryption fails (e.g. user changed device PIN, or backup/restore corrupted
  /// the key links), this wipes the entire vault to prevent crash loops and throws a clean error.
  Future<String?> readWithRobustHandling({required String key}) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (e) {
      // KeyStore decryption failures or key invalidations require a factory reset of the storage
      await deleteAll();
      throw PlatformException(
        code: 'KEYSTORE_DECRYPTION_FAILED',
        message: 'KeyStore/Keychain decryption failed ($e). Vault has been wiped to prevent crash loops. Please re-authenticate.',
      );
    }
  }
}
