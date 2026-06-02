import 'package:flutter/material.dart';
import '../../data/models/isar_contact.dart';
import '../../data/services/isar_service.dart';
import 'package:isar/isar.dart';

/// [IsarViewModel] - The state holder for the Isar educational screen and lab.
/// Implements the MVVM architecture: wraps IsarService calls, exposes
/// read-only observable state, and notifies the View via ChangeNotifier.
class IsarViewModel extends ChangeNotifier {
  // Access the singleton IsarService
  final IsarService _service = IsarService.instance;

  // ──────────────────────────────────────────────────────────────────────────
  // Private State
  // ──────────────────────────────────────────────────────────────────────────
  bool _isInitialized = false;
  List<IsarContact> _contacts = [];
  List<IsarContact> _filteredContacts = [];
  String _activeRoleFilter = 'All';
  String _searchQuery = '';
  final List<String> _consoleLogs = [];
  bool _isSearching = false;
  bool _isRollbackRunning = false;
  bool _isConcurrencyRunning = false;

  // ──────────────────────────────────────────────────────────────────────────
  // Public Read-Only Getters
  // ──────────────────────────────────────────────────────────────────────────
  bool get isInitialized => _isInitialized;
  List<IsarContact> get contacts => _filteredContacts;
  List<IsarContact> get allContacts => _contacts;
  String get activeRoleFilter => _activeRoleFilter;
  String get searchQuery => _searchQuery;
  List<String> get consoleLogs => _consoleLogs;
  bool get isSearching => _isSearching;
  bool get isRollbackRunning => _isRollbackRunning;
  bool get isConcurrencyRunning => _isConcurrencyRunning;
  int get totalCount => _contacts.length;

  /// Initializes the Isar database and loads the initial data snapshot.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // FLOW: Step 1 - Initialize the Isar database service (opens .isar file).
      await _service.init();

      // FLOW: Step 2 - Load the initial contact list from the database.
      _contacts = await _service.getAllContacts();
      _filteredContacts = List.from(_contacts);

      _isInitialized = true;

      // FLOW: Step 3 - Log system initialization details for learning.
      _addLog('SYSTEM', 'await Isar.open([IsarContactSchema]) opened contacts_db.isar');
      _addLog('SYSTEM', 'IsarContact collection loaded: ${_contacts.length} records.');

      notifyListeners();
    } catch (e) {
      _addLog('ERROR', 'Isar initialization failed: $e');
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CREATE / UPDATE
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates a new IsarContact and persists it inside an ACID write transaction.
  Future<void> createContact({
    required String name,
    required String email,
    required String role,
    String? street,
    String? city,
    String? zipCode,
  }) async {
    if (name.trim().isEmpty || email.trim().isEmpty) {
      _addLog('WARNING', 'Create aborted: name and email cannot be empty.');
      notifyListeners();
      return;
    }

    try {
      final hasAddress = (street != null && street.trim().isNotEmpty) ||
          (city != null && city.trim().isNotEmpty) ||
          (zipCode != null && zipCode.trim().isNotEmpty);

      // FLOW: Step 1 - Build the IsarContact model using field-by-field assignment.
      // id = Isar.autoIncrement tells Isar to assign the next integer ID automatically.
      final contact = IsarContact()
        ..name = name.trim()
        ..email = email.trim()
        ..role = role
        ..createdAt = DateTime.now()
        ..address = hasAddress
            ? IsarAddress(
                street: street?.trim(),
                city: city?.trim(),
                zipCode: zipCode?.trim(),
              )
            : null;

      // FLOW: Step 2 - Persist inside a writeTxn() (ACID guaranteed).
      final newId = await _service.putContact(contact);

      // FLOW: Step 3 - Reload fresh list from DB.
      await _refreshContacts();

      // FLOW: Step 4 - Log the exact Isar code that executed.
      _addLog(
        'CRUD (Create)',
        'await isar.writeTxn(() => isar.isarContacts.put(contact)) → assigned id: $newId',
      );

      notifyListeners();
    } catch (e) {
      _addLog('ERROR', 'Failed to create contact: $e');
      notifyListeners();
    }
  }

  /// Updates an existing contact by id (put() with existing id = update).
  Future<void> updateContact({
    required Id id,
    required String name,
    required String email,
    required String role,
    String? street,
    String? city,
    String? zipCode,
  }) async {
    try {
      // FLOW: Step 1 - Fetch the existing record first.
      final existing = await _service.getContactById(id);
      if (existing == null) {
        _addLog('WARNING', 'Update aborted: contact id $id not found.');
        return;
      }

      final hasAddress = (street != null && street.trim().isNotEmpty) ||
          (city != null && city.trim().isNotEmpty) ||
          (zipCode != null && zipCode.trim().isNotEmpty);

      // FLOW: Step 2 - Mutate the object fields and re-put it.
      // Isar identifies this as an update because the id already exists.
      existing
        ..name = name.trim()
        ..email = email.trim()
        ..role = role
        ..address = hasAddress
            ? IsarAddress(
                street: street?.trim(),
                city: city?.trim(),
                zipCode: zipCode?.trim(),
              )
            : null;

      await _service.putContact(existing);

      // FLOW: Step 3 - Reload fresh data.
      await _refreshContacts();

      _addLog(
        'CRUD (Update)',
        'await isar.writeTxn(() => isar.isarContacts.put(contact)) updated id: $id',
      );

      notifyListeners();
    } catch (e) {
      _addLog('ERROR', 'Failed to update contact id $id: $e');
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DELETE
  // ──────────────────────────────────────────────────────────────────────────

  /// Deletes a contact by its auto-incremented primary key.
  Future<void> deleteContact(Id id) async {
    try {
      // FLOW: isar.isarContacts.delete(id) is an O(1) primary-key delete
      // wrapped in writeTxn() for ACID compliance.
      final deleted = await _service.deleteContact(id);

      if (deleted) {
        await _refreshContacts();
        _addLog(
          'CRUD (Delete)',
          'await isar.writeTxn(() => isar.isarContacts.delete($id)) removed record.',
        );
      }

      notifyListeners();
    } catch (e) {
      _addLog('ERROR', 'Failed to delete contact id $id: $e');
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FILTER & SEARCH (Read-Only Queries)
  // ──────────────────────────────────────────────────────────────────────────

  /// Searches contacts by name (case-insensitive partial match).
  Future<void> searchContacts(String query) async {
    _searchQuery = query;
    _isSearching = query.isNotEmpty;

    if (query.trim().isEmpty) {
      _filteredContacts = List.from(_contacts);
      _activeRoleFilter = 'All';
      notifyListeners();
      return;
    }

    try {
      // FLOW: filter().nameContains() uses a full-collection scan since
      // "contains" can't use a B-tree index. Works great for moderate datasets.
      _filteredContacts = await _service.searchByName(query);

      _addLog(
        'READ (Query)',
        'await isar.isarContacts.filter().nameContains("$query", caseSensitive: false).findAll()',
      );

      notifyListeners();
    } catch (e) {
      _addLog('ERROR', 'Search failed: $e');
      notifyListeners();
    }
  }

  /// Filters contacts by role using the indexed roleEqualTo() query.
  Future<void> filterByRole(String role) async {
    _activeRoleFilter = role;
    _searchQuery = '';
    _isSearching = false;

    try {
      if (role == 'All') {
        _filteredContacts = List.from(_contacts);
        _addLog('READ (Query)', 'Cleared filter — showing all ${_contacts.length} contacts.');
      } else {
        // FLOW: roleEqualTo() uses the @Index on 'role' field for O(log n) lookup.
        _filteredContacts = await _service.filterByRole(role);
        _addLog(
          'READ (Query)',
          'await isar.isarContacts.filter().roleEqualTo("$role").sortByName().findAll() → ${_filteredContacts.length} results',
        );
      }

      notifyListeners();
    } catch (e) {
      _addLog('ERROR', 'Filter by role failed: $e');
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MAINTENANCE / CONSOLE
  // ──────────────────────────────────────────────────────────────────────────

  /// Wipes the entire IsarContact collection (factory reset).
  Future<void> resetAll() async {
    try {
      // FLOW: clear() runs inside writeTxn internally.
      await _service.clearAll();
      _contacts.clear();
      _filteredContacts.clear();
      _consoleLogs.clear();
      _activeRoleFilter = 'All';
      _searchQuery = '';
      _isSearching = false;

      _addLog('SYSTEM', 'await isar.writeTxn(() => isar.isarContacts.clear()) — all records wiped.');

      notifyListeners();
    } catch (e) {
      _addLog('ERROR', 'Failed to reset Isar database: $e');
      notifyListeners();
    }
  }

  /// Reloads both the full list and applies the current filter.
  Future<void> _refreshContacts() async {
    _contacts = await _service.getAllContacts();

    if (_activeRoleFilter != 'All') {
      _filteredContacts = await _service.filterByRole(_activeRoleFilter);
    } else if (_searchQuery.isNotEmpty) {
      _filteredContacts = await _service.searchByName(_searchQuery);
    } else {
      _filteredContacts = List.from(_contacts);
    }
  }

  /// Adds a timestamped line to the interactive console log (newest at top).
  void _addLog(String actionType, String message) {
    final now = DateTime.now();
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}:"
        "${now.second.toString().padLeft(2, '0')}";
    _consoleLogs.insert(0, "[$timeStr] $actionType: $message");
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TRANSACTION ROLLBACK & CONCURRENCY DEMOS
  // ──────────────────────────────────────────────────────────────────────────

  /// Runs the transaction rollback educational demo.
  Future<void> runTransactionRollbackDemo() async {
    if (_isRollbackRunning) return;
    _isRollbackRunning = true;
    _addLog('DEMO', 'Initializing Transaction Rollback Demo...');
    notifyListeners();

    try {
      await _service.demoTransactionRollback();
      _addLog('DEMO (Rollback)', 'Success: Transaction finished without exceptions (should not happen in this demo).');
    } catch (e) {
      _addLog('DEMO (Rollback)', 'Exception caught: $e');
      _addLog('DEMO (Rollback)', 'ACID Rollback confirmed: No changes were committed to the database.');
    } finally {
      _isRollbackRunning = false;
      await _refreshContacts();
      notifyListeners();
    }
  }

  /// Runs the multi-isolate/concurrent read-write demo.
  Future<void> runConcurrencyDemo() async {
    if (_isConcurrencyRunning) return;
    _isConcurrencyRunning = true;
    _addLog('DEMO', 'Initializing Multi-Isolate Concurrency Demo...');
    notifyListeners();

    try {
      final steps = await _service.demoConcurrency();
      for (final step in steps) {
        _addLog('DEMO (Concurrency)', step);
      }
    } catch (e) {
      _addLog('ERROR', 'Concurrency demo failed: $e');
    } finally {
      _isConcurrencyRunning = false;
      await _refreshContacts();
      notifyListeners();
    }
  }
}
