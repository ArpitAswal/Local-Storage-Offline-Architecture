# SQLite Relational Module (sqflite)

This module explains how to work with raw SQLite databases in Flutter using the `sqflite` package. It focuses on setting up relational schemas, enforcing foreign keys, executing raw SQL, and handling database constraint exceptions.

---

## 🗄 sqflite: Embedded SQL Database for Flutter
sqflite is a Flutter plugin for SQLite — the most widely deployed database engine in the world (built into every Android, iOS, macOS, and Windows device). Unlike Hive or Isar, sqflite uses SQL: a standardized query language giving you full relational power: JOINs, WHERE/ORDER BY/GROUP BY, indexes, and ACID transactions. All DB operations run on a background thread automatically.

---

## 1. When to Use SQLite vs Other Storages

**✅ USE SQFLITE WHEN:**
- Data has **RELATIONSHIPS** (users → orders → order_items)
- You need complex queries: `WHERE` + `AND`/`OR`, `JOIN`, `GROUP BY`, aggregate functions.
- Data has a fixed schema you want the DB to enforce (`NOT NULL`, `UNIQUE`).
- You need to query across multiple "tables" in one operation.
- Filtering/sorting needs to happen AT THE DATABASE LEVEL (fast).

*Example: E-commerce app*
users table: `id, name, email`
orders table: `id, user_id (FK), total, created_at`
```sql
SELECT u.name, COUNT(o.id) FROM users u JOIN orders o ON u.id=o.user_id GROUP BY u.id ORDER BY COUNT(o.id) DESC
```

**❌ DON'T USE SQFLITE WHEN:**
- Data is simple key-value pairs → use **SharedPreferences**
- Data is schemaless / dynamic objects → use **Hive**
- Data needs to stay encrypted without extra libs → use **SecureStorage**
- You want reactive Streams from DB → use **Drift** (SQLite wrapper with streams)
- You need NO setup / code gen → use **SharedPreferences** or **Hive**

---

## 2. Setup — pubspec.yaml

Add the dependencies:
```yaml
dependencies:
  sqflite: ^2.4.2+1   # The Flutter SQLite plugin
  path: ^1.9.0        # For join(dbsPath, 'mydb.db')
```

No code generation required! sqflite works out of the box. Just pure Dart + SQL.

---

## 3. Opening a Database

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

final dbPath = await getDatabasesPath();
final fullPath = join(dbPath, 'my_app.db');

final Database db = await openDatabase(
  fullPath,
  version: 1, // Schema version — increment for migrations

  onCreate: (db, version) async {
    // Called ONCE on first launch
    await db.execute('''
      CREATE TABLE users (
        id      INTEGER PRIMARY KEY AUTOINCREMENT,
        name    TEXT NOT NULL,
        email   TEXT UNIQUE NOT NULL,
        age     INTEGER
      )
    ''');
  },

  onUpgrade: (db, oldVersion, newVersion) async {
    // Called when version bumps
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
    }
  },
);
```

> **💡 Singleton Pattern:** Always use a singleton for your database service so you never open multiple connections to the same `.db` file. Multiple open connections to the same file on Android reuse the same underlying SQLite object — but it's cleaner to manage one instance.

---

## 4. Schema Design & Data Types

SQLite has 5 storage classes: `INTEGER`, `REAL`, `TEXT`, `BLOB`, `NULL`.

**⚠️ TYPE GOTCHAS — IMPORTANT FOR BEGINNERS:**

1. **BOOLEAN** — SQLite has NO bool type! Store as INTEGER with values `0` (false) or `1` (true).
2. **DATETIME** — SQLite has NO DateTime type! Store as TEXT (ISO-8601) or INTEGER (milliseconds since epoch).
3. **LIST / MAP** — SQLite has NO array type! Serialize to JSON string (`jsonEncode` / `jsonDecode`).

```sql
CREATE TABLE todos (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  title     TEXT NOT NULL,
  is_done   INTEGER NOT NULL DEFAULT 0,
  due_date  TEXT,
  priority  INTEGER NOT NULL DEFAULT 1
)
```

---

## 5. Full CRUD — Helper Methods

### Model: `toMap()` and `fromMap()`
```dart
class Todo {
  final int? id;
  final String title;
  final bool isDone;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'title': title,
    'is_done': isDone ? 1 : 0,
  };

  factory Todo.fromMap(Map<String, Object?> map) => Todo(
    id: map['id'] as int?,
    title: map['title'] as String,
    isDone: (map['is_done'] as int) == 1,
  );
}
```

### CREATE — `db.insert()`
```dart
final newId = await db.insert(
  'todos',
  todo.toMap(),
  conflictAlgorithm: ConflictAlgorithm.replace,
);
```

### READ — `db.query()`
```dart
final List<Map<String, Object?>> rows = await db.query(
  'todos',
  where: 'is_done = ? AND priority >= ?',
  whereArgs: [0, 2],
  orderBy: 'priority DESC, id DESC',
);
```

### UPDATE — `db.update()`
```dart
final rowsAffected = await db.update(
  'todos',
  todo.toMap(),
  where: 'id = ?',
  whereArgs: [todo.id],
);
```

### DELETE — `db.delete()`
```dart
final deleted = await db.delete(
  'todos',
  where: 'id = ?',
  whereArgs: [todo.id],
);
```

---

## 6. Transactions — Atomic ACID Operations

A transaction is a group of SQL operations that either ALL succeed or ALL fail together.

```dart
// Use txn (not db) inside the transaction — using db will DEADLOCK!
await db.transaction((txn) async {
  await txn.rawUpdate(
    'UPDATE accounts SET balance = balance - ? WHERE id = ?', [100, accountA],
  );
  await txn.rawUpdate(
    'UPDATE accounts SET balance = balance + ? WHERE id = ?', [100, accountB],
  );
});
```

---

## 7. Batch — Efficient Bulk Operations

Calling `db.insert()` in a for-loop is SLOW (N round-trips). `db.batch()` queues operations and executes them in ONE round-trip.

```dart
final batch = db.batch();
batch.insert('todos', {'title': 'Task A', 'is_done': 0, 'priority': 1});
batch.insert('todos', {'title': 'Task B', 'is_done': 0, 'priority': 3});
await batch.commit();
```

---

## 8. Migrations (onUpgrade)

When you need to change your schema, increment the version number and handle the upgrade:

```dart
final db = await openDatabase(
  path,
  version: 3, // Bump version
  onUpgrade: (db, oldVersion, newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
    }
  },
);
```

---

## 9. SQLite Foreign Keys & Cascade Deletes

**⚠️ SQLite Foreign Key Warning:** SQLite parses foreign key constraints, but does NOT enforce them by default! You MUST execute `PRAGMA foreign_keys = ON;` in the `onConfigure` callback.

```dart
final db = await openDatabase(
  path,
  version: 2,
  onConfigure: (db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  },
);
```

**ON DELETE CASCADE:**
```sql
CREATE TABLE todos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  category_id INTEGER,
  FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE CASCADE
);
```

> **💡 Why Cascade Delete is vital on mobile:** Phone storage is limited. If a user deletes a profile, cascade delete ensures associated items don't remain as orphaned data wasting space.

---

## 10. DatabaseException & Error Handling

Catch and handle `DatabaseException` to keep the application stable:

```dart
try {
  await db.insert('todos', {'title': 'Orphaned Task', 'category_id': 999});
} on DatabaseException catch (e) {
  if (e.isUniqueConstraintError()) {
    print('Failed: Name already exists in the database.');
  } else if (e.toString().contains('FOREIGN KEY constraint failed')) {
    print('Failed: Parent category does not exist.');
  } else {
    print('Database error: $e');
  }
}
```

> **🔐 Database Locking:** SQLite locks the database file when a write transaction starts. If you run concurrent writes across multiple isolates without using a single database connection instance, SQLite throws a locking DatabaseException. Always use a single singleton service.
