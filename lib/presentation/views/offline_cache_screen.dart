// =============================================================================
// offline_cache_screen.dart
// =============================================================================
// PURPOSE (View Layer — MVVM):
//   Educational guide explaining the Offline-First Repository Pattern.
//   Covers: Repository pattern, async* generator, Cache-First strategy,
//   graceful degradation, and how real apps like Spotify/Gmail use this.
// =============================================================================

import 'package:flutter/material.dart';
import '../navigation/route_navigation.dart';
import '../widgets/extension_widgets.dart';
import 'offline_cache_example.dart';

/// [OfflineCacheScreen] — Educational guide for the Offline-First pattern.
class OfflineCacheScreen extends StatelessWidget {
  const OfflineCacheScreen({super.key});

  static const Color offlineColor = Color(0xFF7B1FA2); // Purple 700

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => RouteNavigation.back(context),
        ),
        centerTitle: true,
        title: const Text('Offline-First Guide'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () =>
                  RouteNavigation.push(context, const OfflineCacheDemoView()),
              icon: const Icon(Icons.science, size: 18, color: offlineColor),
              label: const Text(
                'Try Lab',
                style: TextStyle(
                  color: offlineColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero ─────────────────────────────────────────────────────
              context.headTitle(
                'Offline-First: Repository + Cache Strategy',
                offlineColor,
              ),
              context.dividerSpace(16),

              context.subHeadTitle(
                'Offline-First is not a library — it\'s an architectural pattern. '
                'The Repository layer coordinates between a local cache (Hive) '
                'and a remote API, ensuring users always see content instantly, '
                'even with no internet connection.',
              ),
              context.dividerSpace(16),

              // ── Real-World Context ────────────────────────────────────────
              _buildRealWorldCard(context),
              const SizedBox(height: 20),

              // ── Section 1: Architecture Diagram ─────────────────────────
              context.headTitle('1. Architecture Overview', colorScheme.secondary),
              const SizedBox(height: 10),

              context.theoryContentText(
                'The Repository is the single source of truth for the ViewModel. '
                'It hides whether data came from local cache or a remote API. '
                'The ViewModel and UI never touch Hive or HTTP directly.',
              ),
              const SizedBox(height: 10),

              _buildArchDiagram(context),
              const SizedBox(height: 20),

              // ── Section 2: Setup ──────────────────────────────────────────
              context.headTitle('2. Setup & pubspec.yaml', colorScheme.secondary),
              const SizedBox(height: 10),

              context.contentText('Add to pubspec.yaml', offlineColor),
              context.contentSectionContainer(
                'dependencies:\n'
                '  hive: ^2.2.3         # Local cache\n'
                '  hive_flutter: ^1.1.0 # Flutter init helper\n'
                '  path_provider: ^2.1.2 # Find device DB path',
              ),

              context.contentText('Initialize Hive in main.dart', offlineColor),
              context.contentSectionContainer(
                'void main() async {\n'
                '  WidgetsFlutterBinding.ensureInitialized();\n'
                '  await Hive.initFlutter(); // sets up file path\n'
                '  runApp(const MyApp());\n'
                '}',
              ),
              const SizedBox(height: 20),

              // ── Section 3: The Repository Class ──────────────────────────
              context.headTitle('3. The Repository Pattern', colorScheme.secondary),
              const SizedBox(height: 10),

              context.theoryContentText(
                'A Repository is a class that abstracts data access. '
                'It is the ONLY place in your codebase that knows '
                'about both the local cache and the remote API. '
                'This is the Clean Architecture principle: '
                '"depend on abstractions, not concretions."',
              ),
              const SizedBox(height: 10),

              context.contentText('Repository skeleton', offlineColor),
              context.contentSectionContainer(
                'class ProductRepository {\n'
                '  static const _boxName = \'product_cache\';\n'
                '  static const _cacheKey = \'products\';\n'
                '  late Box _box;\n\n'
                '  Future<void> initialize() async {\n'
                '    _box = await Hive.openBox(_boxName);\n'
                '  }\n\n'
                '  // Read cached products from Hive\n'
                '  List<Product> _readCache() { ... }\n\n'
                '  // Write fetched products to Hive\n'
                '  Future<void> _writeCache(List<Product> p) { ... }\n\n'
                '  // Clear cache (simulate fresh install)\n'
                '  Future<void> clearCache() { ... }\n\n'
                '  // The main offline-first stream ↓\n'
                '  Stream<RepositoryState> getProducts() async* { ... }\n'
                '}',
              ),
              const SizedBox(height: 20),

              // ── Section 4: Cache Write/Read ───────────────────────────────
              context.headTitle('4. Hive as the Cache Layer', colorScheme.secondary),
              const SizedBox(height: 10),

              context.theoryContentText(
                'We store products as JSON Maps in a plain Hive Box — '
                'no TypeAdapter needed for this simple case. '
                'Each product is serialized with toJson() before storing '
                'and deserialized with Product.fromJson() when reading.',
              ),
              const SizedBox(height: 10),

              context.contentText('Serialize & write to Hive', offlineColor),
              context.contentSectionContainer(
                'Future<void> _writeCache(List<Product> products) async {\n'
                '  // Convert each Product → Map<String, dynamic>\n'
                '  // Hive stores it as binary but you write/read Maps\n'
                '  await _box.put(\n'
                '    \'products\',\n'
                '    products.map((p) => p.toJson()).toList(),\n'
                '  );\n'
                '  // Record sync timestamp\n'
                '  await _box.put(\'last_sync\', DateTime.now().toIso8601String());\n'
                '}',
              ),

              context.contentText('Read & deserialize from Hive', offlineColor),
              context.contentSectionContainer(
                'List<Product> _readCache() {\n'
                '  final raw = _box.get(\'products\'); // returns List<dynamic>\n'
                '  if (raw == null) return [];         // MISS: empty cache\n'
                '  // Cast each Map back to Product\n'
                '  return (raw as List)\n'
                '      .map((item) => Product.fromJson(item, source: \'cache\'))\n'
                '      .toList();\n'
                '}',
              ),
              const SizedBox(height: 20),

              // ── Section 5: async* generator ───────────────────────────────
              context.headTitle('5. async* Generator — The Core Mechanism',
                  colorScheme.secondary),
              const SizedBox(height: 10),

              context.theoryContentText(
                'The async* keyword creates an asynchronous generator function.\n\n'
                '• A regular async function returns ONE future value.\n'
                '• An async* function returns a STREAM of values over time.\n'
                '• Each "yield" emits one event to the stream and pauses.\n'
                '• This lets us emit cache first, then network — in sequence.',
              ),
              const SizedBox(height: 10),

              context.contentText('Cache-First async* stream', offlineColor),
              context.contentSectionContainer(
                'Stream<RepositoryState> getProducts() async* {\n'
                '  // ① Read cache synchronously (no await needed!)\n'
                '  final cached = _readCache();\n\n'
                '  // ① yield cache IMMEDIATELY — user sees content instantly\n'
                '  //   networkStatus = loading → shows sync badge, not spinner\n'
                '  yield RepositoryState(\n'
                '    products: cached,\n'
                '    source: cached.isEmpty ? empty : cache,\n'
                '    networkStatus: loading,  // background fetch starting\n'
                '  );\n\n'
                '  // ② Fetch from API in background (2-4 seconds)\n'
                '  try {\n'
                '    final fresh = await api.fetchProducts();\n\n'
                '    await _writeCache(fresh); // update Hive\n\n'
                '    // ② yield fresh network data — UI refreshes smoothly\n'
                '    yield RepositoryState(\n'
                '      products: fresh,\n'
                '      source: network,\n'
                '      networkStatus: success,\n'
                '    );\n'
                '  } catch (e) {\n'
                '    // ② GRACEFUL DEGRADATION — show stale cache + error\n'
                '    yield RepositoryState(\n'
                '      products: cached,  // stale but STILL VISIBLE!\n'
                '      source: cache,\n'
                '      networkStatus: failure,\n'
                '      errorMessage: e.toString(),\n'
                '    );\n'
                '  }\n'
                '  // Stream completes automatically after the last yield\n'
                '}',
              ),
              const SizedBox(height: 20),

              // ── Section 6: ViewModel subscribes ──────────────────────────
              context.headTitle('6. ViewModel Subscribes to the Stream',
                  colorScheme.secondary),
              const SizedBox(height: 10),

              context.theoryContentText(
                'The ViewModel subscribes to getProducts() and updates '
                'its state on each emission. The UI rebuilds automatically '
                'via Provider\'s notifyListeners(), with no additional wiring.',
              ),
              const SizedBox(height: 10),

              context.contentText('ViewModel subscription', offlineColor),
              context.contentSectionContainer(
                'class OfflineViewModel extends ChangeNotifier {\n'
                '  RepositoryState _state = const RepositoryState();\n'
                '  RepositoryState get state => _state;\n\n'
                '  void fetchProducts() {\n'
                '    _sub?.cancel(); // cancel previous fetch\n\n'
                '    _sub = _repo.getProducts().listen((state) {\n'
                '      _state = state;     // update on every yield\n'
                '      notifyListeners();  // rebuild UI\n'
                '    });\n'
                '    // Note: listen() returns immediately!\n'
                '    // The stream emits asynchronously in the background.\n'
                '  }\n'
                '}',
              ),
              const SizedBox(height: 20),

              // ── Section 7: UI pattern ─────────────────────────────────────
              context.headTitle('7. UI — Reacting to RepositoryState',
                  colorScheme.secondary),
              const SizedBox(height: 10),

              context.theoryContentText(
                'The UI uses context.watch<OfflineViewModel>() (Provider) '
                'and reads state fields to decide what to render. '
                'There is never a full-screen spinner — the cache is shown '
                'immediately alongside a subtle "Syncing..." badge.',
              ),
              const SizedBox(height: 10),

              context.contentText('UI state branching', offlineColor),
              context.contentSectionContainer(
                'final vm = context.watch<OfflineViewModel>();\n'
                'final state = vm.state;\n\n'
                'if (state.isEmpty && state.isLoading) {\n'
                '  // First launch, no cache yet → show skeleton loader\n'
                '  return SkeletonList();\n'
                '}\n\n'
                'return Column(children: [\n'
                '  if (state.isLoading)\n'
                '    SyncingBanner(), // subtle top bar: "Syncing..."\n\n'
                '  if (state.networkStatus == failure)\n'
                '    OfflineBanner(error: state.errorMessage),\n\n'
                '  // Products are ALWAYS shown — from cache or network\n'
                '  ProductList(products: state.products),\n'
                ']);',
              ),
              const SizedBox(height: 20),

              // ── Section 8: Graceful Degradation ───────────────────────────
              context.headTitle('8. Graceful Degradation', colorScheme.secondary),
              const SizedBox(height: 10),

              context.theoryContentText(
                'Graceful degradation means failing GRACEFULLY — not with a '
                'blank screen or error dialog, but by showing the best '
                'available data alongside a clear status message.\n\n'
                '• Network success → show fresh data\n'
                '• Network failure → show stale cache + "Offline" banner\n'
                '• No cache, no network → show "No data" with retry button',
              ),
              const SizedBox(height: 10),

              _buildDegradationTable(context),
              const SizedBox(height: 20),

              // ── Section 9: When to use ────────────────────────────────────
              context.headTitle(
                  '9. When to Use This Pattern', colorScheme.secondary),
              const SizedBox(height: 10),

              _buildUseCaseGrid(context),
              const SizedBox(height: 20),

              // ── Section 10: Production Tips ───────────────────────────────
              context.headTitle('10. Production Tips', colorScheme.secondary),
              const SizedBox(height: 10),

              _buildProductionTips(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildRealWorldCard(BuildContext context) {
    final apps = [
      ('🎵', 'Spotify', 'Shows playlists from cache before network loads'),
      ('📧', 'Gmail', 'Shows last emails, syncs in background'),
      ('📸', 'Instagram', 'Cached feed renders instantly while refreshing'),
      ('🚗', 'Uber', 'Shows last map state while live data loads'),
      ('🛒', 'Amazon', 'Cached product list with background price update'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [offlineColor.withValues(alpha: 0.08), Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: offlineColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.star_rounded, color: offlineColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Used in Every Major App',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: offlineColor,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          ...apps.map((a) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.$1, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.$2,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: offlineColor)),
                          Text(a.$3,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.purple.shade700,
                                  height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildArchDiagram(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ARCHITECTURE FLOW',
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.grey,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          _archRow('UI (Widget)', '← notifyListeners()', Colors.cyanAccent),
          _archArrow('↕ context.watch<OfflineViewModel>()'),
          _archRow('OfflineViewModel', '← subscribe to Stream', Colors.greenAccent),
          _archArrow('↕ repo.getProducts() → Stream<State>'),
          _archRow('ProductRepository', '← orchestrates', Colors.amberAccent),
          _archArrow('↙               ↘'),
          Row(children: [
            Expanded(child: _archRow('Hive Cache', 'Local', Colors.orangeAccent)),
            const SizedBox(width: 8),
            Expanded(child: _archRow('Mock API', 'Remote', Colors.purpleAccent)),
          ]),
          const SizedBox(height: 8),
          const Text(
            '// The ViewModel and UI never talk to Hive or API directly',
            style: TextStyle(
                fontFamily: 'monospace', fontSize: 10.5, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _archRow(String label, String role, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ),
          Text(role,
              style: TextStyle(
                  fontFamily: 'monospace', fontSize: 10, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _archArrow(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
      child: Text(label,
          style: const TextStyle(
              fontFamily: 'monospace', fontSize: 11, color: Colors.grey)),
    );
  }

  Widget _buildDegradationTable(BuildContext context) {
    final rows = [
      ('✅', 'Cache Hit + Network OK', 'Show fresh data. Cache updated.', Colors.green),
      ('⚠️', 'Cache Hit + Network Fail', 'Show stale cache + offline banner.', Colors.orange),
      ('⏳', 'Cache Miss + Network OK', 'Show skeleton → fresh data loads.', Colors.blue),
      ('❌', 'Cache Miss + Network Fail', 'Show empty state + retry button.', Colors.red),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: offlineColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final i = e.key;
          final r = e.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: i.isEven
                  ? offlineColor.withValues(alpha: 0.04)
                  : Colors.transparent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(i == 0 ? 10 : 0),
                topRight: Radius.circular(i == 0 ? 10 : 0),
                bottomLeft: Radius.circular(i == rows.length - 1 ? 10 : 0),
                bottomRight: Radius.circular(i == rows.length - 1 ? 10 : 0),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.$1, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.$2,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: r.$4)),
                      const SizedBox(height: 2),
                      Text(r.$3,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUseCaseGrid(BuildContext context) {
    final cases = [
      (Icons.rss_feed, 'News & Feeds', 'Articles cached → read offline', offlineColor),
      (Icons.shopping_bag, 'E-Commerce', 'Products cached → browse offline', Colors.orange.shade700),
      (Icons.map, 'Maps & Location', 'Map tiles cached → view offline', Colors.teal.shade700),
      (Icons.music_note, 'Media Apps', 'Playlists cached → play offline', Colors.red.shade700),
      (Icons.message, 'Messaging', 'Messages cached → read offline', Colors.blue.shade700),
      (Icons.analytics, 'Dashboards', 'Metrics cached → view trends offline', Colors.green.shade700),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: cases.map((c) => SizedBox(
        width: (MediaQuery.of(context).size.width - 52) / 2,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.$4.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.$4.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(c.$1, color: c.$4, size: 22),
              const SizedBox(height: 6),
              Text(c.$2,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: c.$4)),
              const SizedBox(height: 3),
              Text(c.$3,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      height: 1.3)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildProductionTips(BuildContext context) {
    final tips = [
      ('💾', 'Cache Expiry', 
        'Store lastSyncTime in Hive. Re-fetch automatically if cache is older than X minutes.'),
      ('📏', 'Cache Size Limit',
        'Store only the most recent N items. Use box.values.take(100) to cap memory.'),
      ('🔐', 'Secure Caching',
        'Never cache sensitive data (JWT, PII) in Hive. Use flutter_secure_storage instead.'),
      ('🔄', 'Background Sync',
        'Use WorkManager or background_fetch to sync while app is closed.'),
      ('📡', 'Connectivity Check',
        'Use connectivity_plus to detect network state and skip API calls when offline.'),
      ('🧪', 'Testability',
        'The Repository pattern makes it trivial to inject a MockRepository in unit tests.'),
    ];

    return Column(
      children: tips.map((t) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: offlineColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: offlineColor.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.$1, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.$2,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: offlineColor)),
                  const SizedBox(height: 4),
                  Text(t.$3,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}