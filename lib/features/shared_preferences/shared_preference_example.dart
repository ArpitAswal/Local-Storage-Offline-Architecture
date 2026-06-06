import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/navigation/route_navigation.dart';
import 'shared_preferences_viewmodel.dart';

/// [SharedPreferencesDemoView] - The interactive lab where users can see
/// SharedPreferences, SharedPreferencesAsync, and SharedPreferencesWithCache in action.
/// Built strictly following the MVVM pattern and powered by Provider.
class SharedPreferencesDemoView extends StatefulWidget {
  const SharedPreferencesDemoView({super.key});

  @override
  State<SharedPreferencesDemoView> createState() => _SharedPreferencesDemoViewState();
}

class _SharedPreferencesDemoViewState extends State<SharedPreferencesDemoView> {
  final _deleteKeyController = TextEditingController();

  @override
  void dispose() {
    _deleteKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // FLOW: Step 1 - Consume the SharedPreferencesViewModel via Provider.
    final viewModel = context.watch<SharedPreferencesViewModel>();

    return Scaffold(
      appBar: AppBar(
        // FLOW: Step 2 - Use RouteNavigation instead of raw Pop in the lead back button.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => RouteNavigation.back(context),
        ),
        title: const Text('Interactive Persistence Lab'),
      ),
      body: !viewModel.isInitialized
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Hero Sandbox Header ────────────────────────────────────
                  _buildSandboxHeader(colorScheme),
                  const SizedBox(height: 24),

                  // ── Sandbox Card 1: SharedPreferencesWithCache ───────────────
                  _buildInteractiveCard(
                    context,
                    title: 'SharedPreferencesWithCache',
                    badgeText: '💨 Fast Mem-Cache Reads',
                    badgeColor: Colors.teal,
                    description: 'Synchronously reads from an in-memory cache. Writes are backgrounded and written asynchronously to the hardware disk.',
                    value: viewModel.counter.toString(),
                    icon: Icons.flash_on,
                    buttonLabel: 'Increment (Sync + Cache)',
                    onPressed: () {
                      // FLOW: Trigger increment counter action on the View Model
                      viewModel.incrementCounter();
                    },
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 20),

                  // ── Sandbox Card 2: SharedPreferencesAsync ──────────────────
                  _buildInteractiveCard(
                    context,
                    title: 'SharedPreferencesAsync',
                    badgeText: '🛡️ Direct Disk Round-trip',
                    badgeColor: Colors.indigo,
                    description: 'Directly reads and writes to persistent storage asynchronously without holding a local cache, avoiding potential stale memory.',
                    value: viewModel.externalCounter.toString(),
                    icon: Icons.cloud_done_outlined,
                    buttonLabel: 'Increment (Direct Async)',
                    onPressed: () {
                      // FLOW: Trigger increment external counter action on the View Model
                      viewModel.incrementExternalCounter();
                    },
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 20),

                  // ── Sandbox Card 3: Speed Benchmark & Guidelines Comparison ──
                  _buildBenchmarkCard(context, viewModel, colorScheme),
                  const SizedBox(height: 20),

                  // ── Sandbox Card 4: Delete Key Demo ────────────────────────
                  _buildDeleteKeyCard(context, viewModel, colorScheme),
                  const SizedBox(height: 20),

                  // ── Sandbox Card 5: Error Handling Demo ───────────────────
                  _buildErrorHandlingCard(context, viewModel, colorScheme),
                  const SizedBox(height: 28),

                  // ── Reset Button Action ────────────────────────────────────
                  ElevatedButton.icon(
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
                      // FLOW: Trigger factory reset on local storage
                      viewModel.resetAll();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚡ Local Storage cleared successfully!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text(
                      'Clear Storage & Reset Counters',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ===========================================================================
  // PRIVATE COMPONENT BUILDERS
  // ===========================================================================

  Widget _buildDeleteKeyCard(
    BuildContext context,
    SharedPreferencesViewModel viewModel,
    ColorScheme colorScheme,
  ) {
    final controller = TextEditingController();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade200.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.delete_sweep_outlined, color: Colors.red.shade700, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Delete / Remove a Key',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Demonstrates remove() and clear() APIs. Type an existing key name and remove it '
              'from SharedPreferencesWithCache. Or clear ALL keys at once.',
              style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Key to delete (e.g. counter)',
                hintText: 'Enter key name',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.key_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      final key = controller.text.trim();
                      if (key.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('⚠️ Please enter a key name to delete.')),
                        );
                        return;
                      }
                      viewModel.deleteKey(key);
                      controller.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🗑️ remove(\'$key\') executed — key deleted from cache+disk.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('remove(key)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Info box explaining the code running
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Text(
                '📌 Code running:\n'
                'await prefsWithCache.remove(key); // removes from memory cache + disk\n'
                'await asyncPrefs.remove(key);      // removes directly from disk',
                style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.red.shade900, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorHandlingCard(
    BuildContext context,
    SharedPreferencesViewModel viewModel,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.amber.shade300.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Error Handling Demo',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Simulates common beginner mistakes: reading a key with the wrong type, '
              'and reading a non-existent key without a default value.',
              style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 14),
            // Error state display
            if (viewModel.lastErrorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade800, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        viewModel.lastErrorMessage!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontFamily: 'monospace',
                          color: Colors.amber.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.amber.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => viewModel.simulateTypeMismatch(),
                    icon: const Icon(Icons.bug_report_outlined, size: 18),
                    label: const Text('Simulate Type Mismatch', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                '// Code that runs:\n'
                'await prefs.setInt(\'counter\', 42);\n'
                'final String? result = prefs.getString(\'counter\');\n'
                '// result = null (type mismatch — no crash!)',
                style: TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSandboxHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.biotech, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Storage Sandbox',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap increments to see values update in real-time. Changes are immediately saved and survive app restarts.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
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

  Widget _buildInteractiveCard(
    BuildContext context, {
    required String title,
    required String badgeText,
    required Color badgeColor,
    required String description,
    required String value,
    required IconData icon,
    required String buttonLabel,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Title & Badge Row
            Row(
              children: [
                Icon(icon, color: badgeColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Badge tag
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Card Description
            Text(
              description,
              style: TextStyle(
                fontSize: 12.5,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Live State Monitor Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Stored Value:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: badgeColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'taps',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Trigger Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: badgeColor,
                elevation: 1,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onPressed,
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenchmarkCard(
    BuildContext context,
    SharedPreferencesViewModel viewModel,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Title
            Row(
              children: [
                Icon(Icons.speed, color: colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'API Speed & Architectural Benchmark',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Educational Overview
            Text(
              'While both storage types execute read and write tasks, they implement vastly different internal architectures that affect your application speed.',
              style: TextStyle(
                fontSize: 12.5,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // Best Practice Guidelines Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildGuidelineRow(
                    icon: Icons.flash_on,
                    iconColor: Colors.teal,
                    title: 'Use SharedPreferencesWithCache when:',
                    body: 'Reading preferences during UI rendering, builds, or loops. Reads are synchronous, drawing directly from memory instantly (0ms UI lag).',
                  ),
                  const Divider(height: 18),
                  _buildGuidelineRow(
                    icon: Icons.sync_alt,
                    iconColor: Colors.indigo,
                    title: 'Use SharedPreferencesAsync when:',
                    body: 'Data is written from companion apps, notification widgets, native OS extensions, or background Isolates. Protects against out-of-sync cache stale data.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Performance Benchmark State Controller
            if (viewModel.isBenchmarking) ...[
              // Benchmarking Loading View
              Column(
                children: [
                  const SizedBox(height: 8),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                  Text(
                    viewModel.benchmarkExplanation,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ] else if (viewModel.benchmarkCompleted) ...[
              // Benchmark Results Visual Chart
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Average Read Latency per Operation:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Cache Speed Visual Bar (Teal)
                  _buildLatencyBar(
                    label: 'SharedPreferencesWithCache (Instant Sync Memory)',
                    latencyUs: viewModel.cacheAvgLatencyUs,
                    maxLatencyUs: viewModel.asyncAvgLatencyUs,
                    barColor: Colors.teal,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 16),

                  // Async Speed Visual Bar (Indigo)
                  _buildLatencyBar(
                    label: 'SharedPreferencesAsync (Asynchronous Platform Channel)',
                    latencyUs: viewModel.asyncAvgLatencyUs,
                    maxLatencyUs: viewModel.asyncAvgLatencyUs,
                    barColor: Colors.indigo,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 16),

                  // Result Explanation Block
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      viewModel.benchmarkExplanation,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Re-run Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      viewModel.runPerformanceBenchmark();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Re-run Speed Test'),
                  ),
                ],
              ),
            ] else ...[
              // Initial Play Button State
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  viewModel.runPerformanceBenchmark();
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'Run Live Performance Speed Test',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLatencyBar({
    required String label,
    required double latencyUs,
    required double maxLatencyUs,
    required Color barColor,
    required ColorScheme colorScheme,
  }) {
    // Determine dynamic visual width ratio. Min width is 4% to ensure visibility.
    final double ratio = maxLatencyUs == 0.0 ? 0.05 : (latencyUs / maxLatencyUs).clamp(0.04, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${latencyUs.toStringAsFixed(2)} μs',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            // Background bar track
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            // Foreground bar representation
            FractionallySizedBox(
              widthFactor: ratio,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: barColor.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
