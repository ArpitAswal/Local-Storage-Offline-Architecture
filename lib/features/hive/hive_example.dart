import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/navigation/route_navigation.dart';
import 'hive_viewmodel.dart';
import 'models/user.dart';

/// [HiveDemoView] - The interactive lab where users can see Hive
/// CRUD operations (for both primitives and custom data types) in action.
/// Consumes the [HiveViewModel] following pure MVVM architecture.
class HiveDemoView extends StatefulWidget {
  const HiveDemoView({super.key});

  @override
  State<HiveDemoView> createState() => _HiveDemoViewState();
}

class _HiveDemoViewState extends State<HiveDemoView> {
  // ── Form Controllers ──────────────────────────────────────────────────────
  final _primitiveKeyController = TextEditingController();
  final _primitiveValueController = TextEditingController();

  final _userNameController = TextEditingController();
  final _userEmailController = TextEditingController();
  String _selectedRole = 'User'; // Default role in form
  User? _editingUser; // Track user being updated

  // @override
  // void initState() {
  //   super.initState();
  //   // FLOW: Step 1 - Safely initialize the viewmodel states after first frame render.
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     context.read<HiveViewModel>().initialize();
  //   });
  // }

  @override
  void dispose() {
    // FLOW: Step 2 - Dispose controllers to prevent memory leaks.
    _primitiveKeyController.dispose();
    _primitiveValueController.dispose();
    _userNameController.dispose();
    _userEmailController.dispose();
    super.dispose();
  }

  /// Cancels the custom user edit flow and resets the form.
  void _cancelUserEdit() {
    setState(() {
      _editingUser = null;
      _userNameController.clear();
      _userEmailController.clear();
      _selectedRole = 'User';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme
        .of(context)
        .colorScheme;
    final viewModel = context.watch<HiveViewModel>();

    return Scaffold(
      appBar: AppBar(
        // FLOW: Step 3 - RouteNavigation back wrapper.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => RouteNavigation.back(context),
        ),
        title: const Text('Hive Interactive Lab'),
      ),
      body: !viewModel.isInitialized
          ? const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      )
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Section 1: Sandbox Header Banner ───────────────────────
            _buildSandboxHeader(colorScheme),
            const SizedBox(height: 16),

            // ── Section 2: Real-time Terminal Log Console ──────────────
            _buildTerminalConsole(viewModel, colorScheme),
            const SizedBox(height: 16),

            // ── Section 3: Primitive Key-Value CRUD ────────────────────
            _buildPrimitiveCard(viewModel, colorScheme),
            const SizedBox(height: 16),

            // ── Section 4: Custom User CRUD ────────────────────────────
            _buildCustomObjectCard(viewModel, colorScheme),
            const SizedBox(height: 16),

            // ── Section 5: LazyBox Demo ─────────────────────────────────
            _buildLazyBoxCard(viewModel, colorScheme),
            const SizedBox(height: 16),

            // ── Section 6: Encryption Demo ──────────────────────────────
            _buildEncryptionCard(viewModel, colorScheme),
            const SizedBox(height: 24),

            // ── Section 5: Database Maintenance Reset ──────────────────
            _buildResetButton(viewModel, colorScheme),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // PRIVATE COMPONENT WIDGET BUILDERS
  // ===========================================================================

  /// Header introducing the sandbox workspace.
  Widget _buildSandboxHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange.shade200,
            child: Icon(Icons.biotech, color: Colors.orange.shade900),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hive Persistence Sandbox',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Operate on standard keys (String values) or custom structured objects. Check the log console below to view the exact database code running.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade900.withValues(alpha: 0.8),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// Real-time high-fidelity virtual terminal logging system.
  Widget _buildTerminalConsole(HiveViewModel viewModel,
      ColorScheme colorScheme) {
    return Card(
      elevation: 4,
      color: const Color(0xFF1E1E1E), // Obsidian black code color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF333333)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Terminal bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                        Icons.terminal, color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'HIVE_EXECUTION_LOG',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade400,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                // Terminal window controls decoration
                Row(
                  children: [
                    Container(width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Container(width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Colors.amber, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Container(width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Colors.green, shape: BoxShape.circle)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF333333), height: 1),
            const SizedBox(height: 8),

            // Scrollable Console logs
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: viewModel.consoleLogs.isEmpty
                  ? const Center(
                child: Text(
                  'Console Idle. Perform database operations below to trigger action logs.',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: viewModel.consoleLogs.length,
                itemBuilder: (context, index) {
                  final log = viewModel.consoleLogs[index];
                  Color logColor = Colors.white;

                  // FLOW: Color-code log logs based on tags for learning enhancement
                  if (log.contains('CRUD (Create)')) {
                    logColor = Colors.greenAccent;
                  } else if (log.contains('CRUD (Update)')) {
                    logColor = Colors.yellow.shade400;
                  } else if (log.contains('CRUD (Delete)')) {
                    logColor = Colors.red.shade400;
                  } else if (log.contains('SYSTEM')) {
                    logColor = Colors.cyanAccent;
                  } else if (log.contains('BOX')) {
                    logColor = Colors.purpleAccent.shade100;
                  } else if (log.contains('WARNING')) {
                    logColor = Colors.orangeAccent;
                  } else if (log.contains('ERROR')) {
                    logColor = Colors.redAccent;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: logColor,
                        height: 1.4,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ℹ️ Newest operations are appended at the top of the stream.',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  /// Primitive Static Key-Value persistence workspace card.
  Widget _buildPrimitiveCard(HiveViewModel viewModel, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Row(
              children: [
                Icon(Icons.key, color: Colors.orange.shade700, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Primitive Key-Value Playground',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Demonstrates raw schema-less CRUD. Writes primitives directly to settings_box.',
              style: TextStyle(
                  fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),

            // Form Fields
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _primitiveKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Storage Key',
                      hintText: 'e.g., app_theme',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _primitiveValueController,
                    decoration: const InputDecoration(
                      labelText: 'Storage Value',
                      hintText: 'e.g., dark_mode',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Buttons row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      final key = _primitiveKeyController.text.trim();
                      final val = _primitiveValueController.text.trim();

                      if (key.isEmpty || val.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text(
                              '⚠️ Key and Value fields cannot be empty!')),
                        );
                        return;
                      }

                      viewModel.savePrimitive(key, val);
                      _primitiveKeyController.clear();
                      _primitiveValueController.clear();
                    },
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Save Entry (put)'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    _primitiveKeyController.clear();
                    _primitiveValueController.clear();
                  },
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 14),

            const Divider(height: 1),
            const SizedBox(height: 10),

            Text(
              'Stored Entries (settings_box.keys):',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),

            // Render active primitive database values
            viewModel.primitiveData.isEmpty
                ? Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: Text(
                'No key-value pairs stored in settings_box. Insert one above!',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            )
                : Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: viewModel.primitiveData.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final sortedKeys = viewModel.primitiveData.keys.toList();
                  final key = sortedKeys[index];
                  final val = viewModel.primitiveData[key];

                  return ListTile(
                    dense: true,
                    title: Text(
                      key,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      'Value: "$val"',
                      style: TextStyle(fontFamily: 'monospace',
                          color: Colors.orange.shade900),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                          Icons.delete_outline, color: Colors.red, size: 18),
                      onPressed: () {
                        viewModel.deletePrimitive(key);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Custom object (User model class) CRUD persistence workspace card.
  Widget _buildCustomObjectCard(HiveViewModel viewModel,
      ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Row(
              children: [
                Icon(Icons.badge, color: Colors.orange.shade700, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Custom TypeAdapter Sandbox',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Demonstrates Custom Class serialization in Hive using a custom TypeAdapter registered to typeId 0.',
              style: TextStyle(
                  fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            // Form container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        _editingUser != null ? Icons.edit_note : Icons
                            .add_circle_outline,
                        color: Colors.orange.shade900,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _editingUser != null
                            ? 'Edit Stored User'
                            : 'Register New User Object',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Fields
                  TextField(
                    controller: _userNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g., Jane Doe',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _userEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'e.g., jane@example.com',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),

                  // Role selector
                  DropdownButtonFormField<String>(
                    key: ValueKey(_editingUser?.id ?? 'new'),
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Access Role',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Admin', child: Text('Admin (Full Access)')),
                      DropdownMenuItem(
                          value: 'User', child: Text('User (Standard Access)')),
                      DropdownMenuItem(
                          value: 'Guest', child: Text('Guest (View Only)')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Form Operations
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.orange.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            final name = _userNameController.text.trim();
                            final email = _userEmailController.text.trim();

                            if (name.isEmpty || email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text(
                                    '⚠️ Name and Email are mandatory fields!')),
                              );
                              return;
                            }

                            // FLOW: Trigger viewmodel action with editing ID if active
                            viewModel.saveUser(
                              name: name,
                              email: email,
                              role: _selectedRole,
                              existingId: _editingUser?.id,
                            );

                            // Reset editing state and inputs
                            _cancelUserEdit();
                          },
                          icon: Icon(_editingUser != null ? Icons.done : Icons
                              .person_add, size: 16),
                          label: Text(_editingUser != null
                              ? 'Update Record'
                              : 'Save User Object'),
                        ),
                      ),
                      if (_editingUser != null) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.error,
                            side: BorderSide(color: colorScheme.error),
                          ),
                          onPressed: _cancelUserEdit,
                          child: const Text('Cancel'),
                        )
                      ]
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Divider(height: 1),
            const SizedBox(height: 12),

            Text(
              'Saved User Records (users_box.values):',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            // Render custom user cards list
            viewModel.users.isEmpty
                ? Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Text(
                'No User custom models cached in users_box. Add one above!',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: viewModel.users.length,
              itemBuilder: (context, index) {
                final user = viewModel.users[index];

                // Role tags styling
                Color badgeColor = Colors.grey;
                if (user.role == 'Admin') {
                  badgeColor = Colors.red.shade700;
                } else if (user.role == 'User') {
                  badgeColor = Colors.teal.shade700;
                }

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.1)),
                  ),
                  color: colorScheme.surfaceContainerLow,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      foregroundColor: Colors.orange.shade900,
                      child: Text(user.name.substring(0, 1).toUpperCase()),
                    ),
                    title: Row(
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: badgeColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            user.role,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email,
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Key ID: ${user.id}',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit button
                        IconButton(
                          icon: const Icon(
                              Icons.edit, color: Colors.blue, size: 18),
                          onPressed: () {
                            setState(() {
                              _editingUser = user;
                              _userNameController.text = user.name;
                              _userEmailController.text = user.email;
                              _selectedRole = user.role;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    '✍️ User loaded into form. Modify values and tap Update.'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        // Delete button
                        IconButton(
                          icon: const Icon(
                              Icons.delete_forever, color: Colors.red,
                              size: 18),
                          onPressed: () {
                            // If we delete the user currently being edited, cancel the edit flow
                            if (_editingUser?.id == user.id) {
                              _cancelUserEdit();
                            }
                            viewModel.deleteUser(user.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Clean slate wipe button for system resetting.
  Widget _buildResetButton(HiveViewModel viewModel, ColorScheme colorScheme) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        foregroundColor: colorScheme.error,
        backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.error.withValues(alpha: 0.3)),
        ),
      ),
      onPressed: () {
        _cancelUserEdit();
        viewModel.resetAll();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚡ Hive Boxes wiped clean successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      icon: const Icon(Icons.delete_sweep),
      label: const Text(
        'Clear Databases & Logs (Reset All)',
        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  /// LazyBox concept demo card.
  Widget _buildLazyBoxCard(HiveViewModel viewModel, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.purple.shade200.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.layers_outlined, color: Colors.purple.shade700,
                    size: 22),
                const SizedBox(width: 8),
                const Text(
                  'LazyBox Demo',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Text(
                    'Memory Efficient',
                    style: TextStyle(fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'LazyBox loads only KEYS into RAM. Values are read from disk asynchronously on demand. '
                  'Tap the button to write 3 entries and read them back via a LazyBox.',
              style: TextStyle(fontSize: 12.5,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: const Text(
                'final LazyBox<String> box = await Hive.openLazyBox(\'lazy_demo\');\n'
                    'await box.put(\'key1\', \'hello\');       // write same as Box\n'
                    'final val = await box.get(\'key1\'); // async read from disk',
                style: TextStyle(
                    fontFamily: 'monospace', fontSize: 10.5, height: 1.5),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.purple.shade600,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: viewModel.isLazyBoxRunning
                  ? null
                  : () => viewModel.demoLazyBox(),
              icon: viewModel.isLazyBoxRunning
                  ? const SizedBox(width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(
                viewModel.isLazyBoxRunning
                    ? 'Running LazyBox demo...'
                    : 'Run LazyBox Demo',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// AES-256 Encryption demo card.
  Widget _buildEncryptionCard(HiveViewModel viewModel,
      ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.red.shade200.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.red.shade700, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'AES-256 Encryption Demo',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    'HiveAesCipher',
                    style: TextStyle(fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Generates a 256-bit random key, opens a Hive box with HiveAesCipher, '
                  'writes a secret value, then reads it back — the raw .hive file is unreadable without the key.',
              style: TextStyle(fontSize: 12.5,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: const Text(
                'final key = Hive.generateSecureKey(); // 32 random bytes\n'
                    'final box = await Hive.openBox(\n'
                    '  \'enc_box\',\n'
                    '  encryptionCipher: HiveAesCipher(key),\n'
                    ');\n'
                    'await box.put(\'secret\', \'my_api_key\'); // encrypted on disk',
                style: TextStyle(
                    fontFamily: 'monospace', fontSize: 10.5, height: 1.5),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red.shade600,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: viewModel.isEncryptionRunning
                  ? null
                  : () => viewModel.demoEncryption(),
              icon: viewModel.isEncryptionRunning
                  ? const SizedBox(width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.security_rounded, size: 18),
              label: Text(
                viewModel.isEncryptionRunning
                    ? 'Running encryption demo...'
                    : 'Run Encryption Demo',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
