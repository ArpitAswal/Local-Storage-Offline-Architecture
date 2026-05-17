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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
