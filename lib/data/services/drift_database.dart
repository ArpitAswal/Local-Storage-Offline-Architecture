// =============================================================================
// drift_database.dart
// =============================================================================
// PURPOSE: Drift database definition — written WITHOUT code generation so it
//   coexists peacefully with isar_generator in the same project.
//
// Drift supports two approaches:
//   1. Code-gen approach  : annotate with @DriftDatabase, run build_runner
//   2. Manual approach    : subclass GeneratedDatabase directly (this file)
//
// This file uses approach 2, matching exactly what drift_dev generates.
// All boilerplate is written by hand below — same runtime behaviour.
//
// KEY DRIFT CONCEPTS SHOWN:
//   ✅ Table definition   — extends Table with typed columns
//   ✅ DAO (Data Access Object) — DatabaseAccessor with reactive queries
//   ✅ Reactive Stream    — watchAll() returns Stream<List<T>> via .watch()
//   ✅ Transaction        — wrapped inside transaction()
//   ✅ Batch insert       — db.batch() + batch.insertAll()
//   ✅ Typed query        — select().where(...).get() / watch()
//   ✅ Type-safe updates  — update().write(Companion)
// =============================================================================

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. TABLE DSL DEFINITION
//
// A Drift Table is a Dart class where each getter defines a column.
// Drift maps these to SQL automatically:
//   IntColumn    → INTEGER
//   TextColumn   → TEXT
//   BoolColumn   → INTEGER (0/1) — Drift handles bool ↔ int conversion!
//   RealColumn   → REAL
//   DateTimeColumn → INTEGER (unix ms epoch) or TEXT (ISO-8601)
//
// Unlike raw SQLite (sqflite), you NEVER write CREATE TABLE SQL.
// Drift generates it from this class and validates it at compile time.
// ─────────────────────────────────────────────────────────────────────────────
class Tasks extends Table {
  // INTEGER PRIMARY KEY AUTOINCREMENT
  IntColumn get id => integer().autoIncrement()();

  // TEXT NOT NULL — Drift columns are NOT NULL by default!
  TextColumn get title => text().withLength(min: 1, max: 200)();

  // BOOLEAN stored as INTEGER 0/1 — Drift does the conversion automatically.
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  // TEXT NULL — call nullable() to allow NULL values
  TextColumn get dueDate => text().nullable()();

  // INTEGER — priority: 1=Low, 2=Medium, 3=High
  IntColumn get priority => integer().withDefault(const Constant(1))();
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. DATA CLASS
//
// The immutable Dart object that represents one row in the tasks table.
// ─────────────────────────────────────────────────────────────────────────────
class Task {
  final int id;
  final String title;
  final bool isDone;
  final String? dueDate;
  final int priority;

  const Task({
    required this.id,
    required this.title,
    required this.isDone,
    this.dueDate,
    required this.priority,
  });

  String get priorityLabel {
    switch (priority) {
      case 3: return 'High';
      case 2: return 'Medium';
      default: return 'Low';
    }
  }

  Task copyWith({
    int? id,
    String? title,
    bool? isDone,
    String? dueDate,
    int? priority,
    bool clearDueDate = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      priority: priority ?? this.priority,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. COMPANION CLASS (for INSERT / UPDATE)
//
// Drift uses a "Companion" class for write operations — it allows passing
// "absent" vs "null" values, which are different:
//   Value.absent()  = don't include this column in the SQL statement
//   Value(null)     = include NULL
//   Value('text')   = include a concrete value
// ─────────────────────────────────────────────────────────────────────────────
class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<String> title;
  final Value<bool> isDone;
  final Value<String?> dueDate;
  final Value<int> priority;

  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.isDone = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.priority = const Value.absent(),
  });

  TasksCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.isDone = const Value(false),
    this.dueDate = const Value.absent(),
    this.priority = const Value(1),
  }) : title = Value(title);

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) map['id'] = Variable<int>(id.value);
    if (title.present) map['title'] = Variable<String>(title.value);
    if (isDone.present) map['is_done'] = Variable<bool>(isDone.value);
    if (dueDate.present) {
      final v = dueDate.value;
      if (!nullToAbsent || v != null) {
        map['due_date'] = Variable<String>(v);
      }
    }
    if (priority.present) map['priority'] = Variable<int>(priority.value);
    return map;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. TABLE INFO — matches the pattern drift_dev generates
//
// CRITICAL: Column getters MUST use the SAME NAME as the DSL class (Tasks)
// and be annotated with @override so they shadow the DSL ColumnBuilder.
// This is what allows query expressions like:
//   select(tasks).where((t) => t.isDone.equals(false))
// to work — t.isDone must return a GeneratedColumn<bool>, NOT a ColumnBuilder.
// ─────────────────────────────────────────────────────────────────────────────
class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;

  $TasksTable(this.attachedDatabase, [this._alias]);

  // ── COLUMN DEFINITIONS ────────────────────────────────────────────────────
  // Each column OVERRIDES the DSL getter from Tasks.
  // The GeneratedColumn takes: (sqlName, tableAlias, nullable, options...)

  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id', aliasedName, false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints:
        GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );

  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title', aliasedName, false,
    additionalChecks:
        GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );

  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
    'is_done', aliasedName, false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints:
        GeneratedColumn.constraintIsAlways('CHECK ("is_done" IN (0, 1))'),
    defaultValue: const Constant(false),
  );

  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date', aliasedName, true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );

  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority', aliasedName, false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );

  // $columns drives CREATE TABLE generation and all query building.
  // Must use the same names as the overriding getters above.
  @override
  List<GeneratedColumn> get $columns => [id, title, isDone, dueDate, priority];

  @override
  String get aliasedName => _alias ?? actualTableName;

  @override
  String get actualTableName => $name;

  // The SQL table name. Drift convention: static const $name.
  static const String $name = 'tasks';

  // $primaryKey is required for update(table).replace() to work correctly.
  @override
  Set<GeneratedColumn> get $primaryKey => {id};

  // map() deserialises a raw SQLite row Map → Task data object.
  // Column names here are the SQL names (snake_case), matching the
  // GeneratedColumn constructor first argument above.
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      isDone: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_done'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}due_date']),
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
    );
  }

  @override
  $TasksTable createAlias(String alias) => $TasksTable(attachedDatabase, alias);
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. DAO (Data Access Object)
//
// A DAO groups all queries for a specific entity. This is Drift's version
// of the Repository pattern.
//
// Benefits:
//   • Single-responsibility: each DAO handles one domain entity
//   • Testable in isolation (inject a mock database)
//   • Clean public API for the ViewModel layer
//   • Reactive streams — watchAllTasks() auto-pushes updates to UI
// ─────────────────────────────────────────────────────────────────────────────
class TasksDao extends DatabaseAccessor<AppDatabase> {
  TasksDao(super.db);

  $TasksTable get tasks => db.tasks;

  // ── READ ALL (reactive stream) ──────────────────────────────────────────
  // .watch() turns any Drift query into a Stream<List<Task>>.
  // Every INSERT, UPDATE, DELETE on 'tasks' causes this stream to emit.
  // The UI simply uses a StreamSubscription — no setState() refresh needed!
  //
  // SQL: SELECT * FROM tasks [WHERE is_done = ?] ORDER BY priority DESC, id DESC
  Stream<List<Task>> watchAllTasks({String? filter}) {
    final query = select(tasks)
      ..orderBy([
        (t) => OrderingTerm.desc(t.priority),
        (t) => OrderingTerm.desc(t.id),
      ]);
    if (filter == 'done') {
      query.where((t) => t.isDone.equals(true));
    } else if (filter == 'pending') {
      query.where((t) => t.isDone.equals(false));
    }
    return query.watch();
  }

  // ── READ ONCE (future, non-reactive) ──────────────────────────────────
  Future<List<Task>> getAllTasks({String? filter}) {
    final query = select(tasks)
      ..orderBy([
        (t) => OrderingTerm.desc(t.priority),
        (t) => OrderingTerm.desc(t.id),
      ]);
    if (filter == 'done') {
      query.where((t) => t.isDone.equals(true));
    } else if (filter == 'pending') {
      query.where((t) => t.isDone.equals(false));
    }
    return query.get();
  }

  // ── COUNT AGGREGATE ────────────────────────────────────────────────────
  Future<int> countTasks() async {
    final countExpr = tasks.id.count();
    final query = selectOnly(tasks)..addColumns([countExpr]);
    final result = await query.getSingle();
    return result.read(countExpr) ?? 0;
  }

  // ── INSERT ─────────────────────────────────────────────────────────────
  // SQL: INSERT INTO tasks (title, is_done, due_date, priority) VALUES (?, ?, ?, ?)
  Future<int> insertTask(TasksCompanion companion) {
    return into(tasks).insert(companion, mode: InsertMode.insertOrReplace);
  }

  // ── UPDATE (full row) ──────────────────────────────────────────────────
  // SQL: UPDATE tasks SET title=?, is_done=?, due_date=?, priority=? WHERE id=?
  Future<bool> updateTask(TasksCompanion companion) {
    return update(tasks).replace(companion);
  }

  // ── PARTIAL UPDATE (toggle isDone only) ───────────────────────────────
  // SQL: UPDATE tasks SET is_done=? WHERE id=?
  Future<int> toggleDoneStatus(int taskId, bool currentStatus) {
    return (update(tasks)..where((t) => t.id.equals(taskId)))
        .write(TasksCompanion(isDone: Value(!currentStatus)));
  }

  // ── DELETE ─────────────────────────────────────────────────────────────
  // SQL: DELETE FROM tasks WHERE id=?
  Future<int> deleteTask(int id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  // ── DELETE ALL ─────────────────────────────────────────────────────────
  // SQL: DELETE FROM tasks
  Future<int> deleteAllTasks() {
    return delete(tasks).go();
  }

  // ── BATCH INSERT ───────────────────────────────────────────────────────
  // Runs all inserts atomically in one SQL transaction.
  Future<void> batchInsertTasks(List<TasksCompanion> companions) {
    return batch((b) {
      b.insertAll(tasks, companions, mode: InsertMode.insertOrReplace);
    });
  }

  // ── TRANSACTION ────────────────────────────────────────────────────────
  // Wraps any set of DB writes in an atomic BEGIN/COMMIT block.
  Future<void> toggleWithTransaction(int taskId, bool currentStatus) {
    return transaction(() async {
      await toggleDoneStatus(taskId, currentStatus);
    });
  }

  // ── GROUP BY (aggregate) ───────────────────────────────────────────────
  // SQL: SELECT priority, COUNT(id) FROM tasks GROUP BY priority
  Future<Map<String, int>> getPriorityStats() async {
    final countExpr = tasks.id.count();
    final query = selectOnly(tasks)
      ..addColumns([tasks.priority, countExpr])
      ..groupBy([tasks.priority])
      ..orderBy([OrderingTerm.desc(tasks.priority)]);

    final rows = await query.get();
    final stats = <String, int>{};
    for (final row in rows) {
      final p = row.read(tasks.priority) ?? 1;
      final label = p == 3 ? 'High' : p == 2 ? 'Medium' : 'Low';
      stats[label] = row.read(countExpr) ?? 0;
    }
    return stats;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. DATABASE CLASS
//
// The root class for the Drift database. It:
//   • Declares all tables via allSchemaEntities
//   • Opens the SQLite file via driftDatabase() from drift_flutter
//   • Provides DAO instances as getters
//   • Handles schema migration via MigrationStrategy
// ─────────────────────────────────────────────────────────────────────────────
class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.e);

  // ── SINGLETON ─────────────────────────────────────────────────────────
  // driftDatabase() from drift_flutter opens (or creates) the SQLite file
  // at the platform-specific location and runs all DB operations on a
  // background isolate automatically.
  static AppDatabase? _instance;
  static AppDatabase get instance {
    _instance ??= AppDatabase(driftDatabase(name: 'drift_tasks_demo'));
    return _instance!;
  }

  // Table and DAO instances
  late final $TasksTable tasks = $TasksTable(this);
  late final TasksDao tasksDao = TasksDao(this);

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [tasks];

  @override
  int get schemaVersion => 1;

  // ── MIGRATION STRATEGY ─────────────────────────────────────────────────
  // onCreate: called once on first app install — Drift auto-generates
  //   the CREATE TABLE statement from $columns.
  // onUpgrade: called when schemaVersion is bumped. Use m.addColumn(),
  //   m.createTable() etc. to evolve the schema safely.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Example for v2:
      // if (from < 2) { await m.addColumn(tasks, tasks.someNewColumn); }
    },
  );
}
