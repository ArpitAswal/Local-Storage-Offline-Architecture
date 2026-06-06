import 'package:flutter/material.dart';
import 'sqlite_service.dart';
import 'models/todo_item.dart';

/// [SQLiteViewModel] - MVVM state holder for the SQLite screens.
///
/// Wraps [SQLiteService] calls, maintains UI state, and exposes
/// the data to the View layer via ChangeNotifier.
///
/// State managed:
///   - [todos]          : The current list of TodoItems from the DB
///   - [priorityStats]  : Aggregate count per priority (GROUP BY query result)
///   - [activeFilter]   : The selected filter chip (all / pending / done)
///   - [consoleLogs]    : Terminal-style log of every SQL operation
///   - [isLoading]      : Loading flag to show/hide progress indicators
///   - [editingItem]    : The todo currently being edited (null = add mode)
class SQLiteViewModel extends ChangeNotifier {
  final SQLiteService _service = SQLiteService.instance;

  // ──────────────────────────────────────────────────────────────────────────
  // Private State
  // ──────────────────────────────────────────────────────────────────────────
  bool _isInitialized = false;
  bool _isLoading = false;
  List<TodoItem> _todos = [];
  Map<String, int> _priorityStats = {};
  String _activeFilter = 'all';       // 'all' | 'pending' | 'done'
  final List<String> _consoleLogs = [];
  TodoItem? _editingItem;
  bool _isDemoRunning = false;

  // ──────────────────────────────────────────────────────────────────────────
  // Public Getters
  // ──────────────────────────────────────────────────────────────────────────
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  List<TodoItem> get todos => _todos;
  Map<String, int> get priorityStats => _priorityStats;
  String get activeFilter => _activeFilter;
  List<String> get consoleLogs => _consoleLogs;
  TodoItem? get editingItem => _editingItem;
  bool get isDemoRunning => _isDemoRunning;
  int get totalCount => _todos.length;
  int get doneCount => _todos.where((t) => t.isDone).length;
  int get pendingCount => _todos.where((t) => !t.isDone).length;

  // ──────────────────────────────────────────────────────────────────────────
  // Initialization
  // ──────────────────────────────────────────────────────────────────────────

  /// Opens the database (creates the file + schema if first launch) and loads todos.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _setLoading(true);
    try {
      await _refreshTodos();
      _isInitialized = true;
      _addLog('SYSTEM', 'openDatabase() → local_storage_demo.db opened. Schema v1 ready.');
      _addLog('SYSTEM', 'Table: todos (id, title, is_done, due_date, priority)');
    } catch (e) {
      _addLog('ERROR', 'Initialization failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // INSERT
  // ──────────────────────────────────────────────────────────────────────────

  /// Inserts a new TodoItem and refreshes the list.
  Future<void> addTodo({
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
      final item = TodoItem(
        title: title.trim(),
        dueDate: dueDate,
        priority: priority,
      );
      final newId = await _service.insert(item);
      await _refreshTodos();
      _addLog(
        'INSERT',
        'db.insert("todos", {title:"${title.trim()}", priority:$priority}) → id=$newId',
      );
    } catch (e) {
      _addLog('ERROR', 'INSERT failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UPDATE
  // ──────────────────────────────────────────────────────────────────────────

  /// Updates an existing TodoItem (full replacement via UPDATE WHERE id=?).
  Future<void> updateTodo(TodoItem updated) async {
    _setLoading(true);
    try {
      final affected = await _service.update(updated);
      await _refreshTodos();
      _editingItem = null;
      _addLog(
        'UPDATE',
        'db.update("todos", {...}, where:"id=?", whereArgs:[${updated.id}]) → $affected row(s) affected',
      );
    } catch (e) {
      _addLog('ERROR', 'UPDATE failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TOGGLE DONE — uses a TRANSACTION for atomic read-modify-write
  // ──────────────────────────────────────────────────────────────────────────

  /// Flips the isDone status of a todo using a database transaction.
  Future<void> toggleDone(TodoItem item) async {
    try {
      // FLOW: Uses db.transaction() to ensure the update is atomic.
      // If the app crashes mid-update, the transaction rolls back automatically.
      _setLoading(true);
      await _service.toggleDoneTransaction(item.id!, item.isDone);
      await _refreshTodos();
      _addLog(
        'TRANSACTION',
        'db.transaction { UPDATE todos SET is_done=${item.isDone ? 0 : 1} WHERE id=${item.id} } → committed',
      );
    } catch (e) {
      _addLog('ERROR', 'toggleDone failed: $e');
      notifyListeners();
    } finally{
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DELETE
  // ──────────────────────────────────────────────────────────────────────────

  /// Deletes a single todo by its primary key.
  Future<void> deleteTodo(int id) async {
    _setLoading(true);
    try {
      final affected = await _service.delete(id);
      await _refreshTodos();
      _addLog('DELETE', 'db.delete("todos", where:"id=?", whereArgs:[$id]) → $affected row(s) deleted');
    } catch (e) {
      _addLog('ERROR', 'DELETE failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DELETE ALL — TRUNCATE via DELETE without WHERE
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> deleteAll() async {
    _setLoading(true);
    try {
      final count = await _service.deleteAll();
      _consoleLogs.clear();
      await _refreshTodos();
      _addLog('DELETE ALL', 'db.delete("todos") → $count rows deleted. Table is now empty.');
    } catch (e) {
      _addLog('ERROR', 'DELETE ALL failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BATCH INSERT — Insert multiple rows in one atomic native round-trip
  // ──────────────────────────────────────────────────────────────────────────

  /// Seeds the database with sample todos using Batch for efficiency.
  Future<void> seedSampleData() async {
    _setLoading(true);
    try {
      final samples = [
        const TodoItem(title: 'Buy groceries', priority: 1, dueDate: '2024-12-01'),
        const TodoItem(title: 'Submit project report', priority: 3, dueDate: '2024-11-30'),
        const TodoItem(title: 'Call dentist', priority: 2, dueDate: '2024-12-05'),
        const TodoItem(title: 'Read Flutter docs', priority: 1),
        const TodoItem(title: 'Fix critical bug #421', priority: 3, isDone: true),
      ];
      // FLOW: batch.commit() runs all inserts in ONE native round-trip
      await _service.batchInsert(samples);
      await _refreshTodos();
      _addLog(
        'BATCH',
        'batch.commit() → ${samples.length} todos inserted atomically in one round-trip.',
      );
    } catch (e) {
      _addLog('ERROR', 'Batch insert failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FILTER — changes active filter and reloads todos from DB
  // ──────────────────────────────────────────────────────────────────────────

  /// Changes the active filter and reloads filtered data from the DB.
  Future<void> setFilter(String filter) async {
    _activeFilter = filter;
    _setLoading(true);
    try {
      final filterArg = filter == 'all' ? null : filter;
      _todos = await _service.getAll(filterStatus: filterArg);
      final whereClause = filter == 'done'
          ? 'WHERE is_done = 1'
          : filter == 'pending'
              ? 'WHERE is_done = 0'
              : '(no filter)';
      _addLog('QUERY', 'db.query("todos", $whereClause, orderBy:"priority DESC") → ${_todos.length} row(s)');
    } catch (e) {
      _addLog('ERROR', 'Filter query failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // AGGREGATE — rawQuery with GROUP BY
  // ──────────────────────────────────────────────────────────────────────────

  /// Runs a GROUP BY aggregate query and logs the raw SQL.
  Future<void> loadPriorityStats() async {
    try {
      _priorityStats = await _service.getPriorityStats();
      _addLog(
        'RAW SQL',
        'SELECT priority, COUNT(*) FROM todos GROUP BY priority → $_priorityStats',
      );
      notifyListeners();
    } catch (e) {
      _addLog('ERROR', 'Aggregate query failed: $e');
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Edit mode helpers
  // ──────────────────────────────────────────────────────────────────────────
  void startEditing(TodoItem item) {
    _editingItem = item;
    notifyListeners();
  }

  void cancelEditing() {
    _editingItem = null;
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _refreshTodos() async {
    final filterArg = _activeFilter == 'all' ? null : _activeFilter;
    _todos = await _service.getAll(filterStatus: filterArg);
    _priorityStats = await _service.getPriorityStats();
  }

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
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FOREIGN KEY & CASCADE DELETE DEMO
  // ──────────────────────────────────────────────────────────────────────────

  /// Runs the Foreign Key Enforcement, DatabaseException & Cascade Delete demo.
  Future<void> runForeignKeyDemo() async {
    if (_isDemoRunning) return;
    _isDemoRunning = true;
    _isLoading = true;
    _addLog('DEMO', 'Initializing SQLite Foreign Key & Error Demo...');
    notifyListeners();

    try {
      final steps = await _service.demoForeignKeysAndErrors();
      for (final step in steps) {
        if (step.contains('✅ SUCCESS') || step.contains('✅ CASCADE SUCCESS')) {
          _addLog('DEMO (FK)', step);
        } else if (step.contains('❌ FAILURE') || step.contains('❌ CASCADE FAILURE')) {
          _addLog('WARNING', step);
        } else if (step.contains('Exception')) {
          _addLog('ERROR', step);
        } else {
          _addLog('DEMO (FK)', step);
        }
      }
      await _refreshTodos();
    } catch (e) {
      _addLog('ERROR', 'Foreign key demo failed: $e');
    } finally {
      _isDemoRunning = false;
      _isLoading = false;
      notifyListeners();
    }
  }
}
