import 'package:flutter/material.dart';
import '../navigation/route_navigation.dart';
import '../widgets/extension_widgets.dart';
import 'shared_preference_example.dart';

/// [SharedPreferenceScreen] - The educational view layer demonstrating
/// SharedPreferences, SharedPreferencesAsync, and SharedPreferencesWithCache.
class SharedPreferenceScreen extends StatelessWidget {
  const SharedPreferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        // FLOW: Step 1 - Use RouteNavigation instead of raw Navigator pop for the back arrow.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => RouteNavigation.back(context),
        ),
        centerTitle: true,
        title: const Text("Shared Preference Guide"),
        actions: [
          // FLOW: Step 2 - Open the interactive lab view using RouteNavigation.
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () {
                RouteNavigation.push(context, const SharedPreferencesDemoView());
              },
              icon: Icon(Icons.science, size: 18, color: colorScheme.primary),
              label: Text(
                "Try Lab",
                style: TextStyle(
                  color: colorScheme.primary,
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
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Title (Extension call) ──────────────────────────────
              context.headTitle(
                "SharedPreferences vs Async vs WithCache",
                colorScheme.primary,
              ),
              context.dividerSpace(16),
              
              context.subHeadTitle(
                "In Flutter, SharedPreferences is a key-value store backed by XML on Android and NSUserDefaults on iOS. Flutter 3.22 introduced major performance upgrades via modern async & cache architectures.",
              ),
              context.dividerSpace(16),
              
              // ── Examples Section Header ────────────────────────────────────
              context.headTitle("Code Implementations", colorScheme.secondary),
              const SizedBox(height: 12),

              // ── Subsection 1: Legacy SharedPreferences ──────────────────────
              context.contentText("1. Legacy SharedPreferences (Classic)", Colors.blue.shade700),
              context.contentSectionContainer("""// Obtain shared preferences.
final SharedPreferences prefs = await SharedPreferences.getInstance();

// Save an integer value to 'counter' key.
await prefs.setInt('counter', 10);

// Save a boolean value to 'repeat' key.
await prefs.setBool('repeat', true);

// Save a String value to 'action' key.
await prefs.setString('action', 'Start');"""),
              
              context.contentText("Reading Data (Legacy)", Colors.blue.shade700),
              context.contentSectionContainer("""// Try reading data. If it doesn't exist, returns null.
final int? counter = prefs.getInt('counter');
final bool? repeat = prefs.getBool('repeat');
final String? action = prefs.getString('action');"""),

              context.theoryContentText(
                "⚠️ Warning: The legacy SharedPreferences API relies on an in-memory XML dump. Calling getInstance() performs a blocking synchronous read on Android/iOS startup which can cause UI jank. It is recommended to migrate to the newer APIs below.",
              ),
              context.dividerSpace(16),

              // ── Subsection 2: SharedPreferencesAsync ───────────────────────
              context.contentText("2. SharedPreferencesAsync (No-Cache)", Colors.indigo.shade700),
              context.contentSectionContainer("""// Bypasses local memory cache entirely. Directly queries native APIs asynchronously.
final asyncPrefs = SharedPreferencesAsync();

// Saves asynchronously
await asyncPrefs.setBool('repeat', true);
await asyncPrefs.setString('action', 'Start');

// Reads asynchronously (always fetches fresh data from hardware disk)
final bool? repeat = await asyncPrefs.getBool('repeat');
final String? action = await asyncPrefs.getString('action');

// Any time a filter option is included, strongly consider using it.
await asyncPrefs.clear(allowList: <String>{'action', 'repeat'});"""),

              context.theoryContentText(
                "💡 Best Use Case: Ideal if you write to the preferences from background isolates, native Kotlin/Swift code, or another thread. Because it doesn't keep a static memory cache, it never goes stale.",
              ),
              context.dividerSpace(16),

              // ── Subsection 3: SharedPreferencesWithCache ────────────────────
              context.contentText("3. SharedPreferencesWithCache (Super-Fast Cached)", Colors.teal.shade700),
              context.contentSectionContainer("""// Synchronous reads with asynchronous background writes.
final SharedPreferencesWithCache prefsWithCache = 
    await SharedPreferencesWithCache.create(
  cacheOptions: const SharedPreferencesWithCacheOptions(
    // When an allowlist is included, any keys that aren't included cannot be used.
    allowList: <String>{'counter'},
  ),
);

// Writes asynchronously in the background.
await prefsWithCache.setInt('counter', 15);

// Reads synchronously and instantly from memory cache!
final int? counter = prefsWithCache.getInt('counter');"""),

              context.theoryContentText(
                "⚡ Best Use Case: Ideal for the vast majority of app preferences (e.g., Theme, Flags) because reading is instant (synchronous) without causing UI lag. Keys outside the allowList are blocked to keep memory small.",
              ),
              context.dividerSpace(16),

              // ── Subsection 4: Data Migration ───────────────────────────────
              context.contentText("4. Legacy to Async Migration", Colors.orange.shade700),
              context.contentSectionContainer("""import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

const sharedPreferencesOptions = SharedPreferencesOptions();
final SharedPreferences prefs = await SharedPreferences.getInstance();

// Migrates legacy entries to SharedPreferencesAsync safely without data loss.
await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
  legacySharedPreferencesInstance: prefs,
  sharedPreferencesAsyncOptions: sharedPreferencesOptions,
  migrationCompletedKey: 'migrationCompleted',
);"""),

              context.theoryContentText(
                "🚀 Run this migration utility once during application startup. It reads the legacy settings, writes them to the new Async storage, and sets the 'migrationCompletedKey' to prevent duplicate migrations on subsequent boots.",
              ),
              context.dividerSpace(24),

              // ── Subsection 5: Setup & pubspec.yaml ────────────────────────
              context.headTitle("5. Setup & pubspec.yaml", colorScheme.secondary),
              const SizedBox(height: 12),
              context.contentText("Add to pubspec.yaml", Colors.blue.shade700),
              context.contentSectionContainer(
                """dependencies:
  shared_preferences: ^2.5.5
  # That's it! No code generators, no build_runner, no native plugins to configure.
  # Works out of the box on Android, iOS, macOS, Windows, Linux, and Web.

# PLATFORM NOTES (no action required — everything is automatic):
#   Android → XML file at /data/data/<pkg>/shared_prefs/
#   iOS     → NSUserDefaults (plist in app sandbox)
#   macOS   → NSUserDefaults (~/Library/Preferences/)
#   Windows → Registry or local app data file
#   Web     → localStorage (browser key-value storage)
#   Linux   → XDG config directory

# ⚠️ No permissions, no native manifest changes, no entitlements needed.
# SharedPreferences is the ONLY Flutter database that requires zero platform setup.""",
              ),
              context.theoryContentText(
                "💡 Unlike Hive (needs Hive.initFlutter()), Isar (needs isar_flutter_libs binary), "
                "or SQLite (needs path setup), SharedPreferences has ZERO setup overhead. "
                "Just add the dependency and call getInstance() — that's it.",
              ),
              context.dividerSpace(20),

              // ── Subsection 6: Delete & Clear APIs ─────────────────────────
              context.headTitle("6. Delete & Clear (All 3 APIs)", colorScheme.secondary),
              const SizedBox(height: 12),
              context.contentText("Legacy SharedPreferences — remove() & clear()", Colors.blue.shade700),
              context.contentSectionContainer(
                """final SharedPreferences prefs = await SharedPreferences.getInstance();

// DELETE a single key:
await prefs.remove('counter');     // Returns bool (true = key existed)
await prefs.remove('repeat');      // No-op if key doesn't exist (no error)

// WIPE all keys across the entire SharedPreferences file:
await prefs.clear();
// ⚠️ clear() on legacy removes EVERY key in the XML file.
// Use it carefully — it deletes ALL app preferences at once!

// CHECK key existence before deleting (optional best practice):
if (prefs.containsKey('counter')) {
  await prefs.remove('counter');
}""",
              ),
              context.contentText("SharedPreferencesAsync — remove() & clear(allowList)", Colors.indigo.shade700),
              context.contentSectionContainer(
                """final asyncPrefs = SharedPreferencesAsync();

// DELETE a single key:
await asyncPrefs.remove('externalCounter');

// WIPE specific keys using allowList (recommended over clearing everything):
await asyncPrefs.clear(allowList: <String>{'counter', 'theme'});
// Only 'counter' and 'theme' are deleted — other keys are preserved!

// WIPE everything (no allowList = nuclear option):
await asyncPrefs.clear();
// ⚠️ Calling clear() without allowList removes ALL keys in the store.""",
              ),
              context.contentText("SharedPreferencesWithCache — remove() & clear()", Colors.teal.shade700),
              context.contentSectionContainer(
                """final prefsWithCache = await SharedPreferencesWithCache.create(
  cacheOptions: const SharedPreferencesWithCacheOptions(
    allowList: <String>{'counter', 'theme'},
  ),
);

// DELETE a single key (removes from both memory cache AND disk):
await prefsWithCache.remove('counter');
// Synchronous read after remove returns null:
final val = prefsWithCache.getInt('counter'); // null

// WIPE all keys in the allowList:
await prefsWithCache.clear();
// Only keys declared in the allowList can be cleared.
// Keys outside the allowList are NOT touched by this instance.""",
              ),
              context.theoryContentText(
                "⚡ Key Insight: SharedPreferencesWithCache ONLY manages keys in its allowList. "
                "Calling clear() on one instance does NOT delete keys belonging to other "
                "WithCache instances or AsyncPrefs — each instance has its own scope.",
              ),
              context.dividerSpace(20),

              // ── Subsection 7: Error Handling ──────────────────────────────
              context.headTitle("7. Error Handling", colorScheme.secondary),
              const SizedBox(height: 12),
              context.contentText("Common pitfalls and how to handle them", Colors.red.shade700),
              context.contentSectionContainer(
                """// ── PITFALL 1: Reading a key with the WRONG type ─────────────────────
// If you store an int but read it as a String, SharedPreferences returns null
// (not a crash). Always use the correct getter.
final SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.setInt('counter', 42);

final String? wrong = prefs.getString('counter'); // Returns NULL (no crash!)
final int? correct = prefs.getInt('counter');      // Returns 42 ✓

// ── PITFALL 2: null return without a default value ─────────────────────
// get methods return null if the key doesn't exist. ALWAYS provide a default!
final int count = prefs.getInt('counter') ?? 0;  // ✓ Safe
// final int count = prefs.getInt('counter')!;   // ❌ Nullable crash risk!

// ── PITFALL 3: Using SharedPreferencesWithCache before initialization ──
// SharedPreferencesWithCache.create() is async — MUST await before reading.
try {
  final cache = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: <String>{'theme'},
    ),
  );
  final theme = cache.getString('theme') ?? 'light'; // ✓
} catch (e) {
  // Handles any platform-level initialization failure
  debugPrint('SharedPreferences init failed: \$e');
}

// ── PITFALL 4: Storing LARGE data ─────────────────────────────────────
// SharedPreferences is backed by XML/plist — NOT designed for large data.
// Storing lists of 1000+ items, images, or complex JSON will cause:
//   • Slow app startup (the entire XML is read at boot)
//   • Memory bloat (all values loaded into RAM at once)
// ✅ Rule: Keep each value < 1KB. For complex data → use Hive or SQLite.""",
              ),
              context.theoryContentText(
                "✅ Best Practice: Wrap SharedPreferences calls in try/catch only at the "
                "initialization layer (init()). Individual get/set operations on an already-initialized "
                "instance are extremely unlikely to throw — but always null-check the return values.",
              ),
              context.dividerSpace(20),

              // ── Subsection 8: Comparison Table ────────────────────────────
              context.headTitle("8. API Comparison", colorScheme.secondary),
              const SizedBox(height: 12),
              _ComparisonTable(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPARISON TABLE WIDGET (SharedPreferences APIs + cross-DB comparison)
// ─────────────────────────────────────────────────────────────────────────────

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Part A: The 3 SharedPreferences APIs ──────────────────────────
        Text(
          'The Three SharedPreferences APIs',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        const SizedBox(height: 8),
        _buildApiTable(context),
        const SizedBox(height: 20),
        // ── Part B: SharedPreferences vs Other Databases ──────────────────
        Text(
          'SharedPreferences vs Other Databases',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        const SizedBox(height: 8),
        _buildCrossDbTable(context),
      ],
    );
  }

  Widget _buildApiTable(BuildContext context) {
    final headers = ['Feature', 'Legacy', 'Async', 'WithCache'];
    final headerColors = [Colors.grey.shade700, Colors.blue.shade700, Colors.indigo.shade700, Colors.teal.shade700];
    final rows = [
      ['Read type', 'Sync ✅', 'Async ⏳', 'Sync ✅'],
      ['Write type', 'Async ⏳', 'Async ⏳', 'Async ⏳'],
      ['Memory cache', 'Yes (all)', 'None', 'Yes (scoped)'],
      ['Cache staleness risk', 'High ⚠️', 'None ✅', 'Low ✅'],
      ['Background isolate safe', 'No ❌', 'Yes ✅', 'No ❌'],
      ['Key scoping', 'None', 'None', 'allowList ✅'],
      ['Best for', 'Migration', 'Multi-process', 'UI prefs'],
    ];
    return _buildTable(context, headers, headerColors, rows);
  }

  Widget _buildCrossDbTable(BuildContext context) {
    final headers = ['Property', 'SharedPrefs', 'Hive', 'SQLite', 'Isar'];
    final headerColors = [Colors.grey.shade700, Colors.blue.shade700, Colors.orange.shade700, Colors.teal.shade700, Colors.deepOrange.shade700];
    final rows = [
      ['Data model', 'Key-Value', 'Key-Value', 'Relational', 'NoSQL ORM'],
      ['Schema', 'None', 'None/TypeAdap', 'SQL DDL', 'Dart class'],
      ['Complex queries', 'No ❌', 'No ❌', 'Yes ✅', 'Yes ✅'],
      ['Reactive streams', 'No ❌', 'Listen ⚠️', 'No ❌', 'Yes ✅'],
      ['Encryption', 'No ❌', 'AES opt. ✅', 'SQLCipher', 'No ❌'],
      ['Setup complexity', 'Zero 🟢', 'Low 🟢', 'Medium 🟡', 'High 🔴'],
      ['Best use case', 'App flags', 'Offline cache', 'Relational', 'Large NoSQL'],
    ];
    return _buildTable(context, headers, headerColors, rows);
  }

  Widget _buildTable(BuildContext context, List<String> headers, List<Color> headerColors, List<List<String>> rows) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row
              Container(
                color: Colors.blue.shade50,
                child: Row(
                  children: headers.asMap().entries.map((e) {
                    return _cell(
                      e.value,
                      isHeader: true,
                      color: headerColors[e.key],
                      isFirst: e.key == 0,
                    );
                  }).toList(),
                ),
              ),
              // Data rows
              ...rows.asMap().entries.map((rowEntry) {
                return Container(
                  color: rowEntry.key.isEven ? Colors.grey.shade50 : Colors.white,
                  child: Row(
                    children: rowEntry.value.asMap().entries.map((cellEntry) {
                      return _cell(
                        cellEntry.value,
                        isHeader: false,
                        color: cellEntry.key == 0 ? Colors.grey.shade700 : Colors.grey.shade800,
                        isFirst: cellEntry.key == 0,
                      );
                    }).toList(),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(String text, {required bool isHeader, required Color color, required bool isFirst}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      constraints: const BoxConstraints(minWidth: 80),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.blue.shade100, width: 0.8),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isHeader || isFirst ? FontWeight.bold : FontWeight.normal,
          color: color,
          fontFamily: isHeader ? null : 'monospace',
        ),
        textAlign: isFirst ? TextAlign.left : TextAlign.center,
      ),
    );
  }
}
