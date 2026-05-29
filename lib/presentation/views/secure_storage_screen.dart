import 'package:flutter/material.dart';
import '../navigation/route_navigation.dart';
import '../widgets/extension_widgets.dart';
import 'secure_storage_example.dart';

/// [SecureStorageScreen] - Educational guide for flutter_secure_storage.
/// Covers platform encryption internals, all CRUD APIs, AndroidOptions,
/// IOSOptions, biometric authentication, and real-world security use cases.
class SecureStorageScreen extends StatelessWidget {
  const SecureStorageScreen({super.key});

  static const Color secureColor = Color(0xFFC62828); // Red 800

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => RouteNavigation.back(context),
        ),
        centerTitle: true,
        title: const Text('Secure Storage Guide'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () =>
                  RouteNavigation.push(context, const SecureStorageDemoView()),
              icon: Icon(Icons.science, size: 18, color: secureColor),
              label: Text(
                'Try Lab',
                style: TextStyle(
                  color: secureColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero ─────────────────────────────────────────────────────
              context.headTitle(
                '🔐 flutter_secure_storage: Hardware-Encrypted Key-Value',
                secureColor,
              ),
              context.dividerSpace(16),
              context.subHeadTitle(
                'flutter_secure_storage stores key-value pairs using the platform\'s '
                'native hardware-backed encryption — not just software encryption. '
                'Unlike SharedPreferences or Hive, data is encrypted with AES-256 '
                'and the encryption keys live inside a hardware security module '
                '(Android KeyStore or iOS Secure Enclave) that NEVER exposes them '
                'to user-space code — not even to your own app.',
              ),
              context.dividerSpace(16),

              // ── Section 1: Why Secure Storage ────────────────────────────
              context.headTitle('1. Why Not SharedPreferences or Hive?', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('The problem with plain storage for secrets', secureColor),
              context.contentSectionContainer(
                '''// ❌ WRONG — Never store secrets in SharedPreferences
final prefs = await SharedPreferences.getInstance();
await prefs.setString('jwt_token', 'eyJhbGciOiJIUzI1NiIsInR...');
// The JWT is stored as PLAIN TEXT in an XML file on Android!
// Any app on a ROOTED device can read /data/data/com.example/shared_prefs/

// ❌ WRONG — Never store secrets in Hive either
final box = await Hive.openBox('auth');
await box.put('token', 'my_secret_api_key');
// Hive uses binary format but is NOT encrypted by default.
// File can be extracted via adb backup on unprotected devices.

// ✅ CORRECT — Use flutter_secure_storage for ALL secrets
final storage = FlutterSecureStorage();
await storage.write(key: 'jwt_token', value: 'eyJhbGciOiJIUzI1NiIsInR...');
// Encrypted with AES-256 via Android KeyStore / iOS Keychain.
// The AES key NEVER leaves the hardware security module.''',
              ),
              context.theoryContentText(
                '🔐 Security Rule: ANY piece of data that would cause a security '
                'incident if stolen MUST go into Secure Storage:\n'
                '  • JWT access tokens & OAuth refresh tokens\n'
                '  • API keys and service credentials\n'
                '  • Biometric auth secrets and encryption seeds\n'
                '  • User passwords (before hashing, during auth flow)\n'
                '  • Private keys for E2E encryption\n\n'
                '✅ SharedPreferences is fine for: theme mode, onboarding flags, language prefs\n'
                '❌ SharedPreferences is NEVER OK for: tokens, passwords, keys',
              ),
              context.dividerSpace(16),

              // ── Section 2: How it works per platform ──────────────────────
              context.headTitle('2. How Encryption Works Per Platform', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('Platform-native hardware-backed encryption', secureColor),
              context.contentSectionContainer(
                '''// ──────────────────────────────────────────────────────────
// ANDROID (API 23+ / Android 6.0+)
// ──────────────────────────────────────────────────────────
// Key Cipher:     RSA/ECB/OAEPWithSHA-256AndMGF1Padding (default v10+)
// Storage Cipher: AES/GCM/NoPadding (authenticated encryption)
//
// Flow:
//   1. A random AES-256 key is generated and wrapped (encrypted) with RSA
//   2. The RSA private key is stored inside Android KeyStore — 
//      a hardware-backed keystore that NEVER exports private keys
//   3. Your data is encrypted with AES-GCM and stored in SharedPreferences
//   4. On read: KeyStore unwraps the AES key → decrypts the data
//
// Even on a ROOTED device: the AES key cannot be extracted from KeyStore!

// ──────────────────────────────────────────────────────────
// iOS / macOS
// ──────────────────────────────────────────────────────────
// Mechanism: Apple Keychain Services
//
// On devices with Secure Enclave (iPhone 5s+, M1 Mac):
//   - Encryption keys are generated INSIDE the Secure Enclave chip
//   - Keys never leave the chip — even jailbreaking cannot extract them
//
// The Keychain is sandboxed per app bundle ID by default.
// Other apps CANNOT access your Keychain items.
//
// accessibility options control WHEN items are accessible:
//   • .unlocked → only when screen is unlocked (recommended)
//   • .first_unlock → after first device unlock post-reboot
//   • .always → always accessible (least secure)

// ──────────────────────────────────────────────────────────
// Windows
// ──────────────────────────────────────────────────────────
// Uses DPAPI (Data Protection API) — tied to the Windows user account
// Data is encrypted using the user's login credentials as the key

// ──────────────────────────────────────────────────────────
// Linux
// ──────────────────────────────────────────────────────────
// Uses libsecret → GNOME Keyring or KWallet
// Items stored in the desktop session's secure keyring daemon

// ──────────────────────────────────────────────────────────
// Web (Experimental)
// ──────────────────────────────────────────────────────────
// Uses WebCrypto API — browser generates the private key
// Encrypted data stored in LocalStorage — NOT portable across browsers
// ONLY works on HTTPS (or localhost)''',
              ),
              context.dividerSpace(16),

              // ── Section 3: Setup ─────────────────────────────────────────
              context.headTitle('3. Setup & pubspec.yaml', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('Add dependency', secureColor),
              context.contentSectionContainer(
                '''dependencies:
  flutter_secure_storage: ^10.3.1

# ⚠️ Android: Min SDK must be 23+ in android/app/build.gradle
# android {
#   defaultConfig {
#     minSdkVersion 23   ← Required for Android KeyStore AES-GCM
#   }
# }

# ⚠️ Android: Disable auto-backup to prevent encrypted data corruption.
# Add to android/app/src/main/AndroidManifest.xml:
# <application android:allowBackup="false" ...>
# (Google Drive backup of encrypted data causes InvalidKeyException on restore)

# ⚠️ macOS: Add Keychain Sharing capability to both:
#   macos/Runner/DebugProfile.entitlements
#   macos/Runner/Release.entitlements
# <key>keychain-access-groups</key>
# <array/>''',
              ),
              context.theoryContentText(
                '💡 minSdkVersion 23 is required because Android KeyStore\'s '
                'hardware-backed AES-GCM encryption was introduced in API 23. '
                'Apps targeting lower versions must fall back to software encryption '
                'which is significantly less secure.',
              ),
              context.dividerSpace(16),

              // ── Section 4: Create Instance ────────────────────────────────
              context.headTitle('4. Creating a FlutterSecureStorage Instance', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('Default (Recommended) — RSA OAEP + AES-GCM', secureColor),
              context.contentSectionContainer(
                '''import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ── Option 1: Default (Recommended for most apps) ──────────────────────
// Android: RSA OAEP key cipher + AES-GCM storage cipher (v10+ default)
// iOS:     Keychain with accessibility = unlocked
const storage = FlutterSecureStorage();

// ── Option 2: With explicit platform options ────────────────────────────
final storage = FlutterSecureStorage(
  // Android options
  aOptions: AndroidOptions(
    migrateOnAlgorithmChange: true,  // Auto-migrate from old ciphers
    // keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
    // storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
  ),
  // iOS / macOS options
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.unlocked,
    // .unlocked     → only when device is unlocked (most secure for tokens)
    // .first_unlock → accessible after first unlock post-reboot (for background tasks)
    // .always       → always accessible (least secure — avoid for sensitive data)
  ),
);''',
              ),

              context.contentText('With Biometric Authentication (Optional)', secureColor),
              context.contentSectionContainer(
                '''// ── Option 3: Biometric with graceful degradation ──────────────────────
// Data is accessible without biometrics if device has none enrolled.
// Key cipher becomes AES-GCM/NoPadding stored in Android KeyStore.
final storage = FlutterSecureStorage(
  aOptions: AndroidOptions.biometric(
    enforceBiometrics: false,       // Graceful degradation if no biometrics
    biometricPromptTitle: 'Unlock App',
    biometricPromptSubtitle: 'Use fingerprint or face unlock',
  ),
);

// ── Option 4: Strict Biometric Enforcement ─────────────────────────────
// Throws PlatformException if device has NO PIN/pattern/biometric enrolled.
// Required minimum: Android 9.0 (API 28) for enforcement to work fully.
final storage = FlutterSecureStorage(
  aOptions: AndroidOptions.biometric(
    enforceBiometrics: true,
    biometricPromptTitle: 'Authentication Required',
  ),
);

// AndroidManifest.xml — required permission for biometric:
// <uses-permission android:name="android.permission.USE_BIOMETRIC"/>''',
              ),
              context.dividerSpace(16),

              // ── Section 5: Full CRUD API ──────────────────────────────────
              context.headTitle('5. Full CRUD API', colorScheme.secondary),
              const SizedBox(height: 10),

              context.contentText('WRITE — Encrypt and store', secureColor),
              context.contentSectionContainer(
                '''// Writes a key-value pair with full hardware-backed encryption.
// If the key already exists, the value is silently OVERWRITTEN.
// Value must be a String — serialize objects to JSON first.
await storage.write(key: 'jwt_token', value: 'Bearer eyJhbG...');
await storage.write(key: 'api_key', value: 'sk-abc123xyz');
await storage.write(key: 'user_id', value: '42');

// Storing a complex object: serialize to JSON string first
import 'dart:convert';
final userJson = jsonEncode({'name': 'Alice', 'role': 'admin'});
await storage.write(key: 'user_profile', value: userJson);''',
              ),

              context.contentText('READ — Decrypt and retrieve', secureColor),
              context.contentSectionContainer(
                '''// Returns the decrypted String value, or NULL if key doesn't exist.
// Always null-check the return value!
final String? token = await storage.read(key: 'jwt_token');

if (token != null) {
  print('Token: \$token'); // The decrypted value
} else {
  print('No token found — user is not logged in.');
}

// Read and decode a JSON object back to a Dart Map
final String? json = await storage.read(key: 'user_profile');
if (json != null) {
  final Map<String, dynamic> profile = jsonDecode(json);
  print('User: \${profile['name']}');
}''',
              ),

              context.contentText('READ ALL — List the entire vault', secureColor),
              context.contentSectionContainer(
                '''// Returns ALL key-value pairs currently in secure storage.
// Returns Map<String, String> — values are already decrypted.
final Map<String, String> allSecrets = await storage.readAll();

allSecrets.forEach((key, value) {
  print('\$key → \$value');
});

// Useful for:
//   - Debugging: what's currently in the vault?
//   - Migration: move all entries to a new encryption scheme
//   - Audit: log all stored key names (never log values in production!)''',
              ),

              context.contentText('CONTAINS KEY — Check existence without reading', secureColor),
              context.contentSectionContainer(
                '''// Checks if a key exists WITHOUT decrypting or reading the value.
// More efficient than read() when you only need to verify presence.
final bool hasToken = await storage.containsKey(key: 'jwt_token');

if (hasToken) {
  // User is logged in — skip login screen
  Navigator.pushReplacementNamed(context, '/home');
} else {
  // No token found — show login screen
  Navigator.pushReplacementNamed(context, '/login');
}''',
              ),

              context.contentText('DELETE — Remove a single secret', secureColor),
              context.contentSectionContainer(
                '''// Permanently removes a single key-value pair.
// On Android: removes the entry from SharedPreferences
// On iOS:     deletes the Keychain item for this key
await storage.delete(key: 'jwt_token');

// Typical use: refresh token rotation — delete old token, write new one
await storage.delete(key: 'refresh_token');
await storage.write(key: 'refresh_token', value: newRefreshToken);''',
              ),

              context.contentText('DELETE ALL — Secure logout / vault wipe', secureColor),
              context.contentSectionContainer(
                '''// Permanently removes ALL key-value pairs from secure storage.
// ⚠️ This is IRREVERSIBLE — use it carefully.
//
// Call this on user logout to prevent credential leakage
// when another user logs into the same device/account.
Future<void> handleLogout() async {
  await storage.deleteAll();  // Wipe all tokens and secrets
  
  // Then navigate to login screen
  if (context.mounted) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }
}''',
              ),
              context.theoryContentText(
                '⚡ Production Pattern — Token Management:\n'
                '  Login  → storage.write(key: "jwt", value: token)\n'
                '  Startup → storage.containsKey(key: "jwt") → decide route\n'
                '  API Call → storage.read(key: "jwt") → attach to headers\n'
                '  Refresh → storage.delete + storage.write (atomic rotation)\n'
                '  Logout  → storage.deleteAll() → wipe all credentials\n\n'
                'This pattern is used in every major production Flutter app: '
                'banking, healthcare, social, and e-commerce.',
              ),
              context.dividerSpace(16),

              // ── Section 6: iOS Keychain Persistence ───────────────────────
              context.headTitle('6. iOS Keychain: Survives App Reinstalls!', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('An important iOS behaviour beginners miss', secureColor),
              context.contentSectionContainer(
                '''// ⚠️ IMPORTANT iOS BEHAVIOUR:
// Keychain items persist even after the app is UNINSTALLED on iOS!
//
// This means:
//   1. User uninstalls your app
//   2. User reinstalls your app
//   3. storage.read(key: 'user_id') → returns the old value!
//
// This can be a FEATURE (auto-login after reinstall) or a BUG
// (stale/invalid tokens from a previous installation).
//
// SOLUTION: Use a "first_launch" flag in SharedPreferences.
// On first ever launch, clear the Keychain:

Future<void> clearKeychainOnFirstLaunch() async {
  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool('first_launch') ?? true;
  
  if (isFirstLaunch) {
    // Clear any leftover Keychain items from a previous installation
    await storage.deleteAll();
    await prefs.setBool('first_launch', false);
  }
}''',
              ),
              context.theoryContentText(
                '🍎 Why does iOS do this? Apple designed Keychain to persist across '
                'reinstalls to support features like "automatic login" after reinstall '
                'and to allow smooth app migrations. '
                'Android KeyStore does NOT persist after app uninstall — the keys '
                'are destroyed with the app sandbox.',
              ),
              context.dividerSpace(16),

              // ── Section 7: Security vs Other Storages ─────────────────────
              context.headTitle('7. Security Comparison', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('When to use which storage', secureColor),
              context.contentSectionContainer(
                '''// STORAGE SECURITY COMPARISON
// ─────────────────────────────────────────────────────────────────
// SharedPreferences  → Plain text XML / NSUserDefaults. NO encryption.
//                      ❌ Readable on rooted/jailbroken devices.
//                      ✅ Use for: theme, language, flags, last tab index.
//
// Hive               → Binary format. NO encryption by default.
//                      ❌ File extractable via adb on unprotected devices.
//                      ✅ Use for: offline cache, draft objects, user data.
//
// flutter_secure_storage → AES-256 via hardware-backed KeyStore/Keychain.
//                          ✅ Encrypted at rest, sandboxed, hardware-protected.
//                          ✅ Use for: tokens, API keys, passwords, seeds.
//                          ⚠️ Slower than SharedPreferences (encryption overhead).
//                          ⚠️ Do NOT store large blobs — use for keys/tokens only.
//
// SQLite / Drift     → Plain SQL on disk. NO encryption by default.
//                      Optional: SQLCipher adds AES-256 encryption to SQLite.
//                      ✅ Use for: structured relational data, complex queries.
// ─────────────────────────────────────────────────────────────────
// GOLDEN RULE: Never store anything in plain storage that would
// cause a security incident if an attacker read it.''',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}