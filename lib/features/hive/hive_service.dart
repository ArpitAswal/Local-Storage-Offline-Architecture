import 'package:hive_flutter/hive_flutter.dart';
import 'models/user.dart';

/// [HiveService] - A thread-safe Singleton service that manages
/// NoSQL persistence using the Hive local database engine.
/// 
/// It exposes operations to handle primitive key-value data as well as 
/// serialized custom objects using custom TypeAdapters.
class HiveService {
  // ───────────────────────────────────────────────────────────────────────────
  // 1. Private Constructor & Singleton Instance
  // Enforces a single instance throughout the lifecycle of the application.
  // ───────────────────────────────────────────────────────────────────────────
  HiveService._internal();
  static final HiveService instance = HiveService._internal();

  // Box Names
  // In Hive, a 'Box' is the logical equivalent of a Table in SQLite
  // or a Collection in MongoDB. It stores key-value pairs locally as a binary file.
  static const String primitiveBoxName = 'settings_box';
  static const String customBoxName = 'users_box';

  // State flag to track initialization
  bool _isInitialized = false;

  /// Initializes Hive, registers the custom User TypeAdapter, and opens required boxes.
  Future<void> init() async {
    if (_isInitialized) return;

    // FLOW: Step 1 - Register the generated custom User adapter.
    // This must be done BEFORE opening any box that stores the custom object,
    // otherwise Hive will throw a registration error.
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserAdapter());
    }

    // FLOW: Step 2 - Open the Primitive Key-Value Box.
    // We typecast this box to store String keys and dynamic values.
    await Hive.openBox<dynamic>(primitiveBoxName);

    // FLOW: Step 3 - Open the Custom Object User Box.
    // We typecast this box to store String keys and User objects.
    await Hive.openBox<User>(customBoxName);

    _isInitialized = true;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. Primitive (Static Data Types) CRUD Methods
  // Operates on primitive values like Strings, ints, doubles, and booleans.
  // ───────────────────────────────────────────────────────────────────────────

  /// Gets the opened primitive box safely.
  Box<dynamic> get _primitiveBox {
    if (!Hive.isBoxOpen(primitiveBoxName)) {
      throw StateError("Primitive Box '$primitiveBoxName' is not open!");
    }
    return Hive.box<dynamic>(primitiveBoxName);
  }

  /// Exposes all key-value entries in the primitive box.
  Map<String, dynamic> getAllPrimitives() {
    final Map<String, dynamic> map = {};
    for (var key in _primitiveBox.keys) {
      map[key.toString()] = _primitiveBox.get(key);
    }
    return map;
  }

  /// Writes/Updates a key-value entry in Hive.
  /// 
  /// FLOW:
  /// - Create: If the key doesn't exist, Hive adds it.
  /// - Update: If the key exists, Hive overwrites the value.
  Future<void> putPrimitive(String key, dynamic value) async {
    await _primitiveBox.put(key, value);
  }

  /// Reads a value from the primitive box. Returns null if not found.
  dynamic getPrimitive(String key) {
    return _primitiveBox.get(key);
  }

  /// Deletes a key-value pair from the primitive box.
  Future<void> deletePrimitive(String key) async {
    await _primitiveBox.delete(key);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. Custom Data Type (User Model) CRUD Methods
  // Operates on serialized custom User class instances.
  // ───────────────────────────────────────────────────────────────────────────

  /// Gets the opened custom User box safely.
  Box<User> get _userBox {
    if (!Hive.isBoxOpen(customBoxName)) {
      throw StateError("Users Box '$customBoxName' is not open!");
    }
    return Hive.box<User>(customBoxName);
  }

  /// Exposes all stored User objects.
  List<User> getAllUsers() {
    // FLOW: Return values from the box as a clean List
    return _userBox.values.toList();
  }

  /// Writes/Updates a User object in Hive using their ID as the key.
  Future<void> putUser(User user) async {
    // FLOW: We use the user.id as the unique lookup key inside the box.
    await _userBox.put(user.id, user);
  }

  /// Reads a User object by their unique ID.
  User? getUser(String id) {
    return _userBox.get(id);
  }

  /// Deletes a User object by their unique ID.
  Future<void> deleteUser(String id) async {
    await _userBox.delete(id);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. Utility / Maintenance Operations
  // ───────────────────────────────────────────────────────────────────────────

  /// Erases all stored keys from both boxes to reset the database.
  Future<void> clearAll() async {
    await _primitiveBox.clear();
    await _userBox.clear();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. Advanced Feature Demonstrations
  // ───────────────────────────────────────────────────────────────────────────

  /// Demonstrates LazyBox behavior: writes 3 entries and reads them back asynchronously.
  /// Returns a list of log strings describing each operation for the terminal console.
  Future<List<String>> lazyBoxDemo() async {
    const String lazyBoxName = 'lazy_demo_box';
    final List<String> logs = [];

    // FLOW: Step 1 - Open a LazyBox (only keys are loaded into RAM, not values)
    final LazyBox<String> lazyBox = await Hive.openLazyBox<String>(lazyBoxName);
    logs.add('openLazyBox<String>(\'$lazyBoxName\') opened — ${lazyBox.keys.length} keys in RAM.');

    // FLOW: Step 2 - Write 3 string values (same API as regular Box)
    await lazyBox.put('item_1', 'Flutter');
    await lazyBox.put('item_2', 'Hive');
    await lazyBox.put('item_3', 'LazyBox');
    logs.add('put(\'item_1\', \'Flutter\'), put(\'item_2\', \'Hive\'), put(\'item_3\', \'LazyBox\') written.');
    logs.add('Keys in RAM now: ${lazyBox.keys.toList()} — values still ON DISK only.');

    // FLOW: Step 3 - Read values asynchronously (each .get() triggers a disk read)
    final v1 = await lazyBox.get('item_1');
    final v2 = await lazyBox.get('item_2');
    final v3 = await lazyBox.get('item_3');
    logs.add('await lazyBox.get(\'item_1\') → \'$v1\' (async disk read ✓)');
    logs.add('await lazyBox.get(\'item_2\') → \'$v2\' (async disk read ✓)');
    logs.add('await lazyBox.get(\'item_3\') → \'$v3\' (async disk read ✓)');

    // FLOW: Step 4 - Clean up the demo box
    await lazyBox.clear();
    await Hive.deleteBoxFromDisk(lazyBoxName);
    logs.add('Demo box cleared and deleted from disk.');

    return logs;
  }

  /// Demonstrates AES-256 encryption: generates a key, opens an encrypted box,
  /// writes a secret value, reads it back, and cleans up.
  /// Returns log strings for the terminal console.
  Future<List<String>> encryptionDemo() async {
    const String encBoxName = 'encrypted_demo_box';
    final List<String> logs = [];

    // FLOW: Step 1 - Generate a 256-bit (32-byte) cryptographically secure key
    final List<int> encryptionKey = Hive.generateSecureKey();
    logs.add('Hive.generateSecureKey() → ${encryptionKey.length * 8}-bit key generated (${encryptionKey.length} bytes).');

    // FLOW: Step 2 - Open a box with the AES cipher
    final Box<String> encryptedBox = await Hive.openBox<String>(
      encBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    logs.add('openBox<String>(\'$encBoxName\', encryptionCipher: HiveAesCipher(key)) opened.');
    logs.add('All values will be AES-256-CBC encrypted before being written to disk.');

    // FLOW: Step 3 - Write a sensitive value (it is stored encrypted on disk)
    const String secretValue = 'my_super_secret_api_key_12345';
    await encryptedBox.put('api_key', secretValue);
    logs.add('put(\'api_key\', \'$secretValue\') → encrypted and written to disk ✓');

    // FLOW: Step 4 - Read the value back (Hive decrypts transparently)
    final String? readBack = encryptedBox.get('api_key');
    logs.add('get(\'api_key\') → \'$readBack\' (decrypted transparently by HiveAesCipher ✓)');
    logs.add('Raw .hive file bytes are unreadable without the 256-bit key.');

    // FLOW: Step 5 - Clean up the demo encrypted box
    await encryptedBox.clear();
    await Hive.deleteBoxFromDisk(encBoxName);
    logs.add('Encrypted demo box deleted from disk. Key discarded from memory.');

    return logs;
  }
}
