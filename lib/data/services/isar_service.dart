import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/isar_contact.dart';

/// [IsarService] - A Singleton service that manages all Isar database
/// lifecycle and CRUD operations.
///
/// Isar is a fully-async, high-performance NoSQL database for Flutter.
/// Unlike Hive, Isar provides:
///   - Auto-incremented integer primary keys (no manual ID management)
///   - Type-safe fluent query builders (generated at build time)
///   - ACID-compliant write transactions (writeTxn)
///   - Reactive Streams for auto-updating UI without setState()
class IsarService {
  // ──────────────────────────────────────────────────────────────────────────
  // 1. Singleton Pattern
  // Enforces a single Isar instance across the entire app lifecycle.
  // ──────────────────────────────────────────────────────────────────────────
  IsarService._internal();
  static final IsarService instance = IsarService._internal();

  // The Isar database instance — late since it requires async initialization
  late Isar _isar;

  // Flag to prevent double-initialization
  bool _isInitialized = false;

  // ──────────────────────────────────────────────────────────────────────────
  // 2. Initialization
  // Opens the Isar database with the IsarContact schema.
  // Must be called once before any CRUD methods are invoked.
  // ──────────────────────────────────────────────────────────────────────────

  /// Initializes the Isar instance and opens the IsarContactSchema collection.
  Future<void> init() async {
    if (_isInitialized) return;

    // FLOW: Step 1 - Get the app's document directory path using path_provider.
    // Isar stores its binary .isar files in this platform-specific directory.
    final dir = await getApplicationDocumentsDirectory();

    // FLOW: Step 2 - Open Isar with the desired collection schemas.
    // Isar.open() is the equivalent of Hive.initFlutter() + Hive.openBox().
    // Each schema is a generated descriptor created by build_runner.
    _isar = await Isar.open(
      [IsarContactSchema], // Generated from @collection IsarContact
      directory: dir.path,  // Persistent file storage location
      name: 'contacts_db',  // The .isar file will be named 'contacts_db.isar'
    );

    _isInitialized = true;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. CREATE / UPDATE (Write Transaction)
  // All write operations in Isar MUST be wrapped in writeTxn().
  // This guarantees ACID atomicity — either all writes succeed or none do.
  // ──────────────────────────────────────────────────────────────────────────

  /// Inserts a new contact or updates an existing one.
  ///
  /// FLOW:
  /// - If contact.id == Isar.autoIncrement, Isar assigns the next auto ID.
  /// - If contact.id is an existing ID, Isar overwrites that record.
  Future<Id> putContact(IsarContact contact) async {
    // FLOW: Step 1 - Open a write transaction (ensures ACID compliance).
    // writeTxn() automatically commits if the callback returns, or rolls back on error.
    return await _isar.writeTxn(() async {
      // FLOW: Step 2 - isar.isarContacts is the generated typed collection accessor.
      // put() inserts a new record (if new id) or updates (if existing id).
      return await _isar.isarContacts.put(contact);
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. READ Operations (No Transaction Required)
  // Read operations in Isar are non-transactional and run on a background thread.
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns all contacts sorted by name ascending.
  Future<List<IsarContact>> getAllContacts() async {
    // FLOW: Use the generated fluent query builder. sortByName() uses the
    // @Index we declared on the 'name' field for O(log n) sorting.
    return await _isar.isarContacts.where().sortByName().findAll();
  }

  /// Finds a single contact by their auto-incremented integer id.
  Future<IsarContact?> getContactById(Id id) async {
    // FLOW: .get(id) is a direct primary-key lookup — the fastest possible read.
    return await _isar.isarContacts.get(id);
  }

  /// Filters contacts whose name contains the given [query] (case-insensitive).
  ///
  /// This demonstrates Isar's powerful filter() builder — the type-safe
  /// alternative to writing raw SQL WHERE clauses.
  Future<List<IsarContact>> searchByName(String query) async {
    // FLOW: filter() accesses non-indexed fields via a full scan.
    // nameContains() is generated from the 'name' field name automatically.
    return await _isar.isarContacts
        .filter()
        .nameContains(query, caseSensitive: false)
        .findAll();
  }

  /// Filters contacts whose role exactly matches [role].
  Future<List<IsarContact>> filterByRole(String role) async {
    // FLOW: roleEqualTo() uses the @Index we placed on 'role'
    // making this an O(log n) index lookup — not a full table scan.
    return await _isar.isarContacts
        .filter()
        .roleEqualTo(role)
        .sortByName()
        .findAll();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 5. DELETE Operations (Write Transaction)
  // Deletions also require a writeTxn() for ACID compliance.
  // ──────────────────────────────────────────────────────────────────────────

  /// Deletes a single contact by their primary key id.
  Future<bool> deleteContact(Id id) async {
    return await _isar.writeTxn(() async {
      // FLOW: .delete(id) is an O(1) primary-key delete.
      return await _isar.isarContacts.delete(id);
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 6. Reactive Watchers (Streams)
  // Isar Watchers are one of its most powerful features.
  // They emit new values whenever the watched data changes in the database —
  // enabling real-time UI updates without setState() or manual polling.
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns a reactive stream that emits a fresh list of all contacts
  /// every time any contact is created, updated, or deleted.
  Stream<List<IsarContact>> watchAllContacts() {
    // FLOW: .watch(fireImmediately: true) emits the current list immediately
    // upon subscription, then re-emits after every write transaction that
    // affects the IsarContact collection.
    return _isar.isarContacts
        .where()
        .sortByName()
        .watch(fireImmediately: true);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 7. Utility / Maintenance
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns the total number of contacts stored in the collection.
  Future<int> getCount() async {
    return await _isar.isarContacts.count();
  }

  /// Clears all records from the IsarContact collection inside a transaction.
  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.isarContacts.clear();
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 8. Advanced Demos: Error Handling & Concurrency
  // ──────────────────────────────────────────────────────────────────────────

  /// Demonstrates Isar's transactional rollback.
  /// If an error occurs inside a writeTxn, all changes made inside that transaction
  /// are completely rolled back, leaving the database unmodified.
  Future<void> demoTransactionRollback() async {
    final initialCount = await getCount();

    try {
      await _isar.writeTxn(() async {
        // Create and insert a contact
        final contact = IsarContact()
          ..name = "Rollback Test Contact"
          ..email = "rollback@test.com"
          ..role = "User"
          ..createdAt = DateTime.now();
        await _isar.isarContacts.put(contact);

        // Count inside the transaction would show it was added (isolated view)
        // But we deliberately throw an exception to trigger rollback
        throw Exception("Deliberate error to trigger ACID transaction rollback");
      });
    } catch (e) {
      // The exception is caught here
      // Verify that the count hasn't changed (rollback succeeded)
      final postCount = await getCount();
      if (initialCount == postCount) {
        rethrow; // Rethrow so the VM/UI can display/log the caught exception & proof of rollback
      } else {
        throw Exception("Rollback failed! DB contains uncommitted transaction data.");
      }
    }
  }

  /// Demonstrates multi-isolate / concurrent read-write behavior in Isar.
  /// Write transactions are serialized (queue-based single writer), but read transactions
  /// are non-blocking and can run concurrently on separate threads/isolates.
  Future<List<String>> demoConcurrency() async {
    final List<String> sequenceLogs = [];

    sequenceLogs.add("Step 1: Starting simulated long write transaction (takes 2 seconds)...");

    // We launch the write transaction asynchronously but don't await it immediately
    final writeFuture = _isar.writeTxn(() async {
      final contact = IsarContact()
        ..name = "Concurrency Temp Contact"
        ..email = "concurrency@test.com"
        ..role = "User"
        ..createdAt = DateTime.now();
      final id = await _isar.isarContacts.put(contact);
      // Simulate database locked / write in progress by delaying
      await Future.delayed(const Duration(seconds: 2));
      sequenceLogs.add("Step 4 (Write): Write transaction committed for ID $id.");
    });

    // Give the write transaction a tiny headstart to ensure it acquires the write lock
    await Future.delayed(const Duration(milliseconds: 100));

    sequenceLogs.add("Step 2: Starting a concurrent READ query while write transaction is active...");

    // Run a read query - it should complete immediately because reads are non-blocking
    final readStart = DateTime.now();
    final contacts = await _isar.isarContacts.where().findAll();
    final readEnd = DateTime.now();
    final readDurationMs = readEnd.difference(readStart).inMilliseconds;

    sequenceLogs.add("Step 3 (Read): Concurrent READ completed in ${readDurationMs}ms (Read succeeded without waiting for write lock!). Found ${contacts.length} contacts.");

    // Now wait for the write transaction to complete
    await writeFuture;
    sequenceLogs.add("Step 5: Clean up - removing concurrency temp contact...");

    // Delete the temporary contact
    await _isar.writeTxn(() async {
      final temp = await _isar.isarContacts.filter().nameEqualTo("Concurrency Temp Contact").findFirst();
      if (temp != null) {
        await _isar.isarContacts.delete(temp.id);
      }
    });
    sequenceLogs.add("Step 6: Concurrency demonstration complete!");

    return sequenceLogs;
  }
}
