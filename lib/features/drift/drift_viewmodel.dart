import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'drift_database.dart';

/// [DriftViewModel] — MVVM state holder for the Drift database screens.
///
/// Architecture notes:
///   • Wraps [AppDatabase.tasksDao] — all DB calls go through the DAO.
///   • Reactive data: [tasks] is driven by a [StreamSubscription] on the DAO's
///     watchAllTasks() stream. The UI receives automatic updates without any
///     manual refresh calls — this is Drift's signature feature.
///   • Console log: every operation logs the equivalent Drift API call so
///     learners can see what code produced each result.
///
/// State managed:
///   [tasks]         — current task list (updated reactively via stream)
///   [priorityStats] — GROUP BY aggregate result
///   [activeFilter]  — selected filter chip
///   [consoleLogs]   — terminal-style Drift operation log
///   [isLoading]     — loading indicator flag
///   [editingTask]   — task currently in edit mode (null = insert mode)
class DriftViewModel extends ChangeNotifier {
  final AppDatabase _db = AppDatabase.instance;
  TasksDao get _dao => _db.tasksDao;

  // ──────────────────────────────────────────────────────────────────────────
  // Private State
  // ──────────────────────────────────────────────────────────────────────────
  bool _isInitialized = false;
  bool _isLoading = false;
  List<Task> _tasks = [];
  Map<String, int> _priorityStats = {};
  String _activeFilter = 'all';
  final List<String> _consoleLogs = [];
  Task? _editingTask;
  StreamSubscription<List<Task>>? _tasksSub;

  // ──────────────────────────────────────────────────────────────────────────
  // Public Getters
  // ──────────────────────────────────────────────────────────────────────────
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  List<Task> get tasks => _tasks;
  Map<String, int> get priorityStats => _priorityStats;
  String get activeFilter => _activeFilter;
  List<String> get consoleLogs => _consoleLogs;
  Task? get editingTask => _editingTask;
  int get totalCount => _tasks.length;
  int get doneCount => _tasks.where((t) => t.isDone).length;
  int get pendingCount => _tasks.where((t) => !t.isDone).length;

  // ──────────────────────────────────────────────────────────────────────────
  // INITIALIZATION — subscribe to the reactive stream
  //
  // DRIFT KEY CONCEPT: watchAllTasks() returns a Stream<List<Task>>.
  // We subscribe once and let Drift push every change automatically.
  // This is fundamentally different from sqflite where you manually call
  // getAll() after every mutation.
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_isInitialized) return;
    _setLoading(true);
    try {
      // Open the database and fetch the initial task list synchronously
      // (using getAllTasks()) before setting _isInitialized = true.
      // This guarantees the UI has data ready when it first renders.
      _tasks = await _dao.getAllTasks();
      _isInitialized = true;

      // Now subscribe to the reactive stream for subsequent auto-updates.
      _subscribeToStream();

      _addLog('SYSTEM', 'driftDatabase("drift_tasks_demo") opened. Schema v1 ready.');
      _addLog('SYSTEM', 'Reactive stream started: tasksDao.watchAllTasks()');
    } catch (e) {
      // Even on error mark as initialized so the UI renders (with empty state)
      _isInitialized = true;
      _addLog('ERROR', 'Initialization failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // REACTIVE STREAM SUBSCRIPTION
  //
  // FLOW:
  //   1. _dao.watchAllTasks() returns a Stream<List<Task>> backed by SQLite
  //   2. Every INSERT, UPDATE, DELETE on 'tasks' triggers a new emission
  //   3. We update _tasks and call notifyListeners() to rebuild the UI
  //   4. The ViewModel doesn't need to call any "refresh" after mutations!
  // ──────────────────────────────────────────────────────────────────────────
  void _subscribeToStream() {
    _tasksSub?.cancel();
    final filter = _activeFilter == 'all' ? null : _activeFilter;
    _tasksSub = _dao.watchAllTasks(filter: filter).listen(
      (taskList) {
        _tasks = taskList;
        notifyListeners();
      },
      onError: (Object e, StackTrace st) {
        _addLog('ERROR', 'Stream error: $e');
      },
      cancelOnError: false, // keep stream alive even after an error
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // INSERT
  //
  // DRIFT API: into(tasks).insert(TasksCompanion.insert(...))
  // SQL:       INSERT INTO tasks (title, is_done, due_date, priority) VALUES (?, ?, ?, ?)
  //
  // After insert(), the reactive stream emits automatically — no manual reload!
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> addTask({
    required String title,
    String? dueDate,
    required int priority,
  }) async {
    if (title.trim().isEmpty) {
      _addLog('WARNING', 'INSERT aborted: title cannot be empty.');
      notifyListeners();
      return;
    }
    _setLoading(true);
    try {
      final companion = TasksCompanion.insert(
        title: title.trim(),
        dueDate: Value(dueDate?.isNotEmpty == true ? dueDate : null),
        priority: Value(priority),
      );
      final newId = await _dao.insertTask(companion);
      _addLog('INSERT',
          'into(tasks).insert(TasksCompanion(title:"${title.trim()}", priority:$priority)) → id=$newId');
    } catch (e) {
      _addLog('ERROR', 'INSERT failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UPDATE (full row replacement)
  //
  // DRIFT API: update(tasks).replace(companion)
  // SQL:       UPDATE tasks SET title=?, is_done=?, due_date=?, priority=? WHERE id=?
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> updateTask({
    required int id,
    required String title,
    String? dueDate,
    required int priority,
    required bool isDone,
  }) async {
    _setLoading(true);
    try {
      final companion = TasksCompanion(
        id: Value(id),
        title: Value(title.trim()),
        isDone: Value(isDone),
        dueDate: Value(dueDate?.isNotEmpty == true ? dueDate : null),
        priority: Value(priority),
      );
      final success = await _dao.updateTask(companion);
      _editingTask = null;
      _addLog('UPDATE',
          'update(tasks).replace(companion{id:$id, title:"${title.trim()}"}) → ${success ? 'success' : 'no rows affected'}');
    } catch (e) {
      _addLog('ERROR', 'UPDATE failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TOGGLE DONE — uses a TRANSACTION for atomic update
  //
  // DRIFT API: transaction(() async { ... })
  // SQL:       BEGIN; UPDATE tasks SET is_done=? WHERE id=?; COMMIT;
  //
  // Drift's transaction() is simpler than sqflite's — you just wrap code
  // in the callback; Drift handles commit/rollback automatically.
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> toggleDone(Task task) async {
    try {
      await _dao.toggleWithTransaction(task.id, task.isDone);
      _addLog('TRANSACTION',
          'transaction { (update(tasks)..where(id==${task.id})).write(isDone=${!task.isDone}) } → committed');
    } catch (e) {
      _addLog('ERROR', 'toggleDone failed: $e');
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DELETE by ID
  //
  // DRIFT API: (delete(tasks)..where((t) => t.id.equals(id))).go()
  // SQL:       DELETE FROM tasks WHERE id = ?
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> deleteTask(int id) async {
    _setLoading(true);
    try {
      final affected = await _dao.deleteTask(id);
      _addLog('DELETE',
          '(delete(tasks)..where(id==$id)).go() → $affected row(s) deleted');
    } catch (e) {
      _addLog('ERROR', 'DELETE failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DELETE ALL
  //
  // DRIFT API: delete(tasks).go()
  // SQL:       DELETE FROM tasks
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> deleteAll() async {
    _setLoading(true);
    try {
      final count = await _dao.deleteAllTasks();
      _consoleLogs.clear();
      _addLog('DELETE ALL', 'delete(tasks).go() → $count rows deleted. Table is now empty.');
    } catch (e) {
      _addLog('ERROR', 'DELETE ALL failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BATCH INSERT
  //
  // DRIFT API: batch((b) { b.insertAll(tasks, companions); })
  // SQL:       INSERT INTO tasks ... (executed atomically in one transaction)
  //
  // Drift's batch is cleaner than sqflite's — type-safe companions instead
  // of raw Maps. Also runs in a background isolate automatically.
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> seedSampleData() async {
    _setLoading(true);
    try {
      final samples = [
        TasksCompanion.insert(title: 'Buy groceries', priority: const Value(1), dueDate: const Value('2024-12-01')),
        TasksCompanion.insert(title: 'Submit project report', priority: const Value(3), dueDate: const Value('2024-11-30')),
        TasksCompanion.insert(title: 'Call dentist', priority: const Value(2), dueDate: const Value('2024-12-05')),
        TasksCompanion.insert(title: 'Read Drift docs', priority: const Value(1)),
        TasksCompanion.insert(title: 'Fix critical bug #421', priority: const Value(3), isDone: const Value(true)),
      ];
      await _dao.batchInsertTasks(samples);
      _addLog('BATCH',
          'batch { b.insertAll(tasks, ${samples.length} companions) } → inserted atomically');
    } catch (e) {
      _addLog('ERROR', 'Batch insert failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TRANSACTION ROLLBACK & ERROR HANDLING DEMO
  //
  // Catches SqliteException, logs steps and verifies atomicity rollback.
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> runErrorAndRollbackDemo() async {
    if (_isLoading) return;
    _setLoading(true);
    _addLog('─────', '──────────────────────────────────');
    _addLog('ACTION', 'runErrorAndRollbackDemo() called');
    _addLog('TRANSACTION', 'BEGIN TRANSACTION;');

    try {
      await _db.transaction(() async {
        // 1. Insert a temporary task with fixed ID 999
        final companion = TasksCompanion.insert(
          id: const Value(999),
          title: 'Transaction Temp Task #999',
          priority: const Value(2),
        );
        await _dao.insertTask(companion);
        _addLog('INSERT', 'into(tasks).insert(companion{id:999, title:"Transaction Temp Task #999"})');

        // 2. Execute duplicate insert via raw SQL to trigger UNIQUE constraint SqliteException
        _addLog('SQL_EXEC', 'INSERT INTO tasks (id, title, is_done, priority) VALUES (999, "Duplicate", 0, 1);');
        await _db.customStatement('INSERT INTO tasks (id, title, is_done, priority) VALUES (999, "Duplicate", 0, 1);');

        // This will never be reached
        _addLog('TRANSACTION', 'COMMIT TRANSACTION;');
      });
    } catch (e) {
      _addLog('ERROR', 'SqliteException caught: ${e.toString()}');
      _addLog('ROLLBACK', 'Transaction automatically ROLLED BACK. Changes discarded.');
    } finally {
      // 3. Verify that Task 999 does not exist in the database (proves rollback worked)
      final list = await _dao.getAllTasks();
      final hasTask999 = list.any((t) => t.id == 999);
      _addLog('VERIFY', 'Is Task 999 in DB? -> $hasTask999 (Expected: false)');
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FILTER — changes the reactive stream source
  //
  // Drift's watchAllTasks(filter:) applies a WHERE clause to the stream query.
  // We resubscribe with the new filter — the stream emits the filtered data.
  // ──────────────────────────────────────────────────────────────────────────
  void setFilter(String filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    _addLog('QUERY',
        'tasksDao.watchAllTasks(filter:"$filter") → reactive stream re-subscribed');
    _subscribeToStream();
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP BY AGGREGATE
  //
  // DRIFT API: selectOnly(tasks)..addColumns([priority, count])..groupBy([priority])
  // SQL:       SELECT priority, COUNT(id) FROM tasks GROUP BY priority
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> loadPriorityStats() async {
    try {
      _priorityStats = await _dao.getPriorityStats();
      _addLog('AGGREGATE',
          'selectOnly(tasks)..addColumns([priority, id.count()])..groupBy([priority]) → $_priorityStats');
      notifyListeners();
    } catch (e) {
      _addLog('ERROR', 'Aggregate query failed: $e');
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Edit mode helpers
  // ──────────────────────────────────────────────────────────────────────────
  void startEditing(Task task) {
    _editingTask = task;
    notifyListeners();
  }

  void cancelEditing() {
    _editingTask = null;
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _addLog(String type, String message) {
    final now = DateTime.now();
    final t = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    _consoleLogs.insert(0, '[$t] $type: $message');
    notifyListeners();
  }

  @override
  void dispose() {
    _tasksSub?.cancel();
    super.dispose();
  }
}
