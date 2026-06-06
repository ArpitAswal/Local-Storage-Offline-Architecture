# Drift Database (Reactive SQLite)

Drift (formerly Moor) is a Flutter Favorite package that wraps SQLite with a Dart-first, type-safe API. Unlike sqflite where you write raw SQL strings, Drift generates Dart query methods that the compiler validates at build time. Any query can be turned into a reactive Stream that auto-pushes changes to the UI — no `setState()` or manual database polling needed.

---

## 1. Drift vs sqflite (Raw SQLite)

**✅ USE DRIFT WHEN:**
- You want reactive UI that auto-updates when DB changes.
- You want compile-time validated queries (typos become build errors).
- You need a clean DAO (Data Access Object) pattern for testability.
- You want type-safe partial updates without writing `SET` clause SQL.
- Your app has complex migrations.
- You want built-in isolate threading with zero setup.

**❌ USE sqflite (raw) WHEN:**
- You need absolute minimal dependencies / bundle size.
- You have existing complex hand-written SQL (`rawQuery()` is fine).
- Team is more comfortable with SQL than Dart query builders.

---

## 2. Setup — pubspec.yaml

Add the dependencies:
```yaml
dependencies:
  drift: ^2.22.0          # The Drift runtime library
  drift_flutter: ^0.2.0   # FlutterQueryExecutor

dev_dependencies:
  drift_dev: ^2.22.0      # Code generator
  build_runner: ^2.4.0    # Runs the code generator
```

Run code generation:
```bash
flutter pub get
dart run build_runner build
```

---

## 3. Table Definition — Dart-First Schema

Define tables as Dart classes — no SQL `CREATE TABLE` needed.

```dart
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  TextColumn get dueDate => text().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(1))();
}
```

> **🏆 Type Safety:** Drift handles all type conversions (e.g., bool ↔ int, DateTime ↔ String/int) automatically.

---

## 4. Data Class & Companion — Generated Types

Drift generates two classes for each table:
1. **DATA CLASS** (e.g., `Task`): Immutable, for reading from the DB.
2. **COMPANION CLASS** (e.g., `TasksCompanion`): Uses `Value<T>` to distinguish "absent" from "null" for writing to the DB.

```dart
// INSERT example — use named constructor:
final companion = TasksCompanion.insert(
  title: 'Buy groceries',
  priority: const Value(2),
  dueDate: const Value('2024-12-01'),
);

// PARTIAL UPDATE
final update = TasksCompanion(
  id: Value(taskId),
  isDone: Value(true),
);
```

---

## 5. DAO Pattern — Data Access Object

Group queries for an entity in a dedicated class.

```dart
@DriftAccessor(tables: [Tasks])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.db);

  // READ — reactive stream
  Stream<List<Task>> watchAllTasks() => select(tasks).watch();

  // INSERT
  Future<int> insertTask(TasksCompanion c) => into(tasks).insert(c);

  // PARTIAL UPDATE
  Future<int> toggleDone(int id, bool current) =>
      (update(tasks)..where((t) => t.id.equals(id)))
          .write(TasksCompanion(isDone: Value(!current)));

  // DELETE
  Future<int> deleteTask(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();
}
```

---

## 6. Reactive Streams — Drift's Killer Feature

`.watch()` turns any query into an auto-updating stream.

```dart
Stream<List<Task>> watchAllTasks() {
  return (select(tasks)
    ..where((t) => t.isDone.equals(false))
  ).watch(); // ← This is the magic
}
```
Every `INSERT`, `UPDATE`, `DELETE` automatically emits a new list to active subscribers. The UI is always current with zero manual refresh.

---

## 7. Full CRUD — Drift Dart API

**INSERT:**
```dart
final newId = await db.tasksDao.insertTask(companion);
```

**SELECT:**
```dart
final allTasks = await (select(tasks)).get();
```

**UPDATE:**
```dart
await (update(tasks)..where((t) => t.id.equals(taskId)))
    .write(TasksCompanion(isDone: const Value(true)));
```

**DELETE:**
```dart
await (delete(tasks)..where((t) => t.id.equals(taskId))).go();
```

---

## 8. Transactions — Atomic ACID Operations

Drift transactions use `transaction(() async { ... })` and handle isolation automatically.

```dart
await db.transaction(() async {
  await (update(tasks)..where((t) => t.id.equals(taskId)))
      .write(TasksCompanion(isDone: const Value(true)));

  await into(completionLog).insert(
    CompletionLogCompanion.insert(taskId: taskId, completedAt: DateTime.now()),
  );
  // If either write fails → BOTH are rolled back automatically.
});
```

---

## 9. Batch — Efficient Bulk Operations

Wraps multiple writes in one atomic transaction efficiently.

```dart
await db.batch((batch) {
  batch.insertAll(tasks, [
    TasksCompanion.insert(title: 'Task A'),
    TasksCompanion.insert(title: 'Task B'),
  ]);
});
```

---

## 10. Schema Migrations

Drift uses `MigrationStrategy` with a clear, structured API.

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (Migrator m) async {
    await m.createAll();
  },
  onUpgrade: (Migrator m, int from, int to) async {
    if (from < 2) {
      await m.addColumn(tasks, tasks.tags);
    }
  },
);
```

---

## 11. Database Class Setup

```dart
@DriftDatabase(tables: [Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'my_database'));

  @override
  int get schemaVersion => 1;
}
```

> **⚡ Threading:** `driftDatabase()` automatically runs all SQLite operations on a separate isolate (background thread) to prevent UI blocking.

---

## 12. Drift Error Handling & Rollbacks

Runtime failures throw a `SqliteException`. Common errors include UNIQUE constraint violations, NOT NULL constraint failures, or CHECK constraint violations. Drift handles atomic rollbacks when exceptions occur inside a transaction block.

```dart
try {
  await db.transaction(() async {
    await db.tasksDao.insertTask(TasksCompanion.insert(id: Value(999), title: "Task 999"));
    await db.customStatement("INSERT INTO tasks (id, title) VALUES (999, 'Duplicate');");
  });
} catch (e) {
  if (e is SqliteException) {
    print("Sqlite error caught: ${e.message} (code: ${e.extendedResultCode})");
  }
  // SQLite automatically triggers ROLLBACK. Task 999 is discarded!
}
```

---

## 13. Local Storage Comparison Table

| Database | Data Model | Reactive | Type-Safety | CodeGen | Performance |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Drift** | Relational (SQLite) | ✅ Yes (`.watch`) | ✅ Compile-Time | Optional | Fast (Background Isolate) |
| **sqflite** | Relational (SQLite) | ❌ No (Manual) | ❌ String queries | ❌ None | Medium (Thread pool) |
| **Hive** | Document / NoSQL | ✅ Yes (`ValueListenable`) | ❌ Map/Adapter | Optional | Very Fast (Memory cache) |
| **Isar** | Document / NoSQL | ✅ Yes (`.watch`) | ✅ Compile-Time | ✅ Required | Extremely Fast (LMDB) |
| **Secure Storage** | Key-Value | ❌ No (Manual) | ❌ String values | ❌ None | Slow (OS Cryptography) |
| **SharedPrefs** | Key-Value | ❌ No (Manual) | ❌ Basic keys | ❌ None | Medium (Disk XML writes) |
