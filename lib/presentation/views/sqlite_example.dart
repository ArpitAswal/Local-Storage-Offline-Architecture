import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/route_navigation.dart';
import '../providers/sqlite_viewmodel.dart';
import '../../data/models/todo_item.dart';

/// [SQLiteDemoView] — Interactive TryLab for sqflite.
///
/// Users can practice:
///   - INSERT via form with priority selector
///   - SELECT * with filter chips (all / pending / done)
///   - UPDATE via inline edit form
///   - TOGGLE done via transaction
///   - DELETE single row and DELETE ALL
///   - BATCH INSERT (seed sample data)
///   - GROUP BY aggregate query (priority stats)
///
/// All operations log the exact SQL to the terminal console.
class SQLiteDemoView extends StatefulWidget {
  const SQLiteDemoView({super.key});

  @override
  State<SQLiteDemoView> createState() => _SQLiteDemoViewState();
}

class _SQLiteDemoViewState extends State<SQLiteDemoView> {
  final _titleController = TextEditingController();
  final _dueDateController = TextEditingController();
  int _selectedPriority = 1; // 1=Low, 2=Medium, 3=High

  static const Color sqlColor = Color(0xFF00695C);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SQLiteViewModel>().initialize();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _titleController.clear();
    _dueDateController.clear();
    setState(() => _selectedPriority = 1);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final vm = context.watch<SQLiteViewModel>();

    // Sync form when edit mode activates
    if (vm.editingItem != null) {
      _titleController.text = vm.editingItem!.title;
      _dueDateController.text = vm.editingItem!.dueDate ?? '';
      _selectedPriority = vm.editingItem!.priority;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => RouteNavigation.back(context),
        ),
        title: const Text('SQLite Interactive Lab'),
      ),
      body: !vm.isInitialized
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00695C)))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBanner(vm, colorScheme),
                  const SizedBox(height: 12),
                  _buildTerminal(vm),
                  const SizedBox(height: 12),
                  _buildStatsRow(vm, colorScheme),
                  const SizedBox(height: 12),
                  _buildInsertUpdateCard(vm, colorScheme),
                  const SizedBox(height: 12),
                  _buildFilterAndList(vm, colorScheme),
                  const SizedBox(height: 12),
                  _buildActionsRow(vm, colorScheme),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BANNER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBanner(SQLiteViewModel vm, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sqlColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sqlColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: sqlColor.withValues(alpha: 0.15),
            child: const Icon(Icons.storage, color: Color(0xFF00695C)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('SQLite Todos Table',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold, color: sqlColor)),
                    _chip('${vm.totalCount} rows', sqlColor),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Practicing INSERT, SELECT, UPDATE, DELETE, TRANSACTION, BATCH',
                  style: TextStyle(
                      fontSize: 12, color: sqlColor.withValues(alpha: 0.8), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TERMINAL CONSOLE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTerminal(SQLiteViewModel vm) {
    return Card(
      elevation: 4,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF333333)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                const Icon(Icons.terminal, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 6),
                Text('SQL_LOG',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade400,
                        letterSpacing: 0.5)),
              ]),
              Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
              ]),
            ]),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF333333), height: 1),
            const SizedBox(height: 8),
            Container(
              height: 130,
              decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.all(8),
              child: vm.consoleLogs.isEmpty
                  ? const Center(
                      child: Text('Console idle. Run operations below.',
                          style: TextStyle(
                              fontFamily: 'monospace', fontSize: 11, color: Colors.grey),
                          textAlign: TextAlign.center))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: vm.consoleLogs.length,
                      itemBuilder: (_, i) {
                        final log = vm.consoleLogs[i];
                        Color c = Colors.white70;
                        if (log.contains('INSERT')) c = Colors.greenAccent;
                        if (log.contains('UPDATE')) c = Colors.cyanAccent;
                        if (log.contains('TRANSACTION')) c = Colors.purpleAccent;
                        if (log.contains('DELETE ALL')) c = Colors.red.shade400;
                        if (log.contains('DELETE')) c = Colors.orange.shade400;
                        if (log.contains('QUERY')) c = Colors.lightBlueAccent;
                        if (log.contains('BATCH')) c = Colors.yellow.shade400;
                        if (log.contains('RAW SQL')) c = Colors.tealAccent;
                        if (log.contains('SYSTEM')) c = Colors.purple.shade200;
                        if (log.contains('ERROR')) c = Colors.redAccent;
                        if (log.contains('WARNING')) c = Colors.orangeAccent;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.5),
                          child: Text(log,
                              style: TextStyle(
                                  fontFamily: 'monospace', fontSize: 10.5, color: c, height: 1.4)),
                        );
                      }),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STATS ROW — GROUP BY aggregate
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsRow(SQLiteViewModel vm, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(child: _statCard('Total', '${vm.totalCount}', Icons.list_alt, sqlColor)),
          const SizedBox(width: 8),
          Expanded(child: _statCard('Done', '${vm.doneCount}', Icons.check_circle, Colors.green.shade700)),
          const SizedBox(width: 8),
          Expanded(child: _statCard('Pending', '${vm.pendingCount}', Icons.radio_button_unchecked, Colors.orange.shade700)),
        ]),
        const SizedBox(height: 8),
        // Priority stats from GROUP BY query
        if (vm.priorityStats.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.teal.shade100),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                const Icon(Icons.bar_chart, color: Color(0xFF00695C), size: 18),
                Text('GROUP BY priority: ',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: sqlColor,
                        fontWeight: FontWeight.bold)),
                ...vm.priorityStats.entries.map((e) => Text('${e.key}=${e.value}',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: sqlColor))),
              ],
            ),
          ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: sqlColor,
            side: BorderSide(color: sqlColor.withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onPressed: () => context.read<SQLiteViewModel>().loadPriorityStats(),
          icon: const Icon(Icons.bar_chart, size: 18),
          label: const Text('Run GROUP BY Aggregate Query', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)), overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // INSERT / UPDATE FORM
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildInsertUpdateCard(SQLiteViewModel vm, ColorScheme colorScheme) {
    final isEditing = vm.editingItem != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(isEditing ? Icons.edit : Icons.add_circle_outline, color: sqlColor, size: 22),
            const SizedBox(width: 8),
            Text(isEditing ? 'UPDATE — Edit Todo' : 'INSERT — Add New Todo',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            if (isEditing) ...[
              const Spacer(),
              TextButton(
                onPressed: () {
                  vm.cancelEditing();
                  _clearForm();
                },
                child: const Text('Cancel'),
              ),
            ],
          ]),
          const SizedBox(height: 4),
          Text(
            isEditing
                ? 'db.update("todos", map, where:"id=?", whereArgs:[${vm.editingItem!.id}])'
                : 'db.insert("todos", map, conflictAlgorithm: replace)',
            style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),

          // Title field
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Task Title *',
              hintText: 'e.g., Fix critical bug #421',
              border: const OutlineInputBorder(),
              isDense: true,
              prefixIcon: const Icon(Icons.task_alt, size: 18),
              fillColor: colorScheme.surface,
              filled: true,
            ),
          ),
          const SizedBox(height: 10),

          // Due date field
          TextField(
            controller: _dueDateController,
            decoration: InputDecoration(
              labelText: 'Due Date (optional)',
              hintText: 'e.g., 2024-12-31',
              border: const OutlineInputBorder(),
              isDense: true,
              prefixIcon: const Icon(Icons.calendar_today, size: 18),
              fillColor: colorScheme.surface,
              filled: true,
            ),
          ),
          const SizedBox(height: 12),

          // Priority selector
          Text('Priority:', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _priorityChip(1, 'Low', Colors.green.shade700),
              _priorityChip(2, 'Medium', Colors.orange.shade700),
              _priorityChip(3, 'High', Colors.red.shade700),
            ],
          ),
          const SizedBox(height: 14),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: sqlColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: vm.isLoading ? null : () {
              final vm = context.read<SQLiteViewModel>();
              if (vm.editingItem != null) {
                // UPDATE
                final updated = vm.editingItem!.copyWith(
                  title: _titleController.text,
                  dueDate: _dueDateController.text.isEmpty ? null : _dueDateController.text,
                  priority: _selectedPriority,
                );
                vm.updateTodo(updated);
              } else {
                // INSERT
                vm.addTodo(
                  title: _titleController.text,
                  dueDate: _dueDateController.text.isEmpty ? null : _dueDateController.text,
                  priority: _selectedPriority,
                );
              }
              _clearForm();
            },
            icon: vm.isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(isEditing ? Icons.save : Icons.add),
            label: Text(
              isEditing ? 'Save Update (db.update)' : 'Insert Row (db.insert)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _priorityChip(int value, String label, Color color) {
    final selected = _selectedPriority == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPriority = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FILTER CHIPS + TODO LIST (SELECT with WHERE)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFilterAndList(SQLiteViewModel vm, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.table_rows, color: Color(0xFF00695C), size: 22),
            const SizedBox(width: 8),
            const Text('SELECT — Todo Rows', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          Text(
            'db.query("todos", where:..., orderBy:"priority DESC")',
            style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _filterChip('all', 'All (${vm.totalCount})', vm),
              const SizedBox(width: 8),
              _filterChip('pending', 'Pending (${vm.pendingCount})', vm),
              const SizedBox(width: 8),
              _filterChip('done', 'Done (${vm.doneCount})', vm),
            ]),
          ),
          const SizedBox(height: 12),

          if (vm.todos.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              alignment: Alignment.center,
              child: Column(children: [
                Icon(Icons.inbox, size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text('No rows found. Use INSERT above or seed sample data.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    textAlign: TextAlign.center),
              ]),
            )
          else
            ...vm.todos.map((todo) => _buildTodoTile(todo, vm, colorScheme)),
        ]),
      ),
    );
  }

  Widget _filterChip(String value, String label, SQLiteViewModel vm) {
    final selected = vm.activeFilter == value;
    return GestureDetector(
      onTap: () => context.read<SQLiteViewModel>().setFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? sqlColor : sqlColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? sqlColor : sqlColor.withValues(alpha: 0.25)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.white : sqlColor)),
      ),
    );
  }

  Widget _buildTodoTile(TodoItem todo, SQLiteViewModel vm, ColorScheme colorScheme) {
    final priorityColor = todo.priority == 3
        ? Colors.red.shade700
        : todo.priority == 2
            ? Colors.orange.shade700
            : Colors.green.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: todo.isDone
            ? colorScheme.surfaceContainerLow.withValues(alpha: 0.6)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: todo.isDone
              ? colorScheme.outline.withValues(alpha: 0.08)
              : colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(children: [
          // Toggle done (TRANSACTION)
          GestureDetector(
            onTap: () => context.read<SQLiteViewModel>().toggleDone(todo),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                todo.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                key: ValueKey(todo.isDone),
                color: todo.isDone ? Colors.green : Colors.grey,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                todo.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: todo.isDone ? TextDecoration.lineThrough : null,
                  color: todo.isDone ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 5,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // ID badge
                  _miniTag('id=${todo.id}', Colors.blueGrey),
                  // Priority badge
                  _miniTag(todo.priorityLabel, priorityColor),
                  if (todo.dueDate != null)
                    _miniTag('📅 ${todo.dueDate}', Colors.purple.shade700),
                ],
              ),
            ]),
          ),

          // Edit button
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
            tooltip: 'Edit (UPDATE)',
            onPressed: () => context.read<SQLiteViewModel>().startEditing(todo),
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            tooltip: 'Delete (DELETE WHERE id=?)',
            onPressed: () => context.read<SQLiteViewModel>().deleteTodo(todo.id!),
          ),
        ]),
      ),
    );
  }

  Widget _miniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACTION BUTTONS — BATCH and DELETE ALL
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildActionsRow(SQLiteViewModel vm, ColorScheme colorScheme) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // BATCH seed button
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: vm.isLoading ? null : () => context.read<SQLiteViewModel>().seedSampleData(),
        icon: const Icon(Icons.playlist_add),
        label: const Text('Seed Sample Data (batch.commit)', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 10),

      // DELETE ALL
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          foregroundColor: colorScheme.error,
          backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 13),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: colorScheme.error.withValues(alpha: 0.3)),
          ),
        ),
        onPressed: vm.isLoading
            ? null
            : () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Row(children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete All Rows?'),
                    ]),
                    content: const Text(
                        'This runs DELETE FROM todos — removes all rows but keeps the table schema intact.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _clearForm();
                          context.read<SQLiteViewModel>().deleteAll();
                        },
                        child: const Text('Delete All'),
                      ),
                    ],
                  ),
                ),
        icon: const Icon(Icons.delete_sweep),
        label: const Text('Delete All Rows (db.delete)', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    ]);
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
