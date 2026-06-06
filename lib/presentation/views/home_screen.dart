// =============================================================================
// home_screen.dart
// =============================================================================
// PURPOSE (View Layer — MVVM):
//   This is a pure View. It contains ZERO business logic.
//   Its only job is to present navigation options and educational context to the user.
//
// REAL-WORLD RELEVANCE:
//   In a real production app, this screen would typically be a settings/profile menu
//   or an onboarding flow selector. Here it serves as a learning map for all
//   local persistence strategies a Flutter engineer must master.
// =============================================================================

import 'package:flutter/material.dart';
import '../navigation/route_navigation.dart';
import '../../features/shared_preferences/shared_pref_screen.dart';
import '../../features/hive/hive_screen.dart';
import '../../features/isar/isar_screen.dart';
import '../../features/secure_storage/secure_storage_screen.dart';
import '../../features/drift/drift_screen.dart';
import '../../features/sqlite/sql_lite_screen.dart';
import '../../features/offline_cache/offline_cache_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ─────────────────────────────────────────────────────────────────────────
    // Step 1: Access the theme from BuildContext.
    // We never hardcode colors — we always pull from Theme to respect
    // system-wide light/dark mode and design system tokens.
    // ─────────────────────────────────────────────────────────────────────────
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Storage & Offline Architecture'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ───────────────────────────────────────────────────────────────────
          // Step 2: Hero Introduction Banner
          // This card introduces the module's purpose.
          // In a real app, this pattern is used for onboarding screens where
          // SharedPreferences stores the "hasSeenOnboarding" flag.
          // ───────────────────────────────────────────────────────────────────
          _buildHeroBanner(colorScheme),

          const SizedBox(height: 20),

          // ───────────────────────────────────────────────────────────────────
          // Step 3: Section Header — Key-Value & NoSQL
          // These techniques handle simple flags, cached objects, and
          // large unstructured datasets without writing SQL.
          // ───────────────────────────────────────────────────────────────────
          _buildSectionHeader('Part 1: Key-Value & NoSQL Storage', colorScheme),
          const SizedBox(height: 10),

          // SharedPreferences Card
          // ─────────────────────────────────────────────────────────────────
          // REAL-WORLD USE: Every production Flutter app uses SharedPreferences
          // to store lightweight, non-sensitive user state that must survive
          // app restarts: theme mode, onboarding completion flags, language
          // preference, user's last-read article index, etc.
          //
          // DB FEATURE USED: Key-Value store backed by an XML file on Android
          // (SharedPreferences API) and NSUserDefaults on iOS.
          // ─────────────────────────────────────────────────────────────────
          _buildMenuCard(
            context,
            title: 'SharedPreferences',
            subtitle: 'Key-Value pairs. Best for settings, tokens, flags.',
            icon: Icons.settings,
            dbFeature: '🔑 Key-Value | XML / NSUserDefaults',
            realWorldUse: 'Theme mode · Onboarding flag · Language preference',
            destination: const SharedPreferenceScreen(),
            featureColor: Colors.blue.shade700,
          ),

          // Hive Card
          // ─────────────────────────────────────────────────────────────────
          // REAL-WORLD USE: Hive is perfect for offline product catalogue
          // caching, shopping cart persistence, local notes, and draft storage.
          // Apps like e-commerce platforms cache the last-fetched category data
          // in Hive so users see immediate content even with no internet.
          //
          // DB FEATURE USED: NoSQL Box-based storage. Each Box is like a table.
          // Uses auto-generated TypeAdapters (via build_runner) to serialize
          // Dart objects into binary format for ultra-fast I/O.
          // ─────────────────────────────────────────────────────────────────
          _buildMenuCard(
            context,
            title: 'Hive',
            subtitle: 'Pure Dart NoSQL. Fast object caching, offline data.',
            icon: Icons.hive,
            dbFeature: '📦 NoSQL Box | Binary TypeAdapter | Pure Dart',
            realWorldUse:
                'Offline product cache · Shopping cart · Draft storage',
            destination: const HiveScreen(),
            featureColor: Colors.orange.shade700,
          ),

          // Isar Card
          // ─────────────────────────────────────────────────────────────────
          // REAL-WORLD USE: Isar is used for huge local datasets requiring
          // fast full-text search — news apps, e-commerce with 10,000+ SKUs,
          // local contact search, and fitness tracking logs with complex filters.
          // Isar's ACID transactions ensure data integrity during background sync.
          //
          // DB FEATURE USED: High-performance NoSQL with auto-generated indexes,
          // reactive Streams, full-text search, and ACID-compliant write transactions.
          // ─────────────────────────────────────────────────────────────────
          _buildMenuCard(
            context,
            title: 'Isar',
            subtitle: 'High-performance NoSQL. Huge datasets, fast queries.',
            icon: Icons.speed,
            dbFeature: '⚡ Indexed NoSQL | ACID Txn | Reactive Streams',
            realWorldUse:
                'News feed search · Huge catalogue · Fitness log filters',
            destination: const IsarScreen(),
            featureColor: Colors.deepOrange.shade700,
          ),

          // Secure Storage Card
          // ─────────────────────────────────────────────────────────────────
          // REAL-WORLD USE: flutter_secure_storage is the ONLY acceptable
          // location to store JWT tokens, OAuth refresh tokens, biometric
          // auth secrets, and API keys in a Flutter app.
          // Storing these in SharedPreferences or Hive on a rooted/jailbroken
          // device exposes them — a critical security vulnerability.
          //
          // DB FEATURE USED: AES-256 hardware encryption via Android Keystore
          // (API 23+) and iOS Keychain Services. Keys never leave the secure
          // hardware enclave.
          // ─────────────────────────────────────────────────────────────────
          _buildMenuCard(
            context,
            title: 'Secure Storage',
            subtitle: 'Hardware-encrypted. For JWT tokens & auth credentials.',
            icon: Icons.lock,
            dbFeature: '🔐 AES-256 | Android Keystore | iOS Keychain',
            realWorldUse: 'JWT token · OAuth refresh token · Biometric secret',
            destination: const SecureStorageScreen(),
            featureColor: Colors.red.shade700,
          ),

          const SizedBox(height: 24),

          // ───────────────────────────────────────────────────────────────────
          // Step 4: Section Header — SQL & Relational Storage
          // These techniques shine when data has relationships (users → orders),
          // requires complex WHERE/JOIN queries, or needs aggregate functions
          // like COUNT, SUM, GROUP BY.
          // ───────────────────────────────────────────────────────────────────
          _buildSectionHeader('Part 2: SQL & Relational Storage', colorScheme),
          const SizedBox(height: 10),

          // SQLite Card
          // ─────────────────────────────────────────────────────────────────
          // REAL-WORLD USE: SQLite via sqflite is used when data is relational —
          // e.g., an e-commerce app storing Users, Orders, and OrderItems tables
          // with foreign key relationships. Also used for search history with
          // counts, complex filter queries (price + category + rating combined).
          //
          // DB FEATURE USED: Raw SQL engine embedded in the device.
          // Supports CREATE TABLE, INSERT, SELECT with WHERE/ORDER BY/JOIN,
          // and full transaction support (BEGIN, COMMIT, ROLLBACK).
          // ─────────────────────────────────────────────────────────────────
          _buildMenuCard(
            context,
            title: 'SQLite (Raw)',
            subtitle: 'Embedded relational DB. Complex joins & indexing.',
            icon: Icons.storage,
            dbFeature: '🗄 Embedded SQL | Joins | Indexes | sqflite',
            realWorldUse:
                'Orders + Users schema · Search history · Filter queries',
            destination: const SqlLiteScreen(),
            featureColor: Colors.teal.shade700,
          ),

          // Drift Card
          // ─────────────────────────────────────────────────────────────────
          // REAL-WORLD USE: Drift is the production-grade choice over raw SQLite.
          // Used in apps like task managers, budget trackers, and order management
          // systems where you need reactive UI (StreamBuilder) that auto-updates
          // when the database changes — without calling setState() manually.
          //
          // DB FEATURE USED: Type-safe SQL wrapper built on sqflite.
          // The Dart compiler validates queries at build time.
          // DAOs (Data Access Objects) expose clean, testable query methods.
          // Reactive Streams (via watchAll()) auto-push DB changes to UI.
          // ─────────────────────────────────────────────────────────────────
          _buildMenuCard(
            context,
            title: 'Drift',
            subtitle: 'Type-safe SQLite wrapper. Reactive streams & DAOs.',
            icon: Icons.table_chart,
            dbFeature: '🌊 Type-Safe SQL | DAO | Reactive Stream | Code Gen',
            realWorldUse: 'Task manager · Budget tracker · Reactive order list',
            destination: const DriftScreen(),
            featureColor: Colors.indigo.shade700,
          ),

          const SizedBox(height: 24),

          // ───────────────────────────────────────────────────────────────────
          // Step 5: Section Header — Architecture Patterns
          // This section shows HOW to orchestrate the above storage solutions
          // inside a production-grade Repository pattern for offline-first UX.
          // ───────────────────────────────────────────────────────────────────
          _buildSectionHeader(
            'Part 3: Offline-First Architecture',
            colorScheme,
          ),
          const SizedBox(height: 10),

          // Offline-First Card
          // ─────────────────────────────────────────────────────────────────
          // REAL-WORLD USE: Every major app (Spotify, Gmail, Uber, Instagram)
          // uses an offline-first cache strategy. When you open Spotify with
          // no internet, you still see your playlists immediately.
          // The ProductRepository here demonstrates this exact pattern:
          //   1. UI requests data from Repository.
          //   2. Repository instantly yields cached Hive data.
          //   3. Repository fires an async API call in background.
          //   4. On success, updates Hive cache and yields fresh data.
          //   5. UI automatically reflects the update via a Stream.
          //
          // DB FEATURE USED: Repository Pattern + Hive as cache layer.
          // Uses Dart's async* generator with yield* for streaming updates.
          // ─────────────────────────────────────────────────────────────────
          _buildMenuCard(
            context,
            title: 'Offline-First Demo',
            subtitle: 'Repository pattern, cache-first, background sync.',
            icon: Icons.wifi_off,
            dbFeature: '🔄 Cache-First | Repository | async* Generator | Hive',
            realWorldUse:
                'Spotify playlists · Gmail inbox · Instagram feed · Uber map',
            destination: const OfflineCacheScreen(),
            featureColor: Colors.purple.shade700,
          ),

          const SizedBox(height: 24),

          // This footer card maps each storage technique to its role in a
          // real production app's data layer. This is the mental model
          // every senior Flutter engineer must internalize.
          // ───────────────────────────────────────────────────────────────────
          _buildArchitectureSummaryCard(colorScheme),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ===========================================================================
  // PRIVATE WIDGET BUILDERS
  // ===========================================================================
  // These are private helper methods (prefixed with _) following Single
  // Responsibility Principle — each builds exactly one reusable UI component.
  // ===========================================================================

  /// Builds the hero introduction banner at the top of the screen.
  ///
  /// Purpose: Sets the educational context for the entire module.
  /// Real-World Analogy: Similar to an app's onboarding welcome screen,
  /// which reads a "hasSeenOnboarding" flag from SharedPreferences.
  Widget _buildHeroBanner(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Use theme's surface variant — always respects dark/light mode
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: colorScheme.primary, size: 28),
              const SizedBox(width: 10),
              Text(
                'Local Storage Lab',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Every technique shown here is used in real production apps. '
            'Each screen demonstrates the EXACT database feature, '
            'annotated with the real-world app scenario it solves.',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          // Quick legend chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildLegendChip('🔑 Key-Value', Colors.blue.shade700),
              _buildLegendChip('📦 NoSQL Box', Colors.orange.shade700),
              _buildLegendChip('🗄 SQL', Colors.teal.shade700),
              _buildLegendChip('🔐 Encrypted', Colors.red.shade700),
              _buildLegendChip('🔄 Cache-First', Colors.purple.shade700),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a colored section header divider.
  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// Builds a navigation card for each storage technique.
  ///
  /// Parameters:
  /// - [title]         : The name of the storage technique.
  /// - [subtitle]      : A brief one-line technical description.
  /// - [icon]          : The leading icon for quick visual identification.
  /// - [dbFeature]     : The specific database feature this screen demonstrates.
  ///                     This is the key educational label.
  /// - [realWorldUse]  : Concrete real-world app scenarios where this is used.
  /// - [destination]   : The screen widget to navigate to on tap.
  /// - [featureColor]  : The accent color for the DB feature badge.
  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String dbFeature,
    required String realWorldUse,
    required Widget destination,
    required Color featureColor,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          RouteNavigation.push(context, destination);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Card Header Row ──────────────────────────────────────────
              Row(
                children: [
                  // Leading icon inside a circle avatar using theme colors
                  CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Icon(
                      icon,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title — the name of the storage technique
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Subtitle — brief technical description
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // ── DB Feature Badge ─────────────────────────────────────────
              // This label is the KEY educational element on this card.
              // It tells the developer WHICH specific database capability
              // is being demonstrated in the destination screen.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: featureColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: featureColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  dbFeature,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: featureColor,
                    fontFamily: 'monospace',
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Real-World Use Label ─────────────────────────────────────
              // Shows the concrete app scenarios this storage solution solves.
              // This bridges the gap between "learning" and "production usage."
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Real-World: $realWorldUse',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the architecture summary card shown at the bottom of the screen.
  ///
  /// This provides the final mental model: how all storage techniques
  /// plug together in a single real production app's data layer.
  /// This is the "big picture" view every senior engineer holds in their mind.
  Widget _buildArchitectureSummaryCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Real-World App Data Layer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Architecture flow table ────────────────────────────────────
          // This maps each storage role in a single production app.
          // Example app: "E-commerce Shopping App"
          _buildArchRow('🔐', 'Auth JWT Token', 'Secure Storage'),
          _buildArchRow(
            '🔑',
            'Theme / Language / Onboarding',
            'SharedPreferences',
          ),
          _buildArchRow('📦', 'Offline Product Cache', 'Hive'),
          _buildArchRow('⚡', 'Full-text Search Index', 'Isar'),
          _buildArchRow('🗄', 'Orders + Users Relations', 'SQLite / Drift'),
          _buildArchRow(
            '🔄',
            'Background API Sync Strategy',
            'Repository + Cache-First',
          ),
          const SizedBox(height: 10),
          Text(
            '👆 A production app uses ALL of these — each in the right place.',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single row in the architecture summary table.
  Widget _buildArchRow(String emoji, String usage, String technique) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(usage, style: const TextStyle(fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              technique,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a small legend chip used inside the hero banner.
  Widget _buildLegendChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
