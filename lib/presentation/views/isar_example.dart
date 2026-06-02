import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/route_navigation.dart';
import '../providers/isar_viewmodel.dart';
import '../../data/models/isar_contact.dart';

/// [IsarDemoView] - The interactive lab where users can practice Isar CRUD
/// operations — create, read, filter by role, search by name, update, and delete.
///
/// Powered by [IsarViewModel] following strict MVVM architecture.
/// Demonstrates: Isar.open, writeTxn, put, get, delete, filter(), where(), sortByName().
class IsarDemoView extends StatefulWidget {
  const IsarDemoView({super.key});

  @override
  State<IsarDemoView> createState() => _IsarDemoViewState();
}

class _IsarDemoViewState extends State<IsarDemoView> {
  // ── Form Controllers ────────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _searchController = TextEditingController();
  String _selectedRole = 'User';
  IsarContact? _editingContact; // Non-null = edit mode

  static const Color isarColor = Color(0xFFE64A19); // Deep Orange 700

  @override
  void initState() {
    super.initState();
    // FLOW: Safely initialize viewmodel after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IsarViewModel>().initialize();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Clears edit mode and resets the form fields.
  void _cancelEdit() {
    setState(() {
      _editingContact = null;
      _nameController.clear();
      _emailController.clear();
      _streetController.clear();
      _cityController.clear();
      _zipController.clear();
      _selectedRole = 'User';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewModel = context.watch<IsarViewModel>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => RouteNavigation.back(context),
        ),
        title: const Text('Isar Interactive Lab'),
      ),
      body: !viewModel.isInitialized
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE64A19)),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Section 1: Sandbox Header ──────────────────────────────
                  _buildSandboxHeader(viewModel, colorScheme),
                  const SizedBox(height: 16),

                  // ── Section 2: Terminal Console Log ────────────────────────
                  _buildTerminalConsole(viewModel),
                  const SizedBox(height: 16),

                  // ── Section 3: Search + Filter Bar ─────────────────────────
                  _buildSearchFilterBar(viewModel, colorScheme),
                  const SizedBox(height: 16),

                  // ── Section 4: Contact Form (Create / Update) ──────────────
                  _buildContactFormCard(viewModel, colorScheme),
                  const SizedBox(height: 16),

                  // ── Section 4.5: Error Handling & Concurrency Demo ─────────
                  _buildErrorConcurrencyCard(viewModel, colorScheme),
                  const SizedBox(height: 16),

                  // ── Section 5: Stored Contacts List ────────────────────────
                  _buildContactList(viewModel, colorScheme),
                  const SizedBox(height: 16),

                  // ── Section 6: Reset Button ────────────────────────────────
                  _buildResetButton(viewModel, colorScheme),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE WIDGET BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Hero banner introducing the Isar sandbox.
  Widget _buildSandboxHeader(IsarViewModel viewModel, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBE9E7), // Deep orange 50
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCCBC)), // Deep orange 100
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFCCBC),
            child: Icon(Icons.biotech, color: isarColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Isar Persistence Sandbox',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isarColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Live record count badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isarColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isarColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${viewModel.totalCount} records',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isarColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Create contacts, filter by role, search by name, update, and delete. '
                  'Watch the terminal console to see exact Isar API calls.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isarColor.withValues(alpha: 0.8),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Real-time terminal console showing logged Isar execution commands.
  Widget _buildTerminalConsole(IsarViewModel viewModel) {
    return Card(
      elevation: 4,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF333333)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Terminal title bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.terminal, color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'ISAR_EXECUTION_LOG',
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
                // Window decoration dots
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF333333), height: 1),
            const SizedBox(height: 8),

            // Scrollable log entries
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: viewModel.consoleLogs.isEmpty
                  ? const Center(
                      child: Text(
                        'Console idle. Perform database operations below to see live Isar API calls.',
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

                        // Color-code by operation type for readability
                        if (log.contains('CRUD (Create)')) {
                          logColor = Colors.greenAccent;
                        } else if (log.contains('CRUD (Update)')) {
                          logColor = Colors.yellow.shade400;
                        } else if (log.contains('CRUD (Delete)')) {
                          logColor = Colors.red.shade400;
                        } else if (log.contains('READ (Query)')) {
                          logColor = Colors.cyanAccent;
                        } else if (log.contains('SYSTEM')) {
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
                              fontSize: 10.5,
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
              'ℹ️ Newest operations appear at the top of the log.',
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

  /// Search field + role filter chips bar.
  Widget _buildSearchFilterBar(IsarViewModel viewModel, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section title
            Row(
              children: [
                Icon(Icons.search, color: isarColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Search & Filter Queries',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Demonstrates filter().nameContains() and filter().roleEqualTo() — type-safe Isar query builders.',
              style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),

            // Search input
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by name (filter().nameContains)',
                hintText: 'e.g., Alice',
                border: const OutlineInputBorder(),
                isDense: true,
                prefixIcon: const Icon(Icons.manage_search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          viewModel.searchContacts('');
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
                viewModel.searchContacts(value);
              },
            ),
            const SizedBox(height: 12),

            // Role filter chips
            Text(
              'Filter by Role (filter().roleEqualTo — uses @Index):',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['All', 'Admin', 'User', 'Guest'].map((role) {
                final isActive = viewModel.activeRoleFilter == role;
                Color chipColor = isarColor;
                if (role == 'Admin') chipColor = Colors.red.shade700;
                if (role == 'User') chipColor = Colors.teal.shade700;
                if (role == 'Guest') chipColor = Colors.grey.shade600;

                return FilterChip(
                  label: Text(role),
                  selected: isActive,
                  onSelected: (_) {
                    _searchController.clear();
                    viewModel.filterByRole(role);
                  },
                  backgroundColor: colorScheme.surfaceContainerLow,
                  selectedColor: chipColor.withValues(alpha: 0.2),
                  checkmarkColor: chipColor,
                  labelStyle: TextStyle(
                    color: isActive ? chipColor : colorScheme.onSurfaceVariant,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isActive ? chipColor : colorScheme.outline.withValues(alpha: 0.2),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Contact creation / update form card.
  Widget _buildContactFormCard(IsarViewModel viewModel, ColorScheme colorScheme) {
    final isEditing = _editingContact != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Row(
              children: [
                Icon(
                  isEditing ? Icons.edit_note : Icons.person_add,
                  color: isarColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  isEditing ? 'Update Contact Record' : 'Create New Contact',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isEditing
                  ? 'Modify fields below. put() with existing id triggers an UPDATE in Isar.'
                  : 'Fill form and save. Isar auto-assigns the integer id via Isar.autoIncrement.',
              style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),

            // Form container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBE9E7).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFCCBC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Edit mode indicator
                  if (isEditing) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.amber.shade800, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Editing ID: ${_editingContact!.id} — changes will use put(contact) to update',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.amber.shade900,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Name field
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g., Alice Chen',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Email field
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'e.g., alice@example.com',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),

                  // Role dropdown
                  DropdownButtonFormField<String>(
                    key: ValueKey(_editingContact?.id ?? 'new'),
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Access Role',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Admin', child: Text('Admin (Full Access)')),
                      DropdownMenuItem(value: 'User', child: Text('User (Standard Access)')),
                      DropdownMenuItem(value: 'Guest', child: Text('Guest (View Only)')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedRole = value);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Embedded Address section
                  const Text(
                    'Embedded Address (Optional):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _streetController,
                          decoration: const InputDecoration(
                            labelText: 'Street',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _zipController,
                    decoration: const InputDecoration(
                      labelText: 'ZIP Code',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: isarColor,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            final name = _nameController.text.trim();
                            final email = _emailController.text.trim();

                            if (name.isEmpty || email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('⚠️ Name and Email are required!')),
                              );
                              return;
                            }

                            if (isEditing) {
                              viewModel.updateContact(
                                id: _editingContact!.id,
                                name: name,
                                email: email,
                                role: _selectedRole,
                                street: _streetController.text.trim(),
                                city: _cityController.text.trim(),
                                zipCode: _zipController.text.trim(),
                              );
                            } else {
                              viewModel.createContact(
                                name: name,
                                email: email,
                                role: _selectedRole,
                                street: _streetController.text.trim(),
                                city: _cityController.text.trim(),
                                zipCode: _zipController.text.trim(),
                              );
                            }
                            _cancelEdit();
                          },
                          icon: Icon(isEditing ? Icons.done : Icons.save, size: 16),
                          label: Text(
                            isEditing ? 'Update Record' : 'Save Contact (put)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      if (isEditing) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.error,
                            side: BorderSide(color: colorScheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _cancelEdit,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders the list of stored IsarContact objects.
  Widget _buildContactList(IsarViewModel viewModel, ColorScheme colorScheme) {
    final contacts = viewModel.contacts;
    final isFiltered = viewModel.activeRoleFilter != 'All' || viewModel.isSearching;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section header
            Row(
              children: [
                Icon(Icons.people_alt, color: isarColor, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Stored Contacts',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // Count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isarColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${contacts.length}${isFiltered ? ' of ${viewModel.totalCount}' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isarColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'isar.isarContacts.where().sortByName().findAll() — sorted by indexed name field',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // Empty state
            if (contacts.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 28),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      isFiltered
                          ? 'No contacts match your current filter/search.'
                          : 'No contacts yet. Use the form above to create one!',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  return _buildContactTile(contacts[index], viewModel, colorScheme);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// A single contact list tile with avatar, role badge, edit/delete actions.
  Widget _buildContactTile(
    IsarContact contact,
    IsarViewModel viewModel,
    ColorScheme colorScheme,
  ) {
    // Role color coding
    Color roleColor = Colors.grey.shade600;
    if (contact.role == 'Admin') roleColor = Colors.red.shade700;
    if (contact.role == 'User') roleColor = Colors.teal.shade700;

    // Highlight the tile currently being edited
    final isBeingEdited = _editingContact?.id == contact.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isBeingEdited
            ? Colors.amber.shade50
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBeingEdited
              ? Colors.amber.shade300
              : colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFCCBC),
          foregroundColor: isarColor,
          radius: 22,
          child: Text(
            contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                contact.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: roleColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                contact.role,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: roleColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.email, style: const TextStyle(fontSize: 12)),
            if (contact.address != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.home_outlined, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${contact.address!.street ?? ""}, ${contact.address!.city ?? ""} ${contact.address!.zipCode ?? ""}',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 2),
            // Auto-incremented integer ID display — key learning point
            Text(
              'id: ${contact.id}  •  ${_formatDate(contact.createdAt)}',
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
              icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
              onPressed: () {
                setState(() {
                  _editingContact = contact;
                  _nameController.text = contact.name;
                  _emailController.text = contact.email;
                  _selectedRole = contact.role;
                  _streetController.text = contact.address?.street ?? '';
                  _cityController.text = contact.address?.city ?? '';
                  _zipController.text = contact.address?.zipCode ?? '';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✍️ Contact loaded into form. Modify and tap Update.'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red, size: 18),
              onPressed: () {
                if (_editingContact?.id == contact.id) _cancelEdit();
                viewModel.deleteContact(contact.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Factory reset button that clears all Isar records.
  Widget _buildResetButton(IsarViewModel viewModel, ColorScheme colorScheme) {
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
        _cancelEdit();
        _searchController.clear();
        viewModel.resetAll();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚡ Isar database cleared — all contacts deleted!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      icon: const Icon(Icons.delete_sweep),
      label: const Text(
        'Clear All Records (isar.isarContacts.clear())',
        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3),
      ),
    );
  }

  /// Error Handling & Concurrency Demo interactive Card.
  Widget _buildErrorConcurrencyCard(IsarViewModel viewModel, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section title
            Row(
              children: [
                Icon(Icons.lock_reset_outlined, color: isarColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Error Handling & Concurrency Demo',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Demonstrates transaction rollbacks and non-blocking reads during active writes.',
              style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: viewModel.isRollbackRunning || viewModel.isConcurrencyRunning
                        ? null
                        : () => viewModel.runTransactionRollbackDemo(),
                    icon: viewModel.isRollbackRunning
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.undo, size: 16),
                    label: const Text(
                      'Rollback Demo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.indigo.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: viewModel.isConcurrencyRunning || viewModel.isRollbackRunning
                        ? null
                        : () => viewModel.runConcurrencyDemo(),
                    icon: viewModel.isConcurrencyRunning
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.shuffle, size: 16),
                    label: const Text(
                      'Concurrency Demo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Formats a DateTime into a readable short string.
  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }
}
