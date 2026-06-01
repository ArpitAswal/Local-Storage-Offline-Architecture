import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/route_navigation.dart';
import '../providers/drift_viewmodel.dart';
import '../../data/services/drift_database.dart';

/// [DriftDemoView] — Interactive TryLab for Drift.
///
/// Users can practice:
///   - INSERT via form with priority selector
///   - SELECT * via reactive stream (auto-updating — no manual refresh!)
///   - FILTER via chips (all / pending / done)
///   - UPDATE via inline edit form
///   - TOGGLE done via transaction
///   - DELETE single task and DELETE ALL
///   - BATCH INSERT (seed sample data)
///   - GROUP BY aggregate query (priority stats)
///
/// The key difference from SQLiteDemoView: the task list AUTOMATICALLY
/// updates after every mutation without any manual reload calls.
class DriftDemoView extends StatefulWidget {
  const DriftDemoView({super.key});

  @override
  State<DriftDemoView> createState() => _DriftDemoViewState();
}

class _DriftDemoViewState extends State<DriftDemoView> {
  final _titleController = TextEditingController();
  final _dueDateController = TextEditingController();
  int _selectedPriority = 1;

  static const Color driftColor = Color(0xFF3949AB); // Indigo 700

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriftViewModel>().initialize();
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
    final vm = context.watch<DriftViewModel>();

    if (vm.editingTask != null) {
      _titleController.text = vm.editingTask!.title;
      _dueDateController.text = vm.editingTask!.dueDate ?? '';
      _selectedPriority = vm.editingTask!.priority;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => RouteNavigation.back(context),
        ),
        title: const Text('Drift Interactive Lab'),
      ),
      body: !vm.isInitialized
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3949AB)))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBanner(vm, colorScheme),
                  const SizedBox(height: 12),
                  _buildReactiveHighlight(colorScheme),
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
  Widget _buildBanner(DriftViewModel vm, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: driftColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: driftColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: driftColor.withValues(alpha: 0.15),
            child: const Icon(Icons.table_chart, color: Color(0xFF3949AB)),
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
                    Text('Drift Tasks Table',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: driftColor)),
                    _chip('${vm.totalCount} rows', driftColor),
                    _chip('🌊 Reactive', Colors.blue.shade700),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'INSERT, SELECT (stream), UPDATE, DELETE, TRANSACTION, BATCH',
                  style: TextStyle(
                      fontSize: 12,
                      color: driftColor.withValues(alpha: 0.8),
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // REACTIVE HIGHLIGHT CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildReactiveHighlight(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: driftColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stream, color: Color(0xFF3949AB), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌊 Reactive Stream Active',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: driftColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'tasksDao.watchAllTasks() is streaming live. Every INSERT, UPDATE, DELETE auto-updates this list — no manual refresh!',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.indigo.shade700,
                    height: 1.4,
                  ),
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
  Widget _buildTerminal(DriftViewModel vm) {
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
                Text('DRIFT_LOG',
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
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Colors.grey),
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
                        if (log.contains('AGGREGATE')) c = Colors.tealAccent;
                        if (log.contains('SYSTEM')) c = Colors.purple.shade200;
                        if (log.contains('ERROR')) c = Colors.redAccent;
                        if (log.contains('WARNING')) c = Colors.orangeAccent;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.5),
                          child: Text(log,
                              style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10.5,
                                  color: c,
                                  height: 1.4)),
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
  Widget _buildStatsRow(DriftViewModel vm, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(child: _statCard('Total', '${vm.totalCount}', Icons.list_alt, driftColor)),
          const SizedBox(width: 8),
          Expanded(child: _statCard('Done', '${vm.doneCount}', Icons.check_circle, Colors.green.shade700)),
          const SizedBox(width: 8),
          Expanded(child: _statCard('Pending', '${vm.pendingCount}', Icons.radio_button_unchecked, Colors.orange.shade700)),
        ]),
        const SizedBox(height: 8),
        if (vm.priorityStats.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.indigo.shade100),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.bar_chart, color: Color(0xFF3949AB), size: 18),
                Text('GROUP BY priority: ',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: driftColor,
                        fontWeight: FontWeight.bold)),
                ...vm.priorityStats.entries.map((e) => Text(
                    '${e.key}=${e.value}',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: driftColor))),
              ],
            ),
          ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: driftColor,
            side: BorderSide(color: driftColor.withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onPressed: () => context.read<DriftViewModel>().loadPriorityStats(),
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
            Text(label,
                style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // INSERT / UPDATE FORM
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildInsertUpdateCard(DriftViewModel vm, ColorScheme colorScheme) {
    final isEditing = vm.editingTask != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(isEditing ? Icons.edit : Icons.add_circle_outline, color: driftColor, size: 22),
            const SizedBox(width: 8),
            Text(isEditing ? 'UPDATE — Edit Task' : 'INSERT — Add New Task',
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
                ? 'update(tasks).replace(TasksCompanion(id:Value(${vm.editingTask!.id}), ...))'
                : 'into(tasks).insert(TasksCompanion.insert(title:..., priority:...))',
            style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
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
              backgroundColor: driftColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: vm.isLoading
                ? null
                : () {
                    final vm = context.read<DriftViewModel>();
                    if (vm.editingTask != null) {
                      vm.updateTask(
                        id: vm.editingTask!.id,
                        title: _titleController.text,
                        dueDate: _dueDateController.text.isEmpty ? null : _dueDateController.text,
                        priority: _selectedPriority,
                        isDone: vm.editingTask!.isDone,
                      );
                    } else {
                      vm.addTask(
                        title: _titleController.text,
                        dueDate: _dueDateController.text.isEmpty ? null : _dueDateController.text,
                        priority: _selectedPriority,
                      );
                    }
                    _clearForm();
                  },
            icon: vm.isLoading
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(isEditing ? Icons.save : Icons.add),
            label: Text(
              isEditing ? 'Save Update (update.replace)' : 'Insert Task (into.insert)',
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
  // FILTER CHIPS + TASK LIST
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFilterAndList(DriftViewModel vm, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.stream, color: Color(0xFF3949AB), size: 22),
            const SizedBox(width: 8),
            const Text('WATCH — Reactive Task Stream', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          Text(
            'tasksDao.watchAllTasks(filter: "${vm.activeFilter}") → Stream<List<Task>>',
            style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
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
          if (vm.tasks.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              alignment: Alignment.center,
              child: Column(children: [
                Icon(Icons.inbox, size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text('No tasks found. Use INSERT above or seed sample data.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    textAlign: TextAlign.center),
              ]),
            )
          else
            ...vm.tasks.map((task) => _buildTaskTile(task, vm, colorScheme)),
        ]),
      ),
    );
  }

  Widget _filterChip(String value, String label, DriftViewModel vm) {
    final selected = vm.activeFilter == value;
    return GestureDetector(
      onTap: () => context.read<DriftViewModel>().setFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? driftColor : driftColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? driftColor : driftColor.withValues(alpha: 0.25)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.white : driftColor)),
      ),
    );
  }

  Widget _buildTaskTile(Task task, DriftViewModel vm, ColorScheme colorScheme) {
    final priorityColor = task.priority == 3
        ? Colors.red.shade700
        : task.priority == 2
            ? Colors.orange.shade700
            : Colors.green.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: task.isDone
            ? colorScheme.surfaceContainerLow.withValues(alpha: 0.6)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: task.isDone
              ? colorScheme.outline.withValues(alpha: 0.08)
              : colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(children: [
          // Toggle done via TRANSACTION
          GestureDetector(
            onTap: () => context.read<DriftViewModel>().toggleDone(task),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                task.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                key: ValueKey(task.isDone),
                color: task.isDone ? Colors.green : Colors.grey,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                task.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                  color: task.isDone ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 5,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _miniTag('id=${task.id}', Colors.blueGrey),
                  _miniTag(task.priorityLabel, priorityColor),
                  if (task.dueDate != null)
                    _miniTag('📅 ${task.dueDate}', Colors.purple.shade700),
                ],
              ),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
            tooltip: 'Edit (UPDATE)',
            onPressed: () => context.read<DriftViewModel>().startEditing(task),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            tooltip: 'Delete',
            onPressed: () => context.read<DriftViewModel>().deleteTask(task.id),
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
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              color: color,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold)),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACTION BUTTONS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildActionsRow(DriftViewModel vm, ColorScheme colorScheme) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: vm.isLoading
            ? null
            : () => context.read<DriftViewModel>().seedSampleData(),
        icon: const Icon(Icons.playlist_add),
        label: const Text('Seed Sample Data (batch insertAll)', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 10),
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
                      Text('Delete All Tasks?'),
                    ]),
                    content: const Text(
                        'This runs delete(tasks).go() — removes all rows but keeps the table schema intact.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _clearForm();
                          context.read<DriftViewModel>().deleteAll();
                        },
                        child: const Text('Delete All'),
                      ),
                    ],
                  ),
                ),
        icon: const Icon(Icons.delete_sweep),
        label: const Text('Delete All Tasks (delete.go)', style: TextStyle(fontWeight: FontWeight.bold)),
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
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color)),
    );
  }
}
