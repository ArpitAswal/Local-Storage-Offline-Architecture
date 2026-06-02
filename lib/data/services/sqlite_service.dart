import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo_item.dart';

/// [SQLiteService] - Data access layer wrapping sqflite for the todos table.
///
/// Architecture:
///   - Singleton pattern: one database instance shared across the app
///   - Database opened lazily on first access via getter [_db]
///   - All public methods return typed Dart objects (not raw Maps)
///
/// SQLite Fundamentals:
///   - sqflite runs DB operations on a BACKGROUND THREAD automatically
///   - Uses WAL (Write-Ahead Logging) by default for better concurrency
///   - File path: Android → /data/data/{pkg}/databases/  iOS → Documents/
///   - Schema versioning: onCreate/onUpgrade callbacks handle migrations
class SQLiteService {
  // ──────────────────────────────────────────────────────────────────────────
  // 1. Singleton Pattern
  // ──────────────────────────────────────────────────────────────────────────
  SQLiteService._internal();
  static final SQLiteService instance = SQLiteService._internal();

  static const String _dbName = 'local_storage_demo.db';
  static const int _dbVersion = 2;
  static const String _tableName = 'todos';

  Database? _database;

  // ──────────────────────────────────────────────────────────────────────────
  // 2. Database Initialization — Lazy Singleton
  //
  // FLOW:
  //   1. getDatabasesPath() → returns the default DB directory per platform
  //      • Android: /data/data/<packageName>/databases/
  //      • iOS/macOS: Documents directory
  //   2. join(path, name) → constructs the full file path
  //   3. openDatabase():
  //      • Opens the .db file if it exists
  //      • Creates the .db file if it doesn't
  //      • Calls onCreate (first open) or onUpgrade (version bump)
  //   4. onCreate: runs CREATE TABLE DDL to define schema
  // ──────────────────────────────────────────────────────────────────────────
  Future<Database> get _db async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final fullPath = join(dbPath, _dbName);

    _database = await openDatabase(
      fullPath,
      version: _dbVersion,
      onConfigure: (db) async {
        // Enforce foreign keys (disabled by default in SQLite for backwards compatibility)
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
    );

    return _database!;
  }

  /// Called ONCE when the database file is created for the first time.
  /// Runs the CREATE TABLE DDL statement.
  ///
  /// FLOW: db.execute() runs raw SQL — perfect for DDL (Data Definition Language)
  /// like CREATE TABLE, CREATE INDEX, ALTER TABLE.
  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id   INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE $_tableName (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        title       TEXT NOT NULL,
        is_done     INTEGER NOT NULL DEFAULT 0,
        due_date    TEXT,
        priority    INTEGER NOT NULL DEFAULT 1,
        category_id INTEGER,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');
    // Optionally create indexes for faster queries on large datasets:
    // await db.execute('CREATE INDEX idx_priority ON $_tableName(priority)');
  }

  /// Called when the database VERSION is incremented (schema migration).
  ///
  /// FLOW: Add new columns or tables here without losing existing data.
  /// Always use ALTER TABLE ADD COLUMN (SQLite doesn't support DROP COLUMN).
  Future<void> _upgradeSchema(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id   INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');
      try {
        await db.execute('ALTER TABLE $_tableName ADD COLUMN category_id INTEGER REFERENCES categories(id) ON DELETE CASCADE');
      } catch (e) {
        // Column might already exist or table was already customized
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. CREATE (INSERT)
  //
  // FLOW:
  //   db.insert(table, map) compiles to:
  //   INSERT INTO todos (title, is_done, due_date, priority) VALUES (?, ?, ?, ?)
  //
  //   Returns: the newly auto-generated INTEGER id (AUTOINCREMENT).
  //
  //   conflictAlgorithm: what to do if a UNIQUE constraint is violated:
  //     • replace → overwrite the existing row
  //     • ignore  → skip the insert silently
  //     • fail    → throw an exception (default)
  // ──────────────────────────────────────────────────────────────────────────
  Future<int> insert(TodoItem item) async {
    final db = await _db;
    return await db.insert(
      _tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. READ ALL (SELECT *)
  //
  // FLOW:
  //   db.query(table) compiles to: SELECT * FROM todos ORDER BY priority DESC, id DESC
  //
  //   Returns: List<Map<String, Object?>>
  //   Each Map = one database row. Keys = column names. Values = cell values.
  //   Map entries are READ-ONLY from sqflite — copy the map if you need to modify it.
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<TodoItem>> getAll({String? filterStatus}) async {
    final db = await _db;

    List<Map<String, Object?>> rows;

    if (filterStatus == 'done') {
      // Filtered query using WHERE clause
      rows = await db.query(
        _tableName,
        where: 'is_done = ?',
        whereArgs: [1],                     // Always use ? placeholders to prevent SQL injection!
        orderBy: 'priority DESC, id DESC',
      );
    } else if (filterStatus == 'pending') {
      rows = await db.query(
        _tableName,
        where: 'is_done = ?',
        whereArgs: [0],
        orderBy: 'priority DESC, id DESC',
      );
    } else {
      // Unfiltered — return all rows
      rows = await db.query(
        _tableName,
        orderBy: 'priority DESC, id DESC',
      );
    }

    // Convert each Map row → typed TodoItem object
    return rows.map((row) => TodoItem.fromMap(row)).toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 5. READ by PRIORITY (SELECT WHERE + ORDER BY)
  //
  // FLOW: db.query() with where + whereArgs + orderBy
  //   Compiles to: SELECT * FROM todos WHERE priority = ? ORDER BY id DESC
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<TodoItem>> getByPriority(int priority) async {
    final db = await _db;
    final rows = await db.query(
      _tableName,
      where: 'priority = ?',
      whereArgs: [priority],
      orderBy: 'id DESC',
    );
    return rows.map((row) => TodoItem.fromMap(row)).toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 6. UPDATE
  //
  // FLOW:
  //   db.update(table, map, where, whereArgs) compiles to:
  //   UPDATE todos SET title=?, is_done=?, due_date=?, priority=? WHERE id=?
  //
  //   Returns: number of rows affected (should be 1 if the id exists).
  //   If WHERE matches 0 rows → returns 0 (no error thrown).
  // ──────────────────────────────────────────────────────────────────────────
  Future<int> update(TodoItem item) async {
    final db = await _db;
    return await db.update(
      _tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 7. DELETE by ID
  //
  // FLOW:
  //   db.delete(table, where, whereArgs) compiles to:
  //   DELETE FROM todos WHERE id = ?
  //
  //   Returns: number of rows deleted.
  // ──────────────────────────────────────────────────────────────────────────
  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 8. DELETE ALL (TRUNCATE via DELETE without WHERE)
  //
  // FLOW:
  //   db.delete(table) with no where = DELETE FROM todos
  //   This is faster than DROP + CREATE because it preserves the table schema.
  // ──────────────────────────────────────────────────────────────────────────
  Future<int> deleteAll() async {
    final db = await _db;
    return await db.delete(_tableName);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 9. COUNT — Aggregate query using rawQuery
  //
  // FLOW:
  //   db.rawQuery('SELECT COUNT(*) FROM todos') returns List<Map<String, Object?>>
  //   with one row: {'COUNT(*)': 3}
  //   Sqflite.firstIntValue() extracts the first integer from the result.
  // ──────────────────────────────────────────────────────────────────────────
  Future<int> count() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 10. BATCH — Execute multiple writes atomically in one round-trip
  //
  // FLOW:
  //   batch = db.batch()               → starts a new batch
  //   batch.insert(...)                → queues an insert
  //   batch.update(...)                → queues an update
  //   await batch.commit()             → executes ALL queued ops in one transaction
  //
  //   Batch is MUCH faster than calling db.insert() in a loop because it
  //   reduces Dart ↔ native bridge round-trips to ONE.
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> batchInsert(List<TodoItem> items) async {
    final db = await _db;
    final batch = db.batch();

    for (final item in items) {
      batch.insert(_tableName, item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // commit() executes all queued operations atomically.
    // noResult: true skips returning individual operation results for max performance.
    await batch.commit(noResult: true);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 11. TRANSACTION — Group operations atomically with manual rollback control
  //
  // FLOW:
  //   db.transaction((txn) async { ... })
  //   • ALL operations use `txn` (not `db`) inside the callback
  //   • If the callback completes without throwing → COMMIT
  //   • If the callback throws any error → ROLLBACK (all changes cancelled)
  //   • ⚠️ Using `db` inside a transaction will DEADLOCK — always use `txn`
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> toggleDoneTransaction(int id, bool currentStatus) async {
    final db = await _db;
    await db.transaction((txn) async {
      // Both reads and writes use `txn` inside the transaction
      await txn.update(
        _tableName,
        {'is_done': currentStatus ? 0 : 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 12. RAW SQL — For complex queries not covered by helpers
  //
  // FLOW:
  //   db.rawQuery(sql, args) → SELECT with ? placeholders
  //   Always use ? placeholders instead of string interpolation
  //   to prevent SQL injection attacks.
  // ──────────────────────────────────────────────────────────────────────────
  Future<Map<String, int>> getPriorityStats() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT priority, COUNT(*) as total
      FROM $_tableName
      GROUP BY priority
      ORDER BY priority DESC
    ''');

    final stats = <String, int>{};
    for (final row in result) {
      final p = row['priority'] as int;
      final label = p == 3 ? 'High' : p == 2 ? 'Medium' : 'Low';
      stats[label] = row['total'] as int;
    }
    return stats;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 13. FOREIGN KEYS & ERROR HANDLING DEMO
  // ──────────────────────────────────────────────────────────────────────────

  /// Demonstrates Foreign Key Enforcement & Cascading Deletes in SQLite.
  /// Shows catching DatabaseExceptions for foreign key violations.
  Future<List<String>> demoForeignKeysAndErrors() async {
    final db = await _db;
    final List<String> logs = [];

    // Step 1: Create a temporary category "Work"
    logs.add("Step 1: Inserting category 'Work'...");
    final categoryId = await db.insert(
      'categories',
      {'name': 'Work'},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    
    // Find actual ID in case category "Work" was ignored (already exists)
    var actualCatId = categoryId;
    if (actualCatId <= 0) {
      final rows = await db.query('categories', where: 'name = ?', whereArgs: ['Work']);
      actualCatId = rows.first['id'] as int;
    }
    logs.add("Category 'Work' active with ID: $actualCatId");

    // Step 2: Insert a todo linked to this category ID
    logs.add("Step 2: Inserting todo 'Write Unit Tests' referencing category ID $actualCatId...");
    final todoId = await db.insert(_tableName, {
      'title': 'Write Unit Tests',
      'is_done': 0,
      'due_date': '2026-06-02',
      'priority': 2,
      'category_id': actualCatId,
    });
    logs.add("Todo inserted successfully (id=$todoId, category_id=$actualCatId)");

    // Step 3: Attempt to violate foreign key constraints (insert under non-existent category 999)
    logs.add("Step 3: Attempting to insert todo referencing non-existent category 999...");
    try {
      await db.insert(_tableName, {
        'title': 'Orphaned Task',
        'is_done': 0,
        'due_date': '2026-06-02',
        'priority': 1,
        'category_id': 999, // Invalid ID!
      });
      logs.add("❌ FAILURE: Insert succeeded! Foreign keys are NOT being enforced.");
    } on DatabaseException catch (e) {
      logs.add("✅ SUCCESS: Caught expected DatabaseException!");
      logs.add("Details: ${e.toString().trim()}");
    }

    // Step 4: Delete the category and verify cascade delete of the todo
    logs.add("Step 4: Deleting category 'Work' (ID $actualCatId) to test ON DELETE CASCADE...");
    await db.delete('categories', where: 'id = ?', whereArgs: [actualCatId]);

    // Check if the todo still exists
    final todoCheck = await db.query(_tableName, where: 'id = ?', whereArgs: [todoId]);
    if (todoCheck.isEmpty) {
      logs.add("✅ CASCADE SUCCESS: Todo (id=$todoId) was automatically deleted when Category was deleted!");
    } else {
      logs.add("❌ CASCADE FAILURE: Todo (id=$todoId) still exists in DB!");
      // Clean up manually if cascade failed
      await db.delete(_tableName, where: 'id = ?', whereArgs: [todoId]);
    }

    return logs;
  }
}
