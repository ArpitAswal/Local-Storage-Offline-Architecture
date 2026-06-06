# Secure Storage (flutter_secure_storage)

`flutter_secure_storage` stores key-value pairs using the platform's native hardware-backed encryption. Unlike SharedPreferences or Hive, data is encrypted with AES-256 and the encryption keys live inside a hardware security module (Android KeyStore or iOS Secure Enclave) that NEVER exposes them to user-space code.

---

## 1. Why Not SharedPreferences or Hive?

**❌ WRONG — Never store secrets in SharedPreferences or Hive**
SharedPreferences stores data as plain text XML. Hive uses binary format but is NOT encrypted by default. Both can be extracted via adb on unprotected or rooted devices.

**✅ CORRECT — Use flutter_secure_storage for ALL secrets**
The AES key never leaves the hardware security module.

> **🔐 Security Rule:** ANY piece of data that would cause a security incident if stolen MUST go into Secure Storage:
> - JWT access tokens & OAuth refresh tokens
> - API keys and service credentials
> - Biometric auth secrets and encryption seeds
> - User passwords (before hashing, during auth flow)
> - Private keys for E2E encryption

---

## 2. How Encryption Works Per Platform

**Android (API 23+)**
- Key Cipher: `RSA/ECB/OAEPWithSHA-256AndMGF1Padding`
- Storage Cipher: `AES/GCM/NoPadding` (authenticated encryption)
- Flow: AES key is generated and wrapped with RSA. The RSA private key is stored in Android KeyStore. Data is encrypted with AES-GCM and stored in SharedPreferences.

**iOS / macOS**
- Apple Keychain Services (Secure Enclave on supported devices).
- Keys never leave the chip.
- Keychain is sandboxed per app bundle ID.

**Windows & Linux**
- Windows: DPAPI (Data Protection API).
- Linux: `libsecret` (GNOME Keyring or KWallet).

---

## 3. Setup & pubspec.yaml

Add dependency:
```yaml
dependencies:
  flutter_secure_storage: ^10.3.1
```

**⚠️ Android Requirements:**
- Min SDK must be 23+ in `android/app/build.gradle` (for AES-GCM).
- Disable auto-backup in `AndroidManifest.xml` (`android:allowBackup="false"`) to prevent encrypted data corruption on restore.

**⚠️ macOS Requirements:**
- Add Keychain Sharing capability to entitlements.

---

## 4. Creating an Instance

### Default (Recommended)
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();
```

### With Biometric Authentication (Optional)
```dart
final storage = FlutterSecureStorage(
  aOptions: AndroidOptions.biometric(
    enforceBiometrics: false, // Graceful degradation if no biometrics
    biometricPromptTitle: 'Unlock App',
  ),
);
```

---

## 5. Full CRUD API

### WRITE
```dart
// Values must be Strings. Serialize objects to JSON first.
await storage.write(key: 'jwt_token', value: 'Bearer eyJhbG...');
```

### READ
```dart
// Returns String or null
final String? token = await storage.read(key: 'jwt_token');
```

### READ ALL
```dart
final Map<String, String> allSecrets = await storage.readAll();
```

### CONTAINS KEY
```dart
// Efficient check without reading the value
final bool hasToken = await storage.containsKey(key: 'jwt_token');
```

### DELETE & DELETE ALL
```dart
await storage.delete(key: 'jwt_token');

// Secure logout / vault wipe
await storage.deleteAll();
```

> **⚡ Production Token Pattern:**
> - Login → `storage.write`
> - Startup → `storage.containsKey` → decide route
> - API Call → `storage.read`
> - Refresh → `delete` + `write` (atomic)
> - Logout → `deleteAll()`

---

## 6. iOS Keychain Persistence

**⚠️ IMPORTANT:** Keychain items persist even after the app is UNINSTALLED on iOS!
If a user reinstalls the app, `storage.read()` will return the old tokens.

**Solution:** Clear Keychain on first launch.
```dart
Future<void> clearKeychainOnFirstLaunch() async {
  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool('first_launch') ?? true;
  
  if (isFirstLaunch) {
    await storage.deleteAll();
    await prefs.setBool('first_launch', false);
  }
}
```

---

## 7. Security Comparison

- **SharedPreferences:** Plain text XML. NO encryption. Use for theme, flags.
- **Hive:** Binary format. NO encryption by default. Use for offline cache.
- **Secure Storage:** AES-256 via hardware. Sandboxed. Slower than SharedPreferences. Use for tokens and keys ONLY. Do NOT store large blobs.
- **SQLite / Drift:** Plain SQL. NO encryption by default (unless SQLCipher is used). Use for relational data.

---

## 8. Production Error Handling & Recovery

**Why Decryption Fails in Production:**
1. **Lockscreen changes:** User changes PIN, OS invalidates hardware keys.
2. **Backup & Restore:** Restoring cloud backup restores encrypted data but NOT hardware keys.
3. **Keystore corruptions:** Firmware glitches.

**Recovery Pattern:**
```dart
Future<String?> readSecureData(String key) async {
  try {
    return await storage.read(key: key);
  } on PlatformException catch (e) {
    // Decryption permanently failed. MUST call deleteAll() to clear corrupted entries.
    await storage.deleteAll();
    logoutAndRedirectToAuth();
    return null;
  }
}
```

> **⚡ Key Takeaway:** Never let secure storage decryption failures bubble up to crashes. Catch `PlatformException`, wipe the vault with `deleteAll()`, and redirect the user to re-authenticate.
