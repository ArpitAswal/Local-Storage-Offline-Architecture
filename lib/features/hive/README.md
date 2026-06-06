# Hive NoSQL Database

Hive is a lightning-fast, key-value NoSQL database built entirely in Dart. Instead of tables, SQL queries, or schema configurations, Hive saves data in binary files called 'Boxes'. It caches active boxes in memory for instant reads.

---

## 1. Core Database Architecture & Setup

Add to `pubspec.yaml`:
```yaml
dependencies:
  hive: ^2.2.3             # Hive runtime DB engine
  hive_flutter: ^1.1.0     # Flutter helpers: Hive.initFlutter()

dev_dependencies:
  build_runner: ^2.4.0     # Runs code generation
  hive_generator: ^2.0.1   # Generates TypeAdapter files
```
Platform Support: Android, iOS, macOS, Windows, Linux, Web.

Initialize in `main.dart` before `runApp()`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); // Sets up Hive file path automatically
  runApp(const MyApp());
}
```

> **💡 Why `initFlutter()`?** On mobile, the app sandbox path changes per install. `Hive.initFlutter()` resolves the correct directory automatically. On Web, it uses IndexedDB internally.

---

## 2. What are Hive Boxes?

Think of a Box as an XML file or a single table. All keys are unique Strings, and values can be any primitives or models.

```dart
// Open a Hive box
final Box settingsBox = await Hive.openBox('settings_box');

// Fetch the opened box synchronously from anywhere
final myBox = Hive.box('settings_box');
```
> **💡 Concept:** Because Hive caches all open boxes in memory, calling `Hive.box('name')` instantly returns the database synchronously! There's no blocking asynchronous read required after initialization.

---

## 3. CRUD on Primitive Data Types

Hive natively supports `double`, `int`, `String`, `bool`, `List`, `Map`, and `Uint8List` without needing custom code generators.

```dart
final Box box = Hive.box('settings_box');

// CREATE & UPDATE
await box.put('username', 'john_doe');

// READ (returns value or fallback default)
final String user = box.get('username', defaultValue: 'Guest');

// DELETE
await box.delete('username');

// WIPE ALL
await box.clear();
```

---

## 4. Storing Custom Objects (TypeAdapters)

To store custom classes, you must use TypeAdapters.

```dart
import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0) // Unique typeId (0-223)
class User extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String name;
  @HiveField(2) final String email;

  User({required this.id, required this.name, required this.email});
}
```

Run build_runner:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Register the adapter in `main()` BEFORE opening boxes that use them:
```dart
Hive.registerAdapter(UserAdapter());
```

### CRUD on Custom Objects
```dart
final Box<User> userBox = Hive.box<User>('users_box');

final newUser = User(id: 'u101', name: 'Alice', email: 'alice@mail.com');
await userBox.put(newUser.id, newUser);

final User? user = userBox.get('u101');
```

> **⚡ Superpower:** Since the class extends `HiveObject`, you can do: `user.name = 'Bob'; await user.save();` and `await user.delete();` directly!

---

## 5. LazyBox — Memory-Efficient for Large Datasets

**REGULAR Box:** All values loaded into RAM. Great for small datasets.
**LAZY Box:** Only KEYS loaded into RAM. Values loaded from disk ON DEMAND (asynchronously).

```dart
final LazyBox<Product> lazyBox = await Hive.openLazyBox<Product>('catalog_box');

// READ is async!
final Product? product = await lazyBox.get('p001'); // async read ⏳
```

To iterate over a LazyBox:
```dart
final keys = lazyBox.keys.toList(); // Sync
final List<Product> allProducts = [];
for (final key in keys) {
  final value = await lazyBox.get(key);
  if (value != null) allProducts.add(value);
}
```
> **⚠️ Do NOT use `lazyBox.values`** — it returns an `Iterable<Future<Product?>>`. Iterate keys instead.

---

## 6. AES-256 Encryption

Hive can encrypt values using a hardware-generated AES-256 key stored in `flutter_secure_storage`.

```dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorage = const FlutterSecureStorage();
var encryptionKeyString = await secureStorage.read(key: 'hive_aes_key');

if (encryptionKeyString == null) {
  final key = Hive.generateSecureKey();
  await secureStorage.write(key: 'hive_aes_key', value: base64UrlEncode(key));
  encryptionKeyString = base64UrlEncode(key);
}

final keyUint8List = base64Url.decode(encryptionKeyString);
final encryptedBox = await Hive.openBox<String>(
  'secure_notes_box',
  encryptionCipher: HiveAesCipher(keyUint8List),
);

// Encrypted automatically!
await encryptedBox.put('pin', '1234');
```

---

## 7. Compaction — Disk Space Cleanup

Hive uses an APPEND-ONLY format. Over time, deleted data accumulates as 'tombstones'. Compaction rewrites the file with only live entries.

```dart
// Auto compaction strategy
final box = await Hive.openBox(
  'products_box',
  compactionStrategy: (entries, deletedEntries) {
    return deletedEntries > 20; // Compact when 20+ deleted entries accumulate
  },
);

// Manual explicit compaction
await box.compact();
```

---

## 8. Error Handling & Schema Evolution

### Recovering from Corrupted Boxes
If the app crashes mid-write, Hive may throw a `HiveError`.
```dart
try {
  final box = await Hive.openBox<User>('users_box');
} catch (e) {
  if (e is HiveError) {
    // Nuclear option: delete corrupted file
    await Hive.deleteBoxFromDisk('users_box');
    final box = await Hive.openBox<User>('users_box');
  }
}
```

### Safe Schema Evolution Rules
When updating a `@HiveType` class:
1. **✅ Add new fields with ONLY new indexes** (e.g. `@HiveField(4)`).
2. **✅ New fields must be nullable (`?`) or have a default**.
3. **❌ NEVER change an existing index** (old data will corrupt!).
4. **❌ NEVER remove an index** (mark it `@Deprecated` instead).

---

## 9. Hive Comparison Cheat Sheet

| Feature | Hive | SharedPrefs | SQLite | Isar |
| :--- | :--- | :--- | :--- | :--- |
| **Data model** | Key-Value | Key-Value | Relational SQL | NoSQL ORM |
| **Schema required**| Optional ✅ | None ✅ | SQL DDL ⚠️ | Dart class ⚠️ |
| **Complex queries**| No ❌ | No ❌ | Full SQL ✅ | Fluent API ✅ |
| **Reactive streams**| `ValueListenable` ⚠️ | No ❌ | No ❌ | `watch()` ✅ |
| **AES-256 encrypt**| Built-in ✅ | No ❌ | SQLCipher plugin | No ❌ |
| **LazyBox (large)**| Yes ✅ | N/A | N/A | N/A |
| **Best use case** | Offline cache | App flags | Relational data | Fast NoSQL |
