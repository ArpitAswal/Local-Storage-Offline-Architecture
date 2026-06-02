import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/route_navigation.dart';
import '../providers/secure_storage_viewmodel.dart';

/// [SecureStorageDemoView] - Interactive sandbox for flutter_secure_storage.
///
/// Users can practice: write(), read(), readAll(), containsKey(), delete(),
/// and deleteAll() — all using hardware-encrypted AES-256 storage.
/// Each action logs the exact API call to the terminal console.
class SecureStorageDemoView extends StatefulWidget {
  const SecureStorageDemoView({super.key});

  @override
  State<SecureStorageDemoView> createState() => _SecureStorageDemoViewState();
}

class _SecureStorageDemoViewState extends State<SecureStorageDemoView> {
  // ── Form Controllers ─────────────────────────────────────────────────────
  final _writeKeyController = TextEditingController();
  final _writeValueController = TextEditingController();
  final _readKeyController = TextEditingController();
  final _checkKeyController = TextEditingController();

  // Quick-fill presets for demo convenience
  static const _presetKeys = [
    ('jwt_token', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'),
    ('api_key', 'sk-AbCdEf1234567890SecretKey'),
    ('user_id', 'usr_9f3a12bc-4e78-4d9f'),
    ('refresh_token', 'rt_xyzABC987654321longRefreshToken'),
  ];

  static const Color secureColor = Color(0xFFC62828); // Red 800

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SecureStorageViewModel>().initialize();
    });
  }

  @override
  void dispose() {
    _writeKeyController.dispose();
    _writeValueController.dispose();
    _readKeyController.dispose();
    _checkKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final vm = context.watch<SecureStorageViewModel>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => RouteNavigation.back(context),
        ),
        title: const Text('Secure Storage Lab'),
      ),
      body: !vm.isInitialized
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC62828)),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header banner
                  _buildSandboxBanner(vm, colorScheme),
                  const SizedBox(height: 14),

                  // 2. Terminal console
                  _buildTerminalConsole(vm),
                  const SizedBox(height: 14),

                  // 3. Encrypted Vault Viewer (readAll)
                  _buildVaultViewer(vm, colorScheme),
                  const SizedBox(height: 14),

                  // 4. WRITE operation card
                  _buildWriteCard(vm, colorScheme),
                  const SizedBox(height: 14),

                  // 5. READ & CHECK KEY operation card
                  _buildReadCard(vm, colorScheme),
                  const SizedBox(height: 14),

                  // 6. PlatformException & Recovery Demo card
                  _buildErrorRecoveryCard(vm, colorScheme),
                  const SizedBox(height: 14),

                  // 7. DELETE ALL
                  _buildDeleteAllButton(vm, colorScheme),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSandboxBanner(SecureStorageViewModel vm, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFCDD2),
            child: Icon(Icons.shield, color: secureColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Encrypted Vault Sandbox',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: secureColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: secureColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: secureColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${vm.totalKeys} key${vm.totalKeys == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: secureColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'All data is encrypted with AES-256 via Android KeyStore / iOS Keychain. '
                  'Watch the terminal to see exact API calls.',
                  style: TextStyle(
                    fontSize: 12,
                    color: secureColor.withValues(alpha: 0.8),
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

  Widget _buildTerminalConsole(SecureStorageViewModel vm) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.terminal, color: Colors.greenAccent, size: 16),
                  const SizedBox(width: 6),
                  Text('SECURE_STORAGE_LOG',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade400,
                        letterSpacing: 0.5,
                      )),
                ]),
                Row(children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                ]),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF333333), height: 1),
            const SizedBox(height: 8),
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: vm.consoleLogs.isEmpty
                  ? const Center(
                      child: Text(
                        'Console idle. Perform operations below to see live API calls.',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: vm.consoleLogs.length,
                      itemBuilder: (context, index) {
                        final log = vm.consoleLogs[index];
                        Color c = Colors.white;
                        if (log.contains('WRITE')) c = Colors.greenAccent;
                        if (log.contains('READ')) c = Colors.cyanAccent;
                        if (log.contains('CHECK')) c = Colors.yellow.shade400;
                        if (log.contains('DELETE ALL')) c = Colors.red.shade400;
                        if (log.contains('DELETE')) c = Colors.orange.shade400;
                        if (log.contains('SYSTEM')) c = Colors.purpleAccent.shade100;
                        if (log.contains('ERROR')) c = Colors.redAccent;
                        if (log.contains('WARNING')) c = Colors.orangeAccent;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(log,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10.5,
                                color: c,
                                height: 1.4,
                              )),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              'ℹ️ Values are shown as *** in logs — never log secrets in production!',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  /// Shows all keys currently in the vault (readAll) with delete buttons.
  Widget _buildVaultViewer(SecureStorageViewModel vm, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(Icons.lock, color: secureColor, size: 22),
              const SizedBox(width: 8),
              const Text('Encrypted Vault (readAll)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: secureColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${vm.totalKeys}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: secureColor)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              'await storage.readAll() — decrypted for display only',
              style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),

            if (vm.vaultEntries.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                child: Column(children: [
                  Icon(Icons.lock_open_outlined, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('Vault is empty. Use WRITE below to add encrypted entries.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      textAlign: TextAlign.center),
                ]),
              )
            else
              // Quick-fill presets
              ...vm.vaultEntries.entries.map((entry) {
                return _buildVaultEntryTile(entry.key, entry.value, vm, colorScheme);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultEntryTile(
    String key,
    String value,
    SecureStorageViewModel vm,
    ColorScheme colorScheme,
  ) {
    // Mask sensitive values for display — show only first 12 chars + ***
    final maskedValue = value.length > 12
        ? '${value.substring(0, 12)}•••'
        : '•' * value.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.vpn_key, size: 16, color: secureColor.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  maskedValue,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Read button — fills the read key field
          IconButton(
            icon: const Icon(Icons.search, size: 18, color: Colors.blue),
            tooltip: 'Read this key',
            onPressed: () {
              setState(() => _readKeyController.text = key);
              vm.readValue(key: key);
            },
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
            tooltip: 'Delete this key',
            onPressed: () => vm.deleteValue(key: key),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteCard(SecureStorageViewModel vm, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(children: [
              Icon(Icons.lock_outline, color: secureColor, size: 22),
              const SizedBox(width: 8),
              const Text('WRITE — Encrypt & Store', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 4),
            Text(
              'await storage.write(key: ..., value: ...) — AES-256 encrypted',
              style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),

            // Quick-fill preset chips
            Text('Quick presets:', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _presetKeys.map((preset) {
                return ActionChip(
                  label: Text(preset.$1, style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    setState(() {
                      _writeKeyController.text = preset.$1;
                      _writeValueController.text = preset.$2;
                    });
                  },
                  backgroundColor: secureColor.withValues(alpha: 0.08),
                  side: BorderSide(color: secureColor.withValues(alpha: 0.25)),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Key field
            TextField(
              controller: _writeKeyController,
              decoration: const InputDecoration(
                labelText: 'Key (e.g., jwt_token)',
                hintText: 'Unique key name',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.vpn_key, size: 18),
              ),
            ),
            const SizedBox(height: 10),

            // Value field
            TextField(
              controller: _writeValueController,
              decoration: const InputDecoration(
                labelText: 'Value (e.g., Bearer eyJhbG...)',
                hintText: 'Secret value to encrypt',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.security, size: 18),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Write button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: secureColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: vm.isLoading
                  ? null
                  : () {
                      vm.writeValue(
                        key: _writeKeyController.text,
                        value: _writeValueController.text,
                      );
                      _writeKeyController.clear();
                      _writeValueController.clear();
                    },
              icon: vm.isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.lock, size: 18),
              label: const Text('Write & Encrypt', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadCard(SecureStorageViewModel vm, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(Icons.lock_open, color: Colors.blue.shade700, size: 22),
              const SizedBox(width: 8),
              const Text('READ & CHECK', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 4),
            Text(
              'storage.read(key) · storage.containsKey(key)',
              style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),

            // READ section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('READ — Decrypt single value',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade800)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _readKeyController,
                        decoration: InputDecoration(
                          labelText: 'Key to read',
                          hintText: 'e.g., jwt_token',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: vm.isLoading ? null : () => vm.readValue(key: _readKeyController.text),
                      child: const Text('Read', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ]),

                  // Result display
                  if (vm.lastReadKey != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: vm.lastReadValue != null
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: vm.lastReadValue != null
                              ? Colors.green.shade200
                              : Colors.red.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(
                              vm.lastReadValue != null ? Icons.check_circle : Icons.cancel,
                              size: 16,
                              color: vm.lastReadValue != null ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              vm.lastReadValue != null ? 'Key found — value decrypted:' : 'Key "${vm.lastReadKey}" not found in vault',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: vm.lastReadValue != null ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                          ]),
                          if (vm.lastReadValue != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.green.shade100),
                              ),
                              child: Text(
                                vm.lastReadValue!,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // CONTAINS KEY section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('CONTAINS KEY — Check existence without reading',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _checkKeyController,
                        decoration: InputDecoration(
                          labelText: 'Key to check',
                          hintText: 'e.g., jwt_token',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: vm.isLoading ? null : () => vm.checkContainsKey(key: _checkKeyController.text),
                      child: const Text('Check', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ]),

                  if (vm.lastContainsKey != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: vm.lastContainsResult == true ? Colors.green.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: vm.lastContainsResult == true ? Colors.green.shade200 : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(children: [
                        Icon(
                          vm.lastContainsResult == true ? Icons.check_circle : Icons.cancel,
                          color: vm.lastContainsResult == true ? Colors.green : Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'containsKey("${vm.lastContainsKey}") → ${vm.lastContainsResult}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: vm.lastContainsResult == true ? Colors.green.shade800 : Colors.grey.shade700,
                          ),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteAllButton(SecureStorageViewModel vm, ColorScheme colorScheme) {
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
      onPressed: vm.isLoading
          ? null
          : () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Row(children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete All Secrets?'),
                  ]),
                  content: const Text(
                    'This will permanently wipe ALL encrypted entries from the vault.\n\n'
                    'In a real app, call this on user LOGOUT to prevent token leakage.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _writeKeyController.clear();
                        _writeValueController.clear();
                        _readKeyController.clear();
                        _checkKeyController.clear();
                        vm.deleteAll();
                      },
                      child: const Text('Delete All'),
                    ),
                  ],
                ),
              );
            },
      icon: const Icon(Icons.delete_sweep),
      label: const Text(
        'Delete All Secrets (storage.deleteAll) — Use on Logout',
        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3),
      ),
    );
  }

  /// PlatformException Recovery Demo Card
  Widget _buildErrorRecoveryCard(SecureStorageViewModel vm, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(Icons.gpp_bad_outlined, color: secureColor, size: 22),
              const SizedBox(width: 8),
              const Text('PlatformException Recovery Demo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 4),
            Text(
              'Simulates KeyStore decryption failures (invalidated keys, PIN changes) and triggers clean self-healing vault deletion.',
              style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red.shade900,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: vm.isDemoRunning || vm.isLoading
                  ? null
                  : () {
                      _writeKeyController.clear();
                      _writeValueController.clear();
                      _readKeyController.clear();
                      _checkKeyController.clear();
                      vm.simulateDecryptionFailureDemo();
                    },
              icon: vm.isDemoRunning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.warning_amber_outlined, size: 18),
              label: const Text('Simulate KeyStore Failure & Auto-Recovery', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
