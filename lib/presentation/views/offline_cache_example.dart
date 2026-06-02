// =============================================================================
// offline_cache_example.dart
// =============================================================================
// PURPOSE: Interactive TryLab for the Offline-First Repository Pattern.
//
// WHAT THE USER CAN DO:
//   • Tap "Fetch Products" to trigger the cache-first stream
//   • Watch the UI update in two phases (cache → network)
//   • Toggle "Simulate Network Error" to see graceful degradation
//   • Adjust network delay slider (0-5s) to feel real-world latency
//   • "Clear Cache" to simulate first-app-launch (cache miss scenario)
//   • Read the event log to see exactly what the stream emitted and when
//
// KEY OBSERVABLE BEHAVIOURS:
//   ① With cache:    products appear INSTANTLY, then refresh from network
//   ② Without cache: skeleton loads, then products appear from network
//   ③ With error:    stale cache shown + red offline banner (graceful!)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/route_navigation.dart';
import '../providers/offline_viewmodel.dart';
import '../../data/services/offline_repository.dart';

class OfflineCacheDemoView extends StatefulWidget {
  const OfflineCacheDemoView({super.key});

  @override
  State<OfflineCacheDemoView> createState() => _OfflineCacheDemoViewState();
}

class _OfflineCacheDemoViewState extends State<OfflineCacheDemoView>
    with SingleTickerProviderStateMixin {
  static const Color offlineColor = Color(0xFF7B1FA2);
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the "syncing" indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfflineViewModel>().initialize();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OfflineViewModel>();
    final state = vm.state;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => RouteNavigation.back(context),
        ),
        title: const Text('Offline-First Interactive Lab'),
        centerTitle: true,
      ),
      body: !vm.isInitialized
          ? const Center(
              child: CircularProgressIndicator(color: offlineColor),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(vm, state),
                  const SizedBox(height: 12),
                  _buildStatusBanners(state),
                  const SizedBox(height: 12),
                  _buildControlPanel(context, vm),
                  const SizedBox(height: 12),
                  _buildEventLog(vm),
                  const SizedBox(height: 12),
                  _buildProductList(state),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER — shows data source badge, sync status
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(OfflineViewModel vm, RepositoryState state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: offlineColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: offlineColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: offlineColor.withValues(alpha: 0.15),
                child: const Icon(Icons.wifi_off, color: offlineColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Product Repository',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: offlineColor)),
                        _sourceBadge(state),
                        if (state.isLoading) _syncBadge(),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${state.products.length} products · '
                      '${state.source.name.toUpperCase()} data',
                      style: TextStyle(
                          fontSize: 12,
                          color: offlineColor.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (state.lastSyncTime != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.access_time, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                'Last sync: ${_formatTime(state.lastSyncTime!)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _sourceBadge(RepositoryState state) {
    Color color;
    String label;
    IconData icon;

    switch (state.source) {
      case DataSource.cache:
        color = Colors.orange.shade700;
        label = '📦 CACHE';
        icon = Icons.storage;
        break;
      case DataSource.network:
        color = Colors.green.shade700;
        label = '🌐 NETWORK';
        icon = Icons.cloud_done;
        break;
      case DataSource.empty:
        color = Colors.grey.shade600;
        label = '⬜ EMPTY';
        icon = Icons.inbox;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'monospace')),
      ]),
    );
  }

  Widget _syncBadge() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, __) => Opacity(
        opacity: _pulseAnimation.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.shade300),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 5),
            Text('Syncing...',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700)),
          ]),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STATUS BANNERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStatusBanners(RepositoryState state) {
    return Column(children: [
      // Network failure banner
      if (state.networkStatus == NetworkStatus.failure)
        _banner(
          icon: Icons.wifi_off_rounded,
          color: Colors.red.shade700,
          bgColor: Colors.red.shade50,
          borderColor: Colors.red.shade200,
          title: 'Network Unavailable',
          subtitle: state.errorMessage ??
              'Could not reach server. Showing cached data.',
        ),

      // Showing stale cache banner
      if (state.source == DataSource.cache &&
          state.networkStatus == NetworkStatus.loading)
        _banner(
          icon: Icons.history,
          color: Colors.orange.shade700,
          bgColor: Colors.orange.shade50,
          borderColor: Colors.orange.shade200,
          title: 'Showing Cached Data',
          subtitle: 'Background sync in progress... Fresh data will appear shortly.',
        ),

      // Success sync banner (shown briefly)
      if (state.networkStatus == NetworkStatus.success)
        _banner(
          icon: Icons.cloud_done,
          color: Colors.green.shade700,
          bgColor: Colors.green.shade50,
          borderColor: Colors.green.shade200,
          title: 'Synced Successfully',
          subtitle: 'Showing fresh data from network. Cache updated.',
        ),

      // Empty state banner
      if (state.isEmpty && state.networkStatus == NetworkStatus.idle)
        _banner(
          icon: Icons.inbox_outlined,
          color: Colors.grey.shade600,
          bgColor: Colors.grey.shade100,
          borderColor: Colors.grey.shade300,
          title: 'No Data Yet',
          subtitle: 'Tap "Fetch Products" to start the cache-first stream.',
        ),
    ]);
  }

  Widget _banner({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.8),
                    height: 1.3)),
          ]),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CONTROL PANEL
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildControlPanel(BuildContext context, OfflineViewModel vm) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Header
          Row(children: [
            Icon(Icons.tune, color: offlineColor, size: 20),
            const SizedBox(width: 8),
            const Text('Simulation Controls',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 14),

          // ── Primary fetch button ──────────────────────────────────────────
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: offlineColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: vm.state.isLoading
                ? null
                : () => context.read<OfflineViewModel>().fetchProducts(),
            icon: vm.state.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.refresh),
            label: Text(
              vm.state.isLoading
                  ? 'Fetching...'
                  : 'Fetch Products (repo.getProducts())',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Simulate Network Error toggle ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: vm.simulateNetworkError
                  ? Colors.red.shade50
                  : Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: vm.simulateNetworkError
                      ? Colors.red.shade200
                      : Colors.green.shade200),
            ),
            child: Row(children: [
              Icon(
                vm.simulateNetworkError ? Icons.wifi_off : Icons.wifi,
                color: vm.simulateNetworkError
                    ? Colors.red.shade700
                    : Colors.green.shade700,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Simulate Network Error',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: vm.simulateNetworkError
                              ? Colors.red.shade700
                              : Colors.green.shade700),
                    ),
                    Text(
                      vm.simulateNetworkError
                          ? 'Next fetch will FAIL → graceful degradation'
                          : 'Next fetch will SUCCEED → fresh data loaded',
                      style: TextStyle(
                          fontSize: 11,
                          color: vm.simulateNetworkError
                              ? Colors.red.shade600
                              : Colors.green.shade600),
                    ),
                  ],
                ),
              ),
              Switch(
                value: vm.simulateNetworkError,
                onChanged: (_) =>
                    context.read<OfflineViewModel>().toggleSimulateError(),
                activeColor: Colors.red.shade700,
              ),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Network Delay slider ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.timer_outlined, color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 6),
                  Text('Network Delay: ${vm.networkDelaySeconds}s',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700)),
                  const Spacer(),
                  Text(
                    vm.networkDelaySeconds <= 1 ? 'Fast (5G)' 
                        : vm.networkDelaySeconds <= 2 ? 'Normal (4G)'
                        : vm.networkDelaySeconds <= 3 ? 'Slow (3G)'
                        : 'Very Slow (2G)',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
                  ),
                ]),
                Slider(
                  value: vm.networkDelaySeconds.toDouble(),
                  min: 0,
                  max: 5,
                  divisions: 5,
                  activeColor: Colors.blue.shade700,
                  onChanged: (v) =>
                      context.read<OfflineViewModel>().setNetworkDelay(v.toInt()),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Secondary action buttons ───────────────────────────────────────
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                onPressed: () =>
                    context.read<OfflineViewModel>().clearCache(),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Clear Cache',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: offlineColor,
                  side: BorderSide(color: offlineColor.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                onPressed: () => context.read<OfflineViewModel>().clearLog(),
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear Log',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ]),

          const SizedBox(height: 12),

          // ── Scenario quick-select ─────────────────────────────────────────
          const Text('Quick Scenarios:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _scenarioChip(
                context,
                '① Cache Hit',
                'Already cached? Fetch to see instant cache → network update',
                Colors.orange.shade700,
                () {
                  final vmo = context.read<OfflineViewModel>();
                  vmo.setNetworkDelay(2);
                  if (vmo.simulateNetworkError) vmo.toggleSimulateError();
                  vmo.fetchProducts();
                },
              ),
              _scenarioChip(
                context,
                '② Cache Miss',
                'Clear cache first, then fetch — no cache → skeleton → data',
                Colors.blue.shade700,
                () async {
                  final vmo = context.read<OfflineViewModel>();
                  await vmo.clearCache();
                  vmo.setNetworkDelay(2);
                  if (vmo.simulateNetworkError) vmo.toggleSimulateError();
                  vmo.fetchProducts();
                },
              ),
              _scenarioChip(
                context,
                '③ Network Fail',
                'Simulate error — see graceful degradation with stale cache',
                Colors.red.shade700,
                () {
                  final vmo = context.read<OfflineViewModel>();
                  if (!vmo.simulateNetworkError) vmo.toggleSimulateError();
                  vmo.fetchProducts();
                },
              ),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _scenarioChip(
    BuildContext context,
    String label,
    String tooltip,
    Color color,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EVENT LOG — shows stream events in real-time
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildEventLog(OfflineViewModel vm) {
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
            // Terminal bar
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                const Icon(Icons.terminal, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 6),
                Text('STREAM_EVENT_LOG',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade400,
                        letterSpacing: 0.5)),
              ]),
              Row(children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.amber, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle)),
              ]),
            ]),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF333333), height: 1),
            const SizedBox(height: 8),

            // Log list
            Container(
              height: 160,
              decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.all(8),
              child: vm.eventLog.isEmpty
                  ? const Center(
                      child: Text(
                        'Console idle. Tap "Fetch Products" to start.',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: vm.eventLog.length,
                      itemBuilder: (_, i) {
                        final log = vm.eventLog[i];
                        Color c = Colors.white70;
                        if (log.contains('YIELD ①')) c = Colors.orangeAccent;
                        if (log.contains('YIELD ②')) c = Colors.greenAccent;
                        if (log.contains('STREAM')) c = Colors.cyanAccent;
                        if (log.contains('ACTION')) c = Colors.amberAccent;
                        if (log.contains('CACHE')) c = Colors.orange.shade400;
                        if (log.contains('CONFIG')) c = Colors.blue.shade300;
                        if (log.contains('SYSTEM')) c = Colors.purple.shade300;
                        if (log.contains('ERROR')) c = Colors.redAccent;
                        if (log.contains('─────')) {
                          c = const Color(0xFF555555);
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(log,
                              style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  color: c,
                                  height: 1.4)),
                        );
                      }),
            ),

            const SizedBox(height: 8),

            // Legend
            Wrap(spacing: 12, runSpacing: 4, children: [
              _logLegend('YIELD ①', Colors.orangeAccent, 'Cache emit'),
              _logLegend('YIELD ②', Colors.greenAccent, 'Network emit'),
              _logLegend('STREAM', Colors.cyanAccent, 'Subscription'),
              _logLegend('ERROR', Colors.redAccent, 'Failure'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _logLegend(String type, Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text('$type ($label)',
          style: TextStyle(
              fontFamily: 'monospace', fontSize: 9, color: Colors.grey.shade500)),
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRODUCT LIST — the main content area
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildProductList(RepositoryState state) {
    if (state.isEmpty && state.networkStatus == NetworkStatus.loading) {
      // First launch, no cache — show skeleton
      return _buildSkeleton();
    }

    if (state.isEmpty) {
      // No data, no loading
      return _buildEmptyState();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section header
            Row(children: [
              Icon(Icons.inventory_2_outlined, color: offlineColor, size: 20),
              const SizedBox(width: 8),
              const Text('Product Catalogue',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: offlineColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${state.products.length} items',
                    style: TextStyle(
                        fontSize: 11,
                        color: offlineColor,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              state.source == DataSource.network
                  ? 'repo.getProducts() → network → Hive cache updated'
                  : 'repo.getProducts() → Hive cache HIT',
              style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            ...state.products.map((p) => _buildProductTile(p)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTile(Product product) {
    final isNetwork = product.source == 'network';
    final categoryColor = _categoryColor(product.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNetwork
            ? Colors.green.shade50.withValues(alpha: 0.5)
            : Colors.orange.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isNetwork
              ? Colors.green.shade200
              : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_categoryIcon(product.category),
                    color: categoryColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(product.name,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                      if (product.isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('NEW',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ]),
                    const SizedBox(height: 3),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      _miniTag(product.category, categoryColor),
                      _miniTag('⭐ ${product.rating}', Colors.amber.shade700),
                      _miniTag('Stock: ${product.stock}',
                          product.stock < 10
                              ? Colors.red.shade700
                              : Colors.green.shade700),
                      _miniTag(
                        isNetwork ? '🌐 network' : '📦 cache',
                        isNetwork ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('\$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: offlineColor)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            product.description,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
                height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Loading from Network...',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...List.generate(
              4,
              (i) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: offlineColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text('No Products Yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text(
            'Tap "Fetch Products" above to trigger\n'
            'the cache-first stream and load data.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _miniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold)),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Electronics': return Colors.indigo.shade700;
      case 'Sports': return Colors.green.shade700;
      case 'Kitchen': return Colors.orange.shade700;
      case 'Furniture': return Colors.brown.shade700;
      default: return Colors.purple.shade700;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Electronics': return Icons.devices;
      case 'Sports': return Icons.sports;
      case 'Kitchen': return Icons.kitchen;
      case 'Furniture': return Icons.chair;
      default: return Icons.category;
    }
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
