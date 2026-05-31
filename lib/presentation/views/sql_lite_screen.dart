import 'package:flutter/material.dart';
import '../navigation/route_navigation.dart';
import '../widgets/extension_widgets.dart';
import 'sqlite_example.dart';

/// [SqlLiteScreen] — Educational guide for sqflite.
/// Covers: what SQLite is, setup, schema design, full CRUD with raw SQL
/// and helpers, transactions, batch operations, migrations, and type mapping.
class SqlLiteScreen extends StatelessWidget {
  const SqlLiteScreen({super.key});

  static const Color sqlColor = Color(0xFF00695C); // Teal 800

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
        title: const Text('SQLite (sqflite) Guide'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () =>
                  RouteNavigation.push(context, const SQLiteDemoView()),
              icon: Icon(Icons.science, size: 18, color: sqlColor),
              label: Text(
                'Try Lab',
                style: TextStyle(
                  color: sqlColor,
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
              // ── Hero ───────────────────────────────────────────────────
              context.headTitle(
                '🗄 sqflite: Embedded SQL Database for Flutter',
                sqlColor,
              ),
              context.dividerSpace(16),
              context.subHeadTitle(
                'sqflite is a Flutter plugin for SQLite — the most widely deployed database '
                'engine in the world (built into every Android, iOS, macOS, and Windows device). '
                'Unlike Hive or Isar, sqflite uses SQL: a standardized query language giving you '
                'full relational power: JOINs, WHERE/ORDER BY/GROUP BY, indexes, and ACID '
                'transactions. All DB operations run on a background thread automatically.',
              ),
              context.dividerSpace(16),

              // ── Section 1: When to Use SQLite ───────────────────────────
              context.headTitle('1. When to Use SQLite vs Other Storages', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('Choosing the right tool', sqlColor),
              context.contentSectionContainer(
                '''// ✅ USE SQFLITE WHEN:
//   • Data has RELATIONSHIPS (users → orders → order_items)
//   • You need complex queries: WHERE + AND/OR, JOIN, GROUP BY, aggregate
//   • Data has a fixed schema you want the DB to enforce (NOT NULL, UNIQUE)
//   • You need to query across multiple "tables" in one operation
//   • Filtering/sorting needs to happen AT THE DATABASE LEVEL (fast)

// Example: E-commerce app
//   users table: id, name, email
//   orders table: id, user_id (FK), total, created_at
//   SELECT u.name, COUNT(o.id) FROM users u JOIN orders o ON u.id=o.user_id
//   GROUP BY u.id ORDER BY COUNT(o.id) DESC  ← impossible in Hive/SharedPrefs

// ❌ DON'T USE SQFLITE WHEN:
//   • Data is simple key-value pairs → use SharedPreferences
//   • Data is schemaless / dynamic objects → use Hive
//   • Data needs to stay encrypted without extra libs → use SecureStorage
//   • You want reactive Streams from DB → use Drift (SQLite wrapper with streams)
//   • You need NO setup / code gen → use SharedPreferences or Hive''',
              ),
              context.dividerSpace(16),

              // ── Section 2: Setup ─────────────────────────────────────────
              context.headTitle('2. Setup — pubspec.yaml', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('Add the dependencies', sqlColor),
              context.contentSectionContainer(
                '''dependencies:
  sqflite: ^2.4.2+1   # The Flutter SQLite plugin (Flutter Favorite ⭐)
  path: ^1.9.0         # For join(dbsPath, 'mydb.db') — cross-platform path building

# No code generation required! sqflite works out of the box.
# No build_runner, no annotations, no generated files.
# Just pure Dart + SQL.

# Platform support:
#   ✅ Android  ✅ iOS  ✅ macOS
#   ❌ Web (use sqflite_common_ffi_web for experimental web support)
#   ❌ Windows/Linux (use sqflite_common_ffi for desktop)''',
              ),
              context.dividerSpace(16),

              // ── Section 3: Opening the Database ─────────────────────────
              context.headTitle('3. Opening a Database', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('openDatabase() — the entry point', sqlColor),
              context.contentSectionContainer(
                '''import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// STEP 1: Get the platform-specific database directory
//   Android → /data/data/<packageName>/databases/
//   iOS     → NSDocumentDirectory (Documents/)
//   macOS   → ~/Library/Application Support/
final dbPath = await getDatabasesPath();

// STEP 2: Build the full file path using path package
final fullPath = join(dbPath, 'my_app.db');

// STEP 3: Open (or create) the database
//   • If 'my_app.db' does NOT exist → creates the file + calls onCreate
//   • If 'my_app.db' EXISTS with same version → just opens it
//   • If 'my_app.db' EXISTS with OLD version → calls onUpgrade
final Database db = await openDatabase(
  fullPath,
  version: 1,            // Schema version — increment for migrations

  onCreate: (db, version) async {
    // ✅ Called ONCE on first launch — create your tables here
    await db.execute(\'\'\'
      CREATE TABLE users (
        id      INTEGER PRIMARY KEY AUTOINCREMENT,
        name    TEXT NOT NULL,
        email   TEXT UNIQUE NOT NULL,
        age     INTEGER
      )
    \'\'\');
  },

  onUpgrade: (db, oldVersion, newVersion) async {
    // ✅ Called when version bumps — add new columns / tables
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
    }
  },
);

// Most apps open the DB ONCE at startup and never close it.
// Closing is optional — SQLite releases resources when the app exits.
await db.close(); // Only if you explicitly want to free resources''',
              ),
              context.theoryContentText(
                '💡 Singleton Pattern: Always use a singleton for your database '
                'service so you never open multiple connections to the same .db file. '
                'Multiple open connections to the same file on Android reuse the '
                'same underlying SQLite object — but it\'s cleaner to manage one instance.',
              ),
              context.dividerSpace(16),

              // ── Section 4: Schema Design ──────────────────────────────────
              context.headTitle('4. Schema Design & Data Types', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('SQLite native types + Dart mapping', sqlColor),
              context.contentSectionContainer(
                '''// SQLite has 5 storage classes (type affinities):
//   INTEGER  → Dart: int       → stores whole numbers (-2^63 to 2^63-1)
//   REAL     → Dart: double    → stores floating-point numbers
//   TEXT     → Dart: String    → stores UTF-8 text strings
//   BLOB     → Dart: Uint8List → stores raw binary data
//   NULL     → Dart: null      → the absence of any value

// ⚠️ TYPE GOTCHAS — IMPORTANT FOR BEGINNERS:

// 1. BOOLEAN — SQLite has NO bool type!
//    Store as INTEGER with values 0 (false) or 1 (true):
CREATE TABLE settings (
  id       INTEGER PRIMARY KEY,
  is_dark  INTEGER NOT NULL DEFAULT 0   -- 0=false, 1=true
);
// In Dart: bool isDark = (map['is_dark'] as int) == 1;

// 2. DATETIME — SQLite has NO DateTime type!
//    Store as TEXT (ISO-8601) or INTEGER (milliseconds since epoch):
CREATE TABLE events (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT NOT NULL,
  created_at TEXT NOT NULL    -- Store as '2024-12-31T23:59:59.000'
);
// In Dart:
// Serialize:   map['created_at'] = DateTime.now().toIso8601String()
// Deserialize: DateTime.parse(map['created_at'] as String)

// 3. LIST / MAP — SQLite has NO array type!
//    Serialize to JSON string:
import 'dart:convert';
// Serialize:   map['tags'] = jsonEncode(['flutter', 'dart'])
// Deserialize: List tags = jsonDecode(map['tags'] as String)

// Common schema with all types demonstrated:
CREATE TABLE todos (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,  -- Auto-ID
  title     TEXT NOT NULL,                      -- Required string
  is_done   INTEGER NOT NULL DEFAULT 0,         -- Boolean as int
  due_date  TEXT,                               -- Nullable ISO date
  priority  INTEGER NOT NULL DEFAULT 1          -- Enum: 1/2/3
)''',
              ),
              context.dividerSpace(16),

              // ── Section 5: Full CRUD ──────────────────────────────────────
              context.headTitle('5. Full CRUD — Helper Methods', colorScheme.secondary),
              const SizedBox(height: 10),

              context.contentText('Model: toMap() and fromMap()', sqlColor),
              context.contentSectionContainer(
                '''// STEP 1: Define your model class with serialization
class Todo {
  final int? id;       // Nullable — null before INSERT (SQLite assigns it)
  final String title;
  final bool isDone;

  // Serialize to Map for db.insert() / db.update()
  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,   // Omit id when inserting (let SQLite auto-assign)
    'title': title,
    'is_done': isDone ? 1 : 0,  // bool → int
  };

  // Deserialize from db.query() result row
  factory Todo.fromMap(Map<String, Object?> map) => Todo(
    id: map['id'] as int?,
    title: map['title'] as String,
    isDone: (map['is_done'] as int) == 1,  // int → bool
  );
}''',
              ),

              context.contentText('CREATE — db.insert()', sqlColor),
              context.contentSectionContainer(
                '''// db.insert() → compiles to:
// INSERT INTO todos (title, is_done, priority) VALUES (?, ?, ?)
final newId = await db.insert(
  'todos',
  todo.toMap(),
  // What to do on UNIQUE/PRIMARY KEY conflict:
  conflictAlgorithm: ConflictAlgorithm.replace,  // overwrite
  // ConflictAlgorithm.ignore  → skip silently
  // ConflictAlgorithm.fail    → throw exception (default)
);
print('New todo created with id: \$newId');

// RAW alternative (same result):
final id = await db.rawInsert(
  'INSERT INTO todos(title, is_done) VALUES(?, ?)',
  ['Buy milk', 0],
);''',
              ),

              context.contentText('READ — db.query() and db.rawQuery()', sqlColor),
              context.contentSectionContainer(
                '''// db.query() → SELECT * FROM todos ORDER BY priority DESC
final List<Map<String, Object?>> rows = await db.query(
  'todos',
  columns: ['id', 'title', 'is_done'],    // Optional: SELECT specific columns
  where: 'is_done = ? AND priority >= ?', // WHERE clause (use ? for values!)
  whereArgs: [0, 2],                      // Values bound to ? placeholders
  orderBy: 'priority DESC, id DESC',      // ORDER BY
  limit: 20,                              // LIMIT
  offset: 0,                              // OFFSET (for pagination)
);

// Convert rows to typed objects
final todos = rows.map((r) => Todo.fromMap(r)).toList();

// ⚠️ Map entries from sqflite are READ-ONLY!
// If you need to modify a row map in memory, create a copy first:
final mutableRow = Map<String, Object?>.from(rows.first);

// rawQuery for complex SQL not covered by helper:
final result = await db.rawQuery(\'\'\'
  SELECT u.name, COUNT(o.id) as order_count
  FROM users u
  LEFT JOIN orders o ON u.id = o.user_id
  GROUP BY u.id
  ORDER BY order_count DESC
\'\'\');''',
              ),

              context.contentText('UPDATE — db.update()', sqlColor),
              context.contentSectionContainer(
                '''// db.update() → UPDATE todos SET title=?, is_done=? WHERE id=?
final rowsAffected = await db.update(
  'todos',
  todo.toMap(),                  // New values as Map
  where: 'id = ?',
  whereArgs: [todo.id],
);
print('Updated \$rowsAffected row(s)');

// RAW alternative:
await db.rawUpdate(
  'UPDATE todos SET title = ? WHERE id = ?',
  ['New title', todoId],
);''',
              ),

              context.contentText('DELETE — db.delete()', sqlColor),
              context.contentSectionContainer(
                '''// Delete single row by primary key:
// db.delete() → DELETE FROM todos WHERE id = ?
final deleted = await db.delete(
  'todos',
  where: 'id = ?',
  whereArgs: [todo.id],
);

// Delete ALL rows (table truncation — preserves schema):
await db.delete('todos');

// Drop the entire table (removes schema too):
await db.execute('DROP TABLE IF EXISTS todos');

// RAW delete:
await db.rawDelete('DELETE FROM todos WHERE is_done = ?', [1]);''',
              ),
              context.dividerSpace(16),

              // ── Section 6: Transactions ───────────────────────────────────
              context.headTitle('6. Transactions — Atomic ACID Operations', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('db.transaction() — commit or rollback', sqlColor),
              context.contentSectionContainer(
                '''// A transaction is a group of SQL operations that either ALL succeed
// or ALL fail together. This ensures data consistency.
//
// ACID Properties:
//   A - Atomicity:   All ops commit or all rollback — no partial writes
//   C - Consistency: DB moves from one valid state to another
//   I - Isolation:   Transaction sees a snapshot, not concurrent changes
//   D - Durability:  Committed changes survive crashes and power loss

// FLOW: Use txn (not db) inside the transaction — using db will DEADLOCK!
await db.transaction((txn) async {
  // Transfer \$100 from account A to account B
  await txn.rawUpdate(
    'UPDATE accounts SET balance = balance - ? WHERE id = ?', [100, accountA],
  );
  await txn.rawUpdate(
    'UPDATE accounts SET balance = balance + ? WHERE id = ?', [100, accountB],
  );
  // If either update fails (throws), BOTH are rolled back automatically!
});

// Manual rollback by throwing inside the transaction:
try {
  await db.transaction((txn) async {
    await txn.insert('orders', orderMap);
    if (stockCount <= 0) {
      throw Exception('Out of stock!'); // ← triggers ROLLBACK
    }
    await txn.update('inventory', {'stock': stockCount - 1},
        where: 'id = ?', whereArgs: [productId]);
  });
} catch (e) {
  // The order insert was rolled back — inventory unchanged
  print('Order failed: \$e');
}''',
              ),
              context.dividerSpace(16),

              // ── Section 7: Batch ──────────────────────────────────────────
              context.headTitle('7. Batch — Efficient Bulk Operations', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('db.batch() — reduce Dart ↔ native bridge round-trips', sqlColor),
              context.contentSectionContainer(
                '''// PROBLEM: Calling db.insert() in a for-loop is SLOW for large datasets.
// Each call crosses the Dart ↔ native bridge once → N round-trips for N items.

// SOLUTION: Batch queues all operations and executes them in ONE round-trip.
// Great for seeding data, importing CSV, or syncing offline changes.

final batch = db.batch();

// Queue operations (not executed yet):
batch.insert('todos', {'title': 'Task A', 'is_done': 0, 'priority': 1});
batch.insert('todos', {'title': 'Task B', 'is_done': 0, 'priority': 3});
batch.update('todos', {'is_done': 1}, where: 'id = ?', whereArgs: [5]);
batch.delete('todos', where: 'priority = ?', whereArgs: [0]);

// Execute ALL queued ops atomically:
final results = await batch.commit();
// results = [newId1, newId2, rowsAffected, rowsDeleted]

// For maximum performance, skip return values:
await batch.commit(noResult: true);

// Continue on individual failures (don't stop the whole batch):
await batch.commit(continueOnError: true);''',
              ),
              context.dividerSpace(16),

              // ── Section 8: Migrations ─────────────────────────────────────
              context.headTitle('8. Schema Migrations (onUpgrade)', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('Evolving your schema safely', sqlColor),
              context.contentSectionContainer(
                '''// When you need to change your schema (add columns, new tables),
// increment the version number and handle the upgrade:

final db = await openDatabase(
  path,
  version: 3,   // ← Bump from 2 to 3

  onCreate: (db, v) async {
    // Full schema for fresh installs
    await db.execute(\'\'\'
      CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, email TEXT, phone TEXT)
    \'\'\');
  },

  onUpgrade: (db, oldVersion, newVersion) async {
    // Called when upgrading from oldVersion → newVersion
    if (oldVersion < 2) {
      // v1 → v2: added the 'phone' column
      await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
    }
    if (oldVersion < 3) {
      // v2 → v3: added a new 'orders' table
      await db.execute(\'\'\'
        CREATE TABLE orders (
          id      INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          total   REAL NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id)
        )
      \'\'\');
    }
  },
);

// ⚠️ SQLite LIMITATIONS on ALTER TABLE:
//   ✅ ADD COLUMN is supported
//   ❌ DROP COLUMN is NOT supported (requires recreate + copy data)
//   ❌ RENAME COLUMN requires SQLite 3.25.0+ (Android API 30+)''',
              ),
              context.theoryContentText(
                '🏆 Real-World Tip: Always test migrations by:\n'
                '  1. Running your app with the OLD version, creating data\n'
                '  2. Bumping version and running onUpgrade\n'
                '  3. Verifying existing data survived + new schema works\n\n'
                'For complex migrations, consider Drift (sqflite wrapper with built-in '
                'migration helpers and type-safe queries).',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
