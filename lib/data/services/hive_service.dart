import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';

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
}
