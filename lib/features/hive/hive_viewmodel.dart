import 'package:flutter/material.dart';
import 'hive_service.dart';
import 'models/user.dart';

/// [HiveViewModel] - The state holder for the Hive educational screen and lab.
/// Implements the MVVM architecture by wrapping business/persistence calls,
/// exposing read-only data, and notifying listening views of state updates.
class HiveViewModel extends ChangeNotifier {
  // Access singleton HiveService
  final HiveService _service = HiveService.instance;

  // Private states
  bool _isInitialized = false;
  Map<String, dynamic> _primitiveData = {};
  List<User> _users = [];
  final List<String> _consoleLogs = [];
  bool _isLazyBoxRunning = false;
  bool _isEncryptionRunning = false;

  // Read-only getters for the UI View layer
  bool get isInitialized => _isInitialized;
  Map<String, dynamic> get primitiveData => _primitiveData;
  List<User> get users => _users;
  List<String> get consoleLogs => _consoleLogs;
  bool get isLazyBoxRunning => _isLazyBoxRunning;
  bool get isEncryptionRunning => _isEncryptionRunning;

  /// Initializes the Hive database, registers the adapter, and pulls the initial data.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // FLOW: Step 1 - Initialize high-level database boxes
      await _service.init();

      // FLOW: Step 2 - Read current snapshot of primitive key-values from Hive Box
      _primitiveData = _service.getAllPrimitives();

      // FLOW: Step 3 - Read current list of custom User objects from Hive Box
      _users = _service.getAllUsers();

      _isInitialized = true;

      // FLOW: Step 4 - Add system diagnostic console logs for user visibility
      _addLog('SYSTEM', 'Hive.initFlutter() successfully run.');
      _addLog('SYSTEM', 'Hive.registerAdapter(UserAdapter()) registered to index typeId 0.');
      _addLog('BOX', 'Opened primitive Box: Hive.openBox<dynamic>(\'settings_box\') [Size: ${_primitiveData.length} entries]');
      _addLog('BOX', 'Opened custom User Box: Hive.openBox<User>(\'users_box\') [Size: ${_users.length} records]');

      notifyListeners();
    } catch (e) {
      _addLog('ERROR', 'Failed to initialize Hive database: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Primitive CRUD Operations
  // ───────────────────────────────────────────────────────────────────────────

  /// Saves or updates a primitive key-value entry.
  Future<void> savePrimitive(String key, String value) async {
    if (key.trim().isEmpty) {
      _addLog('WARNING', 'Save aborted: Key cannot be empty.');
      return;
    }

    try {
      // FLOW: Step 1 - Check if this is a Create or Update operation
      final exists = _primitiveData.containsKey(key);

      // FLOW: Step 2 - Call local persistence layer
      await _service.putPrimitive(key, value);

      // FLOW: Step 3 - Reload fresh data snapshot
      _primitiveData = _service.getAllPrimitives();

      // FLOW: Step 4 - Generate educational log explaining the CRUD event
      if (exists) {
        _addLog('CRUD (Update)', 'await box.put(\'$key\', \'$value\') updated existing key in settings_box.');
      } else {
        _addLog('CRUD (Create)', 'await box.put(\'$key\', \'$value\') added a new primitive entry to settings_box.');
      }

      notifyListeners();
    } catch (e) {
      _addLog('ERROR', 'Failed to write primitive to Hive: $e');
    }
  }

  /// Deletes a key-value entry by key.
  Future<void> deletePrimitive(String key) async {
    try {
      // FLOW: Step 1 - Call persistence layer to delete key
      await _service.deletePrimitive(key);

      // FLOW: Step 2 - Sync local viewmodel copy
      _primitiveData = _service.getAllPrimitives();

      // FLOW: Step 3 - Log the exact Hive execution command
      _addLog('CRUD (Delete)', 'await box.delete(\'$key\') removed key from settings_box.');

      notifyListeners();
    } catch (e) {
      _addLog('ERROR', 'Failed to delete key \'$key\': $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Custom Object CRUD Operations
  // ───────────────────────────────────────────────────────────────────────────

  /// Creates a new User object or edits an existing one, serializing it to binary.
  Future<void> saveUser({
    required String name,
    required String email,
    required String role,
    String? existingId,
  }) async {
    if (name.trim().isEmpty || email.trim().isEmpty) {
      _addLog('WARNING', 'Save aborted: User Name and Email cannot be empty.');
      return;
    }

    try {
      // FLOW: Step 1 - Check if updating or creating
      final isUpdating = existingId != null && existingId.isNotEmpty;
      final String id = isUpdating ? existingId : DateTime.now().millisecondsSinceEpoch.toString();

      // FLOW: Step 2 - Instantiate custom model class
      final user = User(
        id: id,
        name: name.trim(),
        email: email.trim(),
        role: role,
      );

      // FLOW: Step 3 - Save custom object into the Box using put(key, value)
      await _service.putUser(user);

      // FLOW: Step 4 - Reload state and log details
      _users = _service.getAllUsers();

      if (isUpdating) {
        _addLog('CRUD (Update)', 'await box.put(\'$id\', User(...)) updated User record using registered TypeAdapter.');
      } else {
        _addLog('CRUD (Create)', 'await box.put(\'$id\', User(...)) created new User record and auto-serialized to binary.');
      }

      notifyListeners();
    } catch (e) {
      _addLog('ERROR', 'Failed to save User: $e');
    }
  }

  /// Deletes a custom User object by key ID.
  Future<void> deleteUser(String id) async {
    try {
      // FLOW: Step 1 - Call persistence layer to delete the custom object
      await _service.deleteUser(id);

      // FLOW: Step 2 - Refresh local cached state list
      _users = _service.getAllUsers();

      // FLOW: Step 3 - Log deletion command
      _addLog('CRUD (Delete)', 'await box.delete(\'$id\') deleted custom User from users_box.');

      notifyListeners();
    } catch (e) {
      _addLog('ERROR', 'Failed to delete user \'$id\': $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Maintenance & Console Logger Helpers
  // ───────────────────────────────────────────────────────────────────────────

  /// Adds a highly readable timestamped message to the interactive console log.
  void _addLog(String actionType, String message) {
    final now = DateTime.now();
    final timeStr = 
        "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}:"
        "${now.second.toString().padLeft(2, '0')}";
    
    // We insert at position 0 so that the newest logs appear immediately at the top of the terminal screen.
    _consoleLogs.insert(0, "[$timeStr] $actionType: $message");
  }

  /// Factory resets all boxes, wiping the records and resetting logs.
  Future<void> resetAll() async {
    try {
      // FLOW: Step 1 - Clear both box persistent files
      await _service.clearAll();

      // FLOW: Step 2 - Wipe local state maps and lists
      _primitiveData.clear();
      _users.clear();
      _consoleLogs.clear();

      // FLOW: Step 3 - Print reset diagnostic logs
      _addLog('SYSTEM', 'await box.clear() successfully run on both active boxes.');
      _addLog('SYSTEM', 'Local database has been wiped clean.');

      notifyListeners();
    } catch (e) {
      _addLog('ERROR', 'Failed to wipe database boxes: $e');
    }
  }

  /// Demonstrates LazyBox: opens a lazy box, writes 3 entries, reads them back asynchronously.
  Future<void> demoLazyBox() async {
    _isLazyBoxRunning = true;
    notifyListeners();
    try {
      _addLog('BOX', 'Hive.openLazyBox<String>(\'lazy_demo\') — only KEYs loaded to RAM.');
      final results = await _service.lazyBoxDemo();
      for (final log in results) {
        _addLog('LazyBox', log);
      }
      _addLog('BOX', 'LazyBox demo complete. Values fetched asynchronously from disk.');
    } catch (e) {
      _addLog('ERROR', 'LazyBox demo failed: $e');
    } finally {
      _isLazyBoxRunning = false;
      notifyListeners();
    }
  }

  /// Demonstrates AES-256 encryption: generates a key, writes an encrypted value, reads it back.
  Future<void> demoEncryption() async {
    _isEncryptionRunning = true;
    notifyListeners();
    try {
      _addLog('SYSTEM', 'Generating 256-bit secure key: final key = Hive.generateSecureKey()');
      final results = await _service.encryptionDemo();
      for (final log in results) {
        _addLog('ENCRYPT', log);
      }
    } catch (e) {
      _addLog('ERROR', 'Encryption demo failed: $e');
    } finally {
      _isEncryptionRunning = false;
      notifyListeners();
    }
  }
}
