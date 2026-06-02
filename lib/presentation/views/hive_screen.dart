import 'package:flutter/material.dart';
import '../navigation/route_navigation.dart';
import '../widgets/extension_widgets.dart';
import 'hive_example.dart';

/// [HiveScreen] - The educational guide view explaining
/// the NoSQL Hive database engine, boxes, adapters, and CRUD mechanics.
class HiveScreen extends StatelessWidget {
  const HiveScreen({super.key});

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
        title: const Text("Hive NoSQL Guide"),
        actions: [
          // FLOW: Step 2 - Open the interactive lab view using RouteNavigation.
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () {
                RouteNavigation.push(context, const HiveDemoView());
              },
              icon: Icon(Icons.science, size: 18, color: Colors.orange.shade700),
              label: Text(
                "Try Lab",
                style: TextStyle(
                  color: Colors.orange.shade700,
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
                "Hive: Pure Dart NoSQL Database",
                Colors.orange.shade800,
              ),
              context.dividerSpace(16),
              
              context.subHeadTitle(
                "Hive is a lightning-fast, key-value NoSQL database built entirely in Dart. "
                "Instead of tables, SQL queries, or schema configurations, Hive saves data in "
                "binary files called 'Boxes'. It caches active boxes in memory for instant reads.",
              ),
              context.dividerSpace(16),
              
              // ── Examples Section Header ────────────────────────────────────
              context.headTitle("Core Database Architecture", colorScheme.secondary),
              const SizedBox(height: 12),

              // ── Subsection 1: Hive Boxes ────────────────────────────────────
              context.contentText("1. What are Hive Boxes?", Colors.orange.shade800),
              context.contentSectionContainer("""// Initialize Hive for Flutter (binds the app path directory).
await Hive.initFlutter();

// Open a Hive box. Think of a Box as an XML file or single SQLite table.
// All keys are unique Strings, and values can be any primitives or models.
final Box settingsBox = await Hive.openBox('settings_box');

// Fetch the opened box synchronously from anywhere in your code!
final myBox = Hive.box('settings_box');"""),
              
              context.theoryContentText(
                "💡 Concept: Because Hive caches all open boxes in memory, calling Hive.box('name') "
                "instantly returns the database instance synchronously! There's no blocking asynchronous read "
                "required after initialization, leading to extremely fast interface rendering.",
              ),
              context.dividerSpace(16),

              // ── Subsection 2: Static / Primitive CRUD ───────────────────────
              context.contentText("2. CRUD on Primitive Data Types", Colors.orange.shade800),
              context.contentSectionContainer("""// Access the open box synchronously
final Box box = Hive.box('settings_box');

// CREATE & UPDATE (put: inserts new key or overwrites existing key)
await box.put('username', 'john_doe');
await box.put('themeMode', 'dark');
await box.put('appVolume', 0.85);

// READ (get: returns value or fallback default if not found)
final String user = box.get('username', defaultValue: 'Guest');
final bool isDark = box.get('isDark', defaultValue: false);

// DELETE (delete: deletes a key and its value)
await box.delete('username');

// WIPE ALL (clear: empties the box completely)
await box.clear();"""),

              context.theoryContentText(
                "💡 Primitive Types: Hive natively supports double, int, String, bool, List, Map, "
                "and Uint8List out of the box without needing custom code generators.",
              ),
              context.dividerSpace(16),

              // ── Subsection 3: Custom Data Types ─────────────────────────────
              context.contentText("3. Storing Custom Objects (TypeAdapters)", Colors.orange.shade800),
              context.contentSectionContainer("""import 'package:hive/hive.dart';

// Declare the generated helper file that will hold the binary serializer
part 'user.g.dart';

@HiveType(typeId: 0) // Assign a unique typeId (0-223)
class User extends HiveObject {
  @HiveField(0) // Assign unique indices to each property
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String role;

  User({required this.id, required this.name, required this.email, required this.role});
}"""),

              context.theoryContentText(
                "🛠️ Code Gen Tool: To generate 'user.g.dart', run this command in your project terminal:\n"
                "  flutter pub run build_runner build --delete-conflicting-outputs\n\n"
                "Then, register the adapter in main() BEFORE calling runApp:\n"
                "  Hive.registerAdapter(UserAdapter());",
              ),
              context.dividerSpace(16),

              // ── Subsection 4: Custom CRUD ──────────────────────────────────
              context.contentText("4. CRUD on Custom Objects", Colors.orange.shade800),
              context.contentSectionContainer("""// Open the strongly-typed box
final Box<User> userBox = Hive.box<User>('users_box');

// CREATE: Write a new custom object
final newUser = User(id: 'u101', name: 'Alice', email: 'alice@mail.com', role: 'Admin');
await userBox.put(newUser.id, newUser);

// READ: Fetch single object synchronously or read all objects
final User? user = userBox.get('u101');
final List<User> allUsers = userBox.values.toList();

// UPDATE: Overwrite the key with the updated object
final updatedUser = User(id: 'u101', name: 'Alice Smith', email: 'alice@mail.com', role: 'Admin');
await userBox.put(updatedUser.id, updatedUser);

// DELETE: Remove the user by key
await userBox.delete('u101');"""),

              context.theoryContentText(
                "⚡ Superpower: If your class extends HiveObject, you can call instance methods directly!\n"
                "  final user = userBox.get('u101');\n"
                "  user.name = 'Bob';\n"
                "  await user.save();   // Automatically writes updates back to the box!\n"
                "  await user.delete(); // Automatically deletes itself from the box!",
              ),
              context.dividerSpace(20),

              // ── Section 5: Setup & pubspec.yaml ───────────────────────────
              context.headTitle("5. Setup & pubspec.yaml", colorScheme.secondary),
              const SizedBox(height: 12),
              context.contentText("Add to pubspec.yaml", Colors.orange.shade800),
              context.contentSectionContainer(
                """dependencies:
  hive: ^2.2.3             # Hive runtime DB engine (pure Dart)
  hive_flutter: ^1.1.0     # Flutter helpers: Hive.initFlutter(), ValueListenableBuilder

dev_dependencies:
  build_runner: ^2.4.0     # Runs code generation for TypeAdapters
  hive_generator: ^2.0.1   # Generates *.g.dart TypeAdapter files

# After adding, run:
#   flutter pub get
#   dart run build_runner build --delete-conflicting-outputs

# PLATFORM SUPPORT:
#   ✅ Android  ✅ iOS  ✅ macOS  ✅ Windows  ✅ Linux  ✅ Web
#   Hive is pure Dart — no native binaries needed!""",
              ),
              context.contentText("Initialize Hive in main.dart", Colors.orange.shade800),
              context.contentSectionContainer(
                """// Always call Hive.initFlutter() BEFORE runApp().
// This binds Hive to the platform's document directory.
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required before any async work
  await Hive.initFlutter();                  // Sets up Hive file path automatically

  // Register adapters BEFORE opening boxes that use them:
  Hive.registerAdapter(UserAdapter()); // generated by build_runner

  runApp(const MyApp());
}""",
              ),
              context.theoryContentText(
                "💡 Why initFlutter()? On mobile, the app sandbox path changes per install. "
                "Hive.initFlutter() calls path_provider internally to resolve the correct "
                "directory without you having to configure it. On Web, it uses IndexedDB instead.",
              ),
              context.dividerSpace(20),

              // ── Section 6: LazyBox ─────────────────────────────────────
              context.headTitle("6. LazyBox — Memory-Efficient for Large Datasets", colorScheme.secondary),
              const SizedBox(height: 12),
              context.contentText("Box vs LazyBox: the critical difference", Colors.orange.shade800),
              context.contentSectionContainer(
                """// REGULAR Box: ALL values are loaded into RAM on openBox().
// Great for small datasets (< a few hundred entries).
final Box<Product> box = await Hive.openBox<Product>('products_box');
final product = box.get('p001'); // Instant synchronous read (from RAM)

// LAZY Box: ONLY the KEYS are loaded into RAM on openLazyBox().
// Values are loaded from disk ON DEMAND — asynchronously.
// Essential for large datasets (1000+ entries, images, large objects).
final LazyBox<Product> lazyBox = await Hive.openLazyBox<Product>('catalog_box');

// READ — must be async! Value is fetched from disk on first access.
final Product? product = await lazyBox.get('p001'); // async read ⏳

// All write operations are identical to a regular Box:
await lazyBox.put('p002', Product(id: 'p002', name: 'Widget'));
await lazyBox.delete('p001');
await lazyBox.clear(); // Wipes all entries""",
              ),
              context.contentText("Iterating over a LazyBox", Colors.orange.shade800),
              context.contentSectionContainer(
                """// Keys are always available synchronously (they are in RAM):
final keys = lazyBox.keys.toList(); // ['p001', 'p002', ...]

// Values must be fetched asynchronously per-key:
final List<Product> allProducts = [];
for (final key in lazyBox.keys) {
  final value = await lazyBox.get(key);
  if (value != null) allProducts.add(value);
}

// ⚠️ Do NOT use lazyBox.values — it returns an Iterable of FUTURES
// (Iterable<Future<Product?>>), not the actual values directly.
// Always iterate keys and await each .get() individually.""",
              ),
              context.theoryContentText(
                "💡 Rule of Thumb:\n"
                "  • Box    → use when dataset < 500 entries OR you read values frequently\n"
                "  • LazyBox → use when dataset > 500 entries OR values are large blobs\n"
                "  • LazyBox is great for: product catalogs, message history, media metadata\n"
                "  • Box is great for: settings, user profile, recent items, flags",
              ),
              context.dividerSpace(20),

              // ── Section 7: Encryption (AES-256) ──────────────────────────
              context.headTitle("7. AES-256 Encryption", colorScheme.secondary),
              const SizedBox(height: 12),
              context.contentText("Encrypt a Hive box with a hardware-generated key", Colors.orange.shade800),
              context.contentSectionContainer(
                """import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> openEncryptedBox() async {
  final secureStorage = const FlutterSecureStorage();

  // STEP 1: Try to get an existing AES key from secure storage.
  //         This key is stored encrypted in the OS keychain (never in plaintext).
  var encryptionKeyString = await secureStorage.read(key: 'hive_aes_key');

  if (encryptionKeyString == null) {
    // STEP 2: First launch — generate a new 256-bit (32 byte) random key.
    final key = Hive.generateSecureKey(); // Cryptographically secure random bytes
    // Encode to base64 for storage as a String
    await secureStorage.write(
      key: 'hive_aes_key',
      value: base64UrlEncode(key),
    );
    encryptionKeyString = base64UrlEncode(key);
  }

  // STEP 3: Decode the stored key back to bytes
  final encryptionKeyUint8List = base64Url.decode(encryptionKeyString);

  // STEP 4: Open the box with the AES cipher.
  //         ALL values are encrypted with AES-256-CBC before being written to disk.
  final encryptedBox = await Hive.openBox<String>(
    'secure_notes_box',
    encryptionCipher: HiveAesCipher(encryptionKeyUint8List),
  );

  // Now read/write works exactly like a regular box:
  await encryptedBox.put('pin', '1234'); // Stored encrypted on disk
  final pin = encryptedBox.get('pin');   // Decrypted on read: '1234'
}""",
              ),
              context.theoryContentText(
                "🔐 Security Architecture:\n"
                "  1. AES-256 key is generated by Hive using a CSPRNG (secure random)\n"
                "  2. Key is stored in flutter_secure_storage (Android KeyStore / iOS Keychain)\n"
                "  3. Hive encrypts every value before writing to the .hive file\n"
                "  4. Even if the .hive file is extracted from the device, it's unreadable\n\n"
                "⚠️ NEVER hardcode the encryption key in your Dart source code!\n"
                "  The key MUST be generated at runtime and stored in Secure Storage.",
              ),
              context.dividerSpace(20),

              // ── Section 8: Compaction ───────────────────────────────────
              context.headTitle("8. Compaction — Disk Space Cleanup", colorScheme.secondary),
              const SizedBox(height: 12),
              context.contentText("Why Hive files grow — and how to reclaim space", Colors.orange.shade800),
              context.contentSectionContainer(
                """// PROBLEM: Hive uses an APPEND-ONLY binary file format.
// When you call box.delete('key') or box.put('key', newValue),
// the old data is NOT immediately erased from disk.
// Instead, Hive appends a 'delete marker' or 'new value' at the end.
// Over time, deleted data accumulates as 'tombstones' → wasted disk space.

// SOLUTION: Compaction rewrites the .hive file with only live entries.
// Hive auto-compacts based on a CompactionStrategy.

// AUTO COMPACTION (default strategy): Hive uses a built-in default strategy.
// You can override it when opening the box:
final box = await Hive.openBox(
  'products_box',
  compactionStrategy: (entries, deletedEntries) {
    // This callback runs after every write.
    // Return true to trigger compaction:
    return deletedEntries > 20; // Compact when 20+ deleted entries accumulate
  },
);
// entries        = total live + deleted count
// deletedEntries = count of soft-deleted (tombstone) entries only

// MANUAL COMPACTION (explicit call):
await box.compact();
// Forces a full rewrite of the box file right now.
// Blocks briefly while rewriting — prefer auto compaction in production.""",
              ),
              context.theoryContentText(
                "🖥️ Production Strategy:\n"
                "  • For settings boxes (rarely deleted): default strategy is fine\n"
                "  • For chat/log boxes (frequently deleted): use deletedEntries > 50\n"
                "  • For offline cache boxes (bulk cleared): call compact() after clear()\n"
                "  • Compaction runs on the same isolate as writes — keep the threshold high "
                "to avoid frequent pauses",
              ),
              context.dividerSpace(20),

              // ── Section 9: Error Handling ───────────────────────────────
              context.headTitle("9. Error Handling & Schema Evolution", colorScheme.secondary),
              const SizedBox(height: 12),
              context.contentText("Corrupted boxes and schema field changes", Colors.orange.shade800),
              context.contentSectionContainer(
                """// ── ERROR 1: Corrupted Box File ───────────────────────────────
// Hive files can corrupt if the app crashes mid-write on some older devices.
// Wrap box opening in a try/catch and recover gracefully:
try {
  final box = await Hive.openBox<User>('users_box');
  _users = box.values.toList();
} catch (e) {
  // HiveError is thrown when the binary file is unreadable
  if (e is HiveError) {
    // Nuclear option: delete the corrupted file and start fresh
    await Hive.deleteBoxFromDisk('users_box');
    final box = await Hive.openBox<User>('users_box'); // Empty box
    _users = [];
    debugPrint('Hive box was corrupted and was reset: \$e');
  } else {
    rethrow;
  }
}

// ── ERROR 2: Schema Evolution (Adding / Removing Fields) ───────────
// When you add a new field to a @HiveType class:
//   ✅ SAFE: Adding a new @HiveField with a NEW index (e.g., add @HiveField(4))
//   ❌ NEVER change an existing @HiveField index — old data will corrupt!
//   ❌ NEVER remove a @HiveField index — reserve it as 'deprecated'

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String name;
  @HiveField(2) final String email;
  @HiveField(3) final String role;
  // Adding a new field later: give it index 4, not reuse 0-3!
  @HiveField(4) final String? avatar; // New optional field (nullable = safe)
  User({required this.id, required this.name, required this.email,
        required this.role, this.avatar});
}

// Old stored User objects (without @HiveField(4)) will have avatar = null.
// The TypeAdapter reads field 4 as null for old records — no crash!""",
              ),
              context.theoryContentText(
                "✅ Safe Field Evolution Rules:\n"
                "  1. Add new fields with ONLY new indexes (never reuse old indexes)\n"
                "  2. New fields must be nullable (?) or have a default value\n"
                "  3. Never remove a @HiveField decorator — mark it @Deprecated instead\n"
                "  4. Regenerate TypeAdapter with build_runner after every schema change",
              ),
              context.dividerSpace(20),

              // ── Section 10: Comparison ──────────────────────────────────
              context.headTitle("10. Hive vs Other Databases", colorScheme.secondary),
              const SizedBox(height: 12),
              _HiveComparisonTable(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HIVE COMPARISON TABLE WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _HiveComparisonTable extends StatelessWidget {
  const _HiveComparisonTable();

  static const Color _hiveColor = Color(0xFFEF6C00); // Orange 800

  @override
  Widget build(BuildContext context) {
    final headers = ['Feature', 'Hive', 'SharedPrefs', 'SQLite', 'Isar'];
    final headerColors = [
      Colors.grey.shade700,
      _hiveColor,
      Colors.blue.shade700,
      Colors.teal.shade700,
      Colors.deepOrange.shade700,
    ];
    final rows = [
      ['Data model', 'Key-Value', 'Key-Value', 'Relational SQL', 'NoSQL ORM'],
      ['Schema required', 'Optional ✅', 'None ✅', 'SQL DDL ⚠️', 'Dart class ⚠️'],
      ['Complex queries', 'No ❌', 'No ❌', 'Full SQL ✅', 'Fluent API ✅'],
      ['Reactive streams', 'ValueListenable ⚠️', 'No ❌', 'No ❌', 'watch() ✅'],
      ['AES-256 encrypt', 'Built-in ✅', 'No ❌', 'SQLCipher plugin', 'No ❌'],
      ['Code generation', 'Optional', 'None', 'None', 'Required'],
      ['LazyBox (large data)', 'Yes ✅', 'N/A', 'N/A', 'N/A'],
      ['Platform support', 'All 6 ✅', 'All 6 ✅', 'Android/iOS/Mac', 'All 6 ✅'],
      ['Best use case', 'Offline cache', 'App flags', 'Relational data', 'Fast NoSQL'],
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Colors.orange.shade50,
                child: Row(
                  children: headers.asMap().entries.map((e) => _cell(
                    e.value,
                    isHeader: true,
                    color: headerColors[e.key],
                    isFirst: e.key == 0,
                  )).toList(),
                ),
              ),
              ...rows.asMap().entries.map((rowEntry) => Container(
                color: rowEntry.key.isEven ? Colors.orange.shade50.withValues(alpha: 0.3) : Colors.white,
                child: Row(
                  children: rowEntry.value.asMap().entries.map((cellEntry) => _cell(
                    cellEntry.value,
                    isHeader: false,
                    color: cellEntry.key == 0 ? Colors.grey.shade700 : Colors.grey.shade800,
                    isFirst: cellEntry.key == 0,
                  )).toList(),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(String text, {required bool isHeader, required Color color, required bool isFirst}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      constraints: const BoxConstraints(minWidth: 85),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.orange.shade100, width: 0.8)),
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