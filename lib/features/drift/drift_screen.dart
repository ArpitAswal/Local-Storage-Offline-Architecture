// =============================================================================
// drift_screen.dart  — Educational Guide for Drift
// =============================================================================
import 'package:flutter/material.dart';
import '../../presentation/navigation/route_navigation.dart';
import '../../presentation/widgets/extension_widgets.dart';
import 'drift_example.dart';

/// [DriftScreen] — Educational guide for the Drift package.
///
/// Covers: what Drift is, setup, table definitions, DAO pattern, reactive
/// streams, full CRUD with the Drift Dart API, transactions, batch operations,
/// migrations, and how Drift compares to raw sqflite.
class DriftScreen extends StatelessWidget {
  const DriftScreen({super.key});

  static const Color driftColor = Color(0xFF3949AB); // Indigo 700

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
        title: const Text('Drift Database Guide'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () =>
                  RouteNavigation.push(context, const DriftDemoView()),
              icon: Icon(Icons.science, size: 18, color: driftColor),
              label: Text(
                'Try Lab',
                style: TextStyle(
                  color: driftColor,
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
              // ── Hero ─────────────────────────────────────────────────────
              context.headTitle(
                '🌊 Drift: Reactive, Type-Safe SQLite for Flutter',
                driftColor,
              ),
              context.dividerSpace(16),
              context.subHeadTitle(
                'Drift (formerly Moor) is a Flutter Favorite package that wraps SQLite '
                'with a Dart-first, type-safe API. Unlike sqflite where you write raw SQL '
                'strings, Drift generates Dart query methods that the compiler validates at '
                'build time. Its killer feature: any query can be turned into a reactive '
                'Stream that auto-pushes changes to the UI — no setState() or manual '
                'database polling needed.',
              ),
              context.dividerSpace(16),

              // ── Section 1: Drift vs sqflite ───────────────────────────────
              context.headTitle('1. Drift vs sqflite (Raw SQLite)', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('When to choose Drift over raw sqflite', driftColor),
              context.contentSectionContainer(
                '''// ✅ USE DRIFT WHEN:
//   • You want reactive UI that auto-updates when DB changes
//     (StreamBuilder + watchAllTasks() — zero setState() needed)
//   • You want compile-time validated queries (typos become build errors)
//   • You need a clean DAO (Data Access Object) pattern for testability
//   • You want type-safe partial updates without writing SET clause SQL
//   • Your app has complex migrations you want Drift to help manage
//   • You want built-in isolate threading with zero setup

// ❌ USE sqflite (raw) WHEN:
//   • You need absolute minimal dependencies / bundle size
//   • You have existing complex hand-written SQL (rawQuery() is fine)
//   • You need Web + Desktop support without extra setup
//   • Team is more comfortable with SQL than Dart query builders

// KEY DIFFERENCES:
//   sqflite raw:  db.rawQuery('SELECT * FROM tasks WHERE is_done = ?', [0])
//   Drift:        (select(tasks)..where((t) => t.isDone.equals(false))).get()
//   Drift type-safe = the compiler catches "is_doen" (typo) at build time!
//   sqflite raw = crashes at RUNTIME with "no such column: is_doen"

// REACTIVE difference (Drift's biggest advantage):
//   sqflite:  Must call getAll() after every INSERT/UPDATE/DELETE manually
//   Drift:    watchAllTasks() stream emits automatically — UI always current!''',
              ),
              context.dividerSpace(16),

              // ── Section 2: Setup ──────────────────────────────────────────
              context.headTitle('2. Setup — pubspec.yaml', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('Add the dependencies', driftColor),
              context.contentSectionContainer(
                '''dependencies:
  drift: ^2.22.0          # The Drift runtime library (Flutter Favorite ⭐)
  drift_flutter: ^0.2.0   # FlutterQueryExecutor — opens DB on mobile/desktop

dev_dependencies:
  drift_dev: ^2.22.0      # Code generator (creates .g.dart files)
  build_runner: ^2.4.0    # Runs the code generator

# After adding, run:
#   flutter pub get
#   dart run build_runner build

# Platform support:
#   ✅ Android  ✅ iOS  ✅ macOS  ✅ Windows  ✅ Linux  ✅ Web
#   Drift works everywhere — unlike sqflite which lacks native desktop/web

# Note: drift_dev conflicts with isar_generator due to sqlite3 version
# dependency conflict. Alternative: write the table/DAO classes manually
# (no code gen required — Drift is a runtime library, code gen is optional).''',
              ),
              context.dividerSpace(16),

              // ── Section 3: Table Definition ───────────────────────────────
              context.headTitle('3. Table Definition — Dart-First Schema', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('Define tables as Dart classes — no SQL CREATE TABLE needed', driftColor),
              context.contentSectionContainer(
                '''// Each table is a Dart class extending Table.
// Drift maps your getter types to SQL types automatically:
//   IntColumn    → INTEGER (NOT NULL by default)
//   TextColumn   → TEXT
//   BoolColumn   → INTEGER 0/1 (Drift handles bool ↔ int conversion!)
//   RealColumn   → REAL
//   DateTimeColumn → stored as TEXT (ISO-8601) or INTEGER (epoch ms)

class Tasks extends Table {
  // INTEGER PRIMARY KEY AUTOINCREMENT
  IntColumn get id => integer().autoIncrement()();

  // TEXT NOT NULL — columns are NOT NULL by default in Drift!
  // withLength() adds a CHECK constraint for bounds validation.
  TextColumn get title => text().withLength(min: 1, max: 200)();

  // BOOLEAN — Drift handles bool ↔ INTEGER 0/1 automatically.
  // Unlike sqflite where you cast manually: (map['is_done'] as int) == 1
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  // TEXT NULL — call nullable() to allow NULL values
  TextColumn get dueDate => text().nullable()();

  // INTEGER — custom enum-like column
  IntColumn get priority => integer().withDefault(const Constant(1))();
}

// ✅ Drift validates this schema at COMPILE TIME via drift_dev.
//    If you add a column with a typo, the build fails — not the app.
// ✅ Drift generates: CREATE TABLE, data class, companion class automatically.''',
              ),
              context.theoryContentText(
                '🏆 Type Safety: Drift\'s BoolColumn stores 0/1 in SQLite '
                'but exposes a Dart bool to your code. No manual casting needed. '
                'DateTimeColumn stores milliseconds since epoch but gives you '
                'a DateTime object. Drift handles ALL conversions internally.',
              ),
              context.dividerSpace(16),

              // ── Section 4: Data Class & Companion ─────────────────────────
              context.headTitle('4. Data Class & Companion — Generated Types', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('The two Dart types Drift generates per table', driftColor),
              context.contentSectionContainer(
                '''// Drift generates TWO classes for each table:

// 1. DATA CLASS (immutable, for reading from DB)
//    Maps each Table column to a typed Dart field.
class Task {
  final int id;
  final String title;
  final bool isDone;     // ← Dart bool (not int!)
  final String? dueDate; // ← Nullable String
  final int priority;
  // ... constructor, copyWith, ==, hashCode
}

// 2. COMPANION CLASS (for writing to DB)
//    Uses Value<T> to distinguish "absent" from "null":
//      Value.absent() = don\'t include this column in the SQL
//      Value(null)    = include NULL in SQL
//      Value("text")  = include the value
class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<String> title;
  final Value<bool> isDone;
  final Value<String?> dueDate;
  final Value<int> priority;
}

// INSERT example — use named constructor for clarity:
final companion = TasksCompanion.insert(
  title: \'Buy groceries\',
  priority: const Value(2),    // Medium
  dueDate: const Value(\'2024-12-01\'),
  // isDone defaults to false (not included → Value.absent())
);

// PARTIAL UPDATE — only change isDone, leave everything else:
final companion = TasksCompanion(
  id: Value(taskId),                 // WHERE id = ?
  isDone: Value(true),               // SET is_done = 1
  // title, dueDate, priority are absent → NOT in SET clause
);''',
              ),
              context.dividerSpace(16),

              // ── Section 5: DAO Pattern ────────────────────────────────────
              context.headTitle('5. DAO Pattern — Data Access Object', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('Group all queries for an entity in a dedicated class', driftColor),
              context.contentSectionContainer(
                '''// A DAO is a class annotated with @DriftAccessor that groups
// all database queries for a specific domain entity.
// Without code gen, extend DatabaseAccessor<YourDatabase> manually.

// Benefits:
//   ✅ Single-responsibility: TasksDao handles only tasks queries
//   ✅ Testable in isolation (inject a mock/in-memory database)
//   ✅ Clean API: ViewModel calls tasksDao.insertTask() not db.insert()
//   ✅ Composable: different screens use different DAOs

class TasksDao extends DatabaseAccessor<AppDatabase> {
  TasksDao(super.db);

  \$TasksTable get tasks => db.tasks; // shortcut to the table

  // READ — reactive stream (Drift\'s killer feature!)
  Stream<List<Task>> watchAllTasks() {
    return (select(tasks)
      ..orderBy([(t) => OrderingTerm.desc(t.priority)])
    ).watch(); // ← .watch() makes it reactive
  }

  // READ — single fetch (non-reactive)
  Future<List<Task>> getAllTasks() {
    return (select(tasks)
      ..orderBy([(t) => OrderingTerm.desc(t.priority)])
    ).get(); // ← .get() returns Future<List<T>>
  }

  // INSERT
  Future<int> insertTask(TasksCompanion c) =>
      into(tasks).insert(c, mode: InsertMode.insertOrReplace);

  // UPDATE (full row)
  Future<bool> updateTask(TasksCompanion c) =>
      update(tasks).replace(c);

  // PARTIAL UPDATE (only isDone column)
  Future<int> toggleDone(int id, bool current) =>
      (update(tasks)..where((t) => t.id.equals(id)))
          .write(TasksCompanion(isDone: Value(!current)));

  // DELETE
  Future<int> deleteTask(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();
}''',
              ),
              context.dividerSpace(16),

              // ── Section 6: Reactive Streams ───────────────────────────────
              context.headTitle('6. Reactive Streams — Drift\'s Killer Feature', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('.watch() turns any query into an auto-updating stream', driftColor),
              context.contentSectionContainer(
                '''// THE PROBLEM with sqflite / raw SQLite:
//   You must manually call getAll() after every insert/update/delete.
//   If multiple screens use the same table, they all go stale independently.

// THE DRIFT SOLUTION — .watch():
//   Returns Stream<List<Task>> backed by SQLite change notifications.
//   Every INSERT, UPDATE, DELETE automatically emits a new list to ALL
//   active subscribers. The UI is always current with zero manual refresh.

// ── In the DAO ──────────────────────────────────────────────────────────
Stream<List<Task>> watchAllTasks() {
  return (select(tasks)
    ..where((t) => t.isDone.equals(false))  // WHERE is_done = 0
    ..orderBy([(t) => OrderingTerm.desc(t.priority)])
  ).watch(); // ← This is the magic
}

// ── In the ViewModel — subscribe once ───────────────────────────────────
StreamSubscription<List<Task>>? _sub;

void _subscribeToStream() {
  _sub = tasksDao.watchAllTasks().listen((tasks) {
    _tasks = tasks;
    notifyListeners(); // Rebuild UI widgets that use this ViewModel
  });
}

// After calling insertTask() or deleteTask(), the stream emits automatically.
// NO manual "refresh" or "reload" call needed anywhere!

// ── In the UI — using StreamBuilder ─────────────────────────────────────
// (Alternative to ViewModel/ChangeNotifier pattern)
StreamBuilder<List<Task>>(
  stream: tasksDao.watchAllTasks(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return const CircularProgressIndicator();
    final tasks = snapshot.data!;
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (_, i) => TaskTile(task: tasks[i]),
    );
  },
)
// When you insert/delete a task ANYWHERE in the app, this ListView
// automatically rebuilds. No setState(), no manual reload!''',
              ),
              context.theoryContentText(
                '🔥 Real-World Impact: In a task manager app with multiple screens '
                '(list view, calendar view, widget), ALL screens stay in sync '
                'automatically when any task changes — including background sync '
                'from a remote API. This makes Drift the go-to choice for '
                'production Flutter apps that need reactive local storage.',
              ),
              context.dividerSpace(16),

              // ── Section 7: Full CRUD ──────────────────────────────────────
              context.headTitle('7. Full CRUD — Drift Dart API', colorScheme.secondary),
              const SizedBox(height: 10),

              context.contentText('INSERT — into(table).insert(companion)', driftColor),
              context.contentSectionContainer(
                '''// Drift uses Companion objects for type-safe INSERT.
// The compiler validates that required columns are provided.
final companion = TasksCompanion.insert(
  title: \'Fix critical bug #421\',
  priority: const Value(3),           // High
  dueDate: const Value(\'2024-11-30\'),
);

// InsertMode.insertOrReplace = ConflictAlgorithm.replace in sqflite
final newId = await db.tasksDao.insertTask(companion);
// SQL: INSERT OR REPLACE INTO tasks (title, is_done, due_date, priority)
//      VALUES (\'Fix critical bug #421\', 0, \'2024-11-30\', 3)
print(\'Inserted with id: \$newId\');''',
              ),

              context.contentText('SELECT — select().where().get() / watch()', driftColor),
              context.contentSectionContainer(
                '''// Type-safe SELECT — no string column names!
// Drift query API:
final allTasks = await (select(tasks)
  ..orderBy([(t) => OrderingTerm.desc(t.priority)])
).get();
// SQL: SELECT * FROM tasks ORDER BY priority DESC

// With WHERE:
final pendingTasks = await (select(tasks)
  ..where((t) => t.isDone.equals(false))
  ..orderBy([(t) => OrderingTerm.desc(t.priority)])
).get();
// SQL: SELECT * FROM tasks WHERE is_done = 0 ORDER BY priority DESC

// Reactive watch — emits on any change:
final stream = (select(tasks)
  ..where((t) => t.isDone.equals(false))
).watch();
// ← stream re-emits whenever tasks table changes!

// Multiple conditions:
final urgent = await (select(tasks)
  ..where((t) => t.priority.isBiggerOrEqualValue(2) & t.isDone.not())
).get();
// SQL: SELECT * FROM tasks WHERE priority >= 2 AND is_done = 0''',
              ),

              context.contentText('UPDATE — type-safe partial update', driftColor),
              context.contentSectionContainer(
                '''// FULL UPDATE (all columns):
await db.tasksDao.updateTask(TasksCompanion(
  id: Value(taskId),
  title: Value(\'Updated title\'),
  isDone: Value(false),
  priority: Value(2),
  dueDate: const Value.absent(), // skip — don\'t change dueDate
));
// SQL: UPDATE tasks SET title=\'Updated title\', is_done=0, priority=2 WHERE id=?

// PARTIAL UPDATE (only one field — no full object needed!):
// In sqflite: update(\'tasks\', {\'is_done\': 1}, where: \'id=?\', whereArgs: [id])
// In Drift:   type-safe, no string column names, compiler-validated:
await (update(tasks)..where((t) => t.id.equals(taskId)))
    .write(TasksCompanion(isDone: const Value(true)));
// SQL: UPDATE tasks SET is_done = 1 WHERE id = ?

// Drift validates Value types at compile time:
// TasksCompanion(isDone: Value(\'wrong\')) ← COMPILE ERROR (not a bool!)''',
              ),

              context.contentText('DELETE — type-safe delete expressions', driftColor),
              context.contentSectionContainer(
                '''// DELETE single row:
final deleted = await (delete(tasks)
  ..where((t) => t.id.equals(taskId))
).go();
// SQL: DELETE FROM tasks WHERE id = ?

// DELETE with complex condition:
await (delete(tasks)
  ..where((t) => t.isDone.equals(true) & t.priority.isSmallerThanValue(2))
).go();
// SQL: DELETE FROM tasks WHERE is_done = 1 AND priority < 2

// DELETE ALL:
await delete(tasks).go(); // DELETE FROM tasks''',
              ),
              context.dividerSpace(16),

              // ── Section 8: Transactions ───────────────────────────────────
              context.headTitle('8. Transactions — Atomic ACID Operations', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('db.transaction() — simpler than sqflite\'s approach', driftColor),
              context.contentSectionContainer(
                '''// Drift transactions are cleaner than sqflite:
//   sqflite: db.transaction((txn) async { txn.insert(...) })
//             ^ must use `txn` (not `db`) — easy to deadlock with `db`!
//   Drift:   transaction(() async { insert(...) })
//             ^ No separate txn object — Drift handles isolation automatically

await db.transaction(() async {
  // Transfer: mark task as done AND log the completion time
  await (update(tasks)..where((t) => t.id.equals(taskId)))
      .write(TasksCompanion(isDone: const Value(true)));

  await into(completionLog).insert(
    CompletionLogCompanion.insert(taskId: taskId, completedAt: DateTime.now()),
  );
  // If either write fails → BOTH are rolled back automatically.
  // Drift uses SQLite\'s BEGIN/COMMIT/ROLLBACK internally.
});

// Manual rollback — throw inside the transaction:
try {
  await db.transaction(() async {
    await insertTask(companion);
    if (stockCount <= 0) {
      throw Exception(\'No stock available\'); // ← triggers ROLLBACK
    }
    await decrementStock(productId);
  });
} catch (e) {
  // The insert was rolled back. Stock unchanged.
  print(\'Transaction rolled back: \$e\');
}''',
              ),
              context.dividerSpace(16),

              // ── Section 9: Batch Operations ───────────────────────────────
              context.headTitle('9. Batch — Efficient Bulk Operations', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('batch() — typed bulk operations in one round-trip', driftColor),
              context.contentSectionContainer(
                '''// Drift\'s batch() wraps multiple writes in one atomic transaction.
// Typed companions replace raw Maps — the compiler validates every field.

await db.batch((batch) {
  // insertAll: inserts a List of companions in one go
  batch.insertAll(tasks, [
    TasksCompanion.insert(title: \'Task A\', priority: const Value(1)),
    TasksCompanion.insert(title: \'Task B\', priority: const Value(3)),
    TasksCompanion.insert(title: \'Task C\', priority: const Value(2)),
  ], mode: InsertMode.insertOrReplace);
});
// All 3 inserts execute atomically in ONE SQL transaction.
// Drift also runs this on a background isolate — non-blocking!

// Mixed operations in one batch:
await db.batch((batch) {
  batch.insert(tasks, newTaskCompanion);
  batch.update(tasks, doneCompanion, where: (t) => t.id.equals(5));
  batch.delete(tasks, where: (t) => t.isDone.equals(true));
});
// SQL: BEGIN; INSERT...; UPDATE...; DELETE...; COMMIT;''',
              ),
              context.dividerSpace(16),

              // ── Section 10: Migrations ────────────────────────────────────
              context.headTitle('10. Schema Migrations', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('Drift\'s migration system — safer than sqflite\'s onUpgrade', driftColor),
              context.contentSectionContainer(
                '''// Drift uses MigrationStrategy with a clear, structured API.
// Bump schemaVersion and describe what changed.

class AppDatabase extends GeneratedDatabase {
  @override
  int get schemaVersion => 3; // ← bump from 2 to 3

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      // ✅ Called once on first install — creates ALL tables automatically
      await m.createAll();
      // No SQL needed! Drift generates CREATE TABLE from your table classes.
    },

    onUpgrade: (Migrator m, int from, int to) async {
      // ✅ Called when schemaVersion bumps
      if (from < 2) {
        // v1 → v2: add a \'tags\' column (migrator wraps ALTER TABLE)
        await m.addColumn(tasks, tasks.\$tags);
        // SQL: ALTER TABLE tasks ADD COLUMN tags TEXT
      }
      if (from < 3) {
        // v2 → v3: add a \'completion_log\' table
        await m.createTable(completionLog);
        // SQL: CREATE TABLE completion_log (...)
      }
    },

    beforeOpen: (OpenedDatabase details) async {
      // Runs AFTER migration, BEFORE first query — great for sanity checks
      if (details.versionBefore != details.versionNow) {
        print(\'Migrated from v\${details.versionBefore} to v\${details.versionNow}\');
      }
    },
  );
}

// 🏆 Drift advantage: m.addColumn() validates the column exists in your
// Dart table class at compile time. sqflite\'s ALTER TABLE is just a string.''',
              ),
              context.theoryContentText(
                '💡 Drift Pro Tip: Drift includes a schema versioning tool '
                '(drift_dev generate_schema) that saves a snapshot of each version. '
                'You can then write "step-by-step" migration tests that verify '
                'your migration logic works correctly from any past version. '
                'sqflite has no equivalent built-in tooling.',
              ),
              context.dividerSpace(16),

              // ── Section 11: Database Setup ────────────────────────────────
              context.headTitle('11. Database Class Setup', colorScheme.secondary),
              const SizedBox(height: 10),
              context.contentText('AppDatabase — the root of your Drift database', driftColor),
              context.contentSectionContainer(
                '''// The database class ties everything together.
// With code gen: @DriftDatabase(tables: [Tasks])
// Without code gen: extend GeneratedDatabase manually.

class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.e);

  // ── Singleton pattern (opens DB once) ───────────────────────────────────
  static AppDatabase? _instance;
  static AppDatabase get instance {
    _instance ??= AppDatabase(
      // driftDatabase() from drift_flutter:
      //   • Android: /data/data/<pkg>/databases/drift_tasks_demo.db
      //   • iOS/macOS: Documents/drift_tasks_demo.db
      //   • Runs on a background isolate automatically ← zero setup needed!
      driftDatabase(name: \'drift_tasks_demo\'),
    );
    return _instance!;
  }

  // Table instances — used by DAOs and queries
  late final \$TasksTable tasks = \$TasksTable(this);

  // DAO instances
  late final TasksDao tasksDao = TasksDao(this);

  // All tables — Drift uses this for CREATE TABLE on first open
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [tasks];

  @override
  int get schemaVersion => 1;
}

// Usage in ViewModel:
final db = AppDatabase.instance;
final id = await db.tasksDao.insertTask(companion);
final stream = db.tasksDao.watchAllTasks(); // Stream<List<Task>>''',
              ),
              context.theoryContentText(
                '⚡ Threading: driftDatabase() from drift_flutter automatically '
                'runs all SQLite operations on a separate isolate (background thread). '
                'This means your UI thread is NEVER blocked by database I/O — '
                'no ANR or janky scrolling. sqflite also runs on a background '
                'thread, but Drift\'s isolate setup provides even better isolation.',
              ),
              const SizedBox(height: 20),

              // ── Section 12: Drift Error Handling ──────────────────────────
              context.headTitle('12. Drift Error Handling & Rollbacks', colorScheme.secondary),
              const SizedBox(height: 10),
              context.theoryContentText(
                'Drift database operations run on top of SQLite, so runtime failures '
                'throw a `SqliteException` (from the `sqlite3` package). Common errors include '
                'UNIQUE constraint violations, NOT NULL constraint failures, or CHECK constraint '
                'violations. Drift handles atomic rollbacks when exceptions occur inside a transaction block.',
              ),
              const SizedBox(height: 10),
              context.contentText('Catching SqliteException & Rollback', driftColor),
              context.contentSectionContainer(
                'try {\n'
                '  await db.transaction(() async {\n'
                '    // 1. First insert executes successfully\n'
                '    await db.tasksDao.insertTask(TasksCompanion.insert(id: Value(999), title: "Task 999"));\n\n'
                '    // 2. Second insert uses raw SQL and triggers UNIQUE constraint violation\n'
                '    await db.customStatement("INSERT INTO tasks (id, title) VALUES (999, \'Duplicate\');");\n'
                '  });\n'
                '} catch (e) {\n'
                '  if (e is SqliteException) {\n'
                '    print("Sqlite error caught: \${e.message} (code: \${e.extendedResultCode})");\n'
                '  }\n'
                '  // SQLite automatically triggers ROLLBACK. Task 999 is discarded from database!\n'
                '}',
              ),
              const SizedBox(height: 20),

              // ── Section 13: Local Storage Database Comparison ──────────────
              context.headTitle('13. Local Storage Comparison Table', colorScheme.secondary),
              const SizedBox(height: 10),
              _buildDatabaseComparisonTable(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatabaseComparisonTable(BuildContext context) {
    final rows = [
      ('Database', 'Data Model', 'Reactive', 'Type-Safety', 'CodeGen', 'Performance'),
      ('Drift', 'Relational (SQLite)', '✅ Yes (.watch)', '✅ Compile-Time', 'Optional', 'Fast (Background Isolate)'),
      ('sqflite', 'Relational (SQLite)', '❌ No (Manual)', '❌ String queries', '❌ None', 'Medium (Thread pool)'),
      ('Hive', 'Document / NoSQL', '✅ Yes (ValueListenable)', '❌ Map/Adapter', 'Optional', 'Very Fast (Memory cache)'),
      ('Isar', 'Document / NoSQL', '✅ Yes (.watch)', '✅ Compile-Time', '✅ Required', 'Extremely Fast (LMDB-based)'),
      ('Secure Storage', 'Key-Value', '❌ No (Manual)', '❌ String values', '❌ None', 'Slow (OS Cryptography)'),
      ('SharedPrefs', 'Key-Value', '❌ No (Manual)', '❌ Basic keys', '❌ None', 'Medium (Disk XML writes)'),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: driftColor.withValues(alpha: 0.2)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 580,
          child: Column(
            children: rows.asMap().entries.map((e) {
              final i = e.key;
              final r = e.value;
              final isHeader = i == 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isHeader
                      ? driftColor.withValues(alpha: 0.1)
                      : i.isEven
                          ? driftColor.withValues(alpha: 0.04)
                          : Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(i == 0 ? 10 : 0),
                    topRight: Radius.circular(i == 0 ? 10 : 0),
                    bottomLeft: Radius.circular(i == rows.length - 1 ? 10 : 0),
                    bottomRight: Radius.circular(i == rows.length - 1 ? 10 : 0),
                  ),
                  border: isHeader ? Border(bottom: BorderSide(color: driftColor.withValues(alpha: 0.2))) : null,
                ),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(r.$1, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: isHeader ? driftColor : Colors.indigo.shade800))),
                    Expanded(flex: 3, child: Text(r.$2, style: TextStyle(fontSize: 10, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal))),
                    Expanded(flex: 2, child: Text(r.$3, style: TextStyle(fontSize: 10, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal))),
                    Expanded(flex: 2, child: Text(r.$4, style: TextStyle(fontSize: 10, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal))),
                    Expanded(flex: 2, child: Text(r.$5, style: TextStyle(fontSize: 10, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal))),
                    Expanded(flex: 3, child: Text(r.$6, style: TextStyle(fontSize: 10, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal))),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}