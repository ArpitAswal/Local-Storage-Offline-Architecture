import 'package:flutter/material.dart';
import '../navigation/route_navigation.dart';
import '../widgets/extension_widgets.dart';
import 'isar_example.dart';

/// [IsarScreen] - The educational guide view explaining the Isar NoSQL database
/// engine: collection schema, initialization, typed CRUD, filter queries,
/// ACID transactions, and reactive Streams — all with annotated code examples.
class IsarScreen extends StatelessWidget {
  const IsarScreen({super.key});

  // Isar's deep-orange accent color used consistently throughout this screen.
  static const Color isarColor = Color(0xFFE64A19); // Deep Orange 700

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        // FLOW: Step 1 - RouteNavigation back wrapper.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => RouteNavigation.back(context),
        ),
        centerTitle: true,
        title: const Text("Isar Database Guide"),
        actions: [
          // FLOW: Step 2 - Navigate to the interactive TryLab.
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () {
                RouteNavigation.push(context, const IsarDemoView());
              },
              icon: Icon(Icons.science, size: 18, color: isarColor),
              label: Text(
                "Try Lab",
                style: TextStyle(
                  color: isarColor,
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
              // ── Hero Title ─────────────────────────────────────────────────
              context.headTitle(
                "Isar: Indexed NoSQL + ACID Transactions",
                isarColor,
              ),
              context.dividerSpace(16),

              context.subHeadTitle(
                "Isar is an extremely fast, fully async NoSQL database built for Flutter. "
                "Unlike Hive's box-based key-value storage, Isar provides "
                "auto-incremented integer IDs, typed fluent query builders, "
                "ACID-compliant write transactions, and reactive Streams — "
                "all generated at build time with zero boilerplate.",
              ),
              context.dividerSpace(16),

              // ── Section 1: Setup & Pubspec ──────────────────────────────────
              context.headTitle("1. Setup & pubspec.yaml", colorScheme.secondary),
              const SizedBox(height: 10),

              context.contentText("Add to pubspec.yaml", isarColor),
              context.contentSectionContainer(
                """isar_version: &isar_version 3.1.0+1

dependencies:
  isar: *isar_version
  isar_flutter_libs: *isar_version  # Contains native Isar core binary
  path_provider: ^2.1.2             # Needed to get app directory

dev_dependencies:
  isar_generator: *isar_version     # Code generator (runs via build_runner)
  build_runner: any""",
              ),

              context.theoryContentText(
                "💡 isar_flutter_libs ships the pre-compiled Isar Core binary "
                "(written in Rust) for each platform — Android ARM/x86, iOS, macOS, "
                "Windows, and Linux. You never need to compile it yourself. "
                "isar_generator generates the schema file and query extensions at build time.",
              ),
              context.dividerSpace(16),

              // ── Section 2: Collection Model ────────────────────────────────
              context.headTitle("2. Define a Collection Schema", colorScheme.secondary),
              const SizedBox(height: 10),

              context.contentText("Annotate your model with @collection", isarColor),
              context.contentSectionContainer(
                """import 'package:isar/isar.dart';

// Tell build_runner where to write the generated code
part 'isar_contact.g.dart';

@collection  // ← marks this class as an Isar Collection (= table)
class IsarContact {

  // Auto-increment primary key — Isar assigns the ID automatically.
  // No UUIDs, no timestamp IDs — just simple integers starting from 1.
  Id id = Isar.autoIncrement;

  // @Index creates a B-tree index for fast sorting & equality lookups
  @Index(type: IndexType.value)
  String name = '';

  String email = '';

  @Index(type: IndexType.value)
  String role = 'User'; // 'Admin' | 'User' | 'Guest'

  DateTime createdAt = DateTime.now();
}""",
              ),

              context.theoryContentText(
                "🛠️ Run code generation after defining your schema:\n"
                "  flutter pub run build_runner build --delete-conflicting-outputs\n\n"
                "This generates 'isar_contact.g.dart' which contains:\n"
                "• IsarContactSchema — the binary descriptor Isar.open() requires\n"
                "• isar.isarContacts — the typed collection accessor\n"
                "• Fluent filter builder: .filter().nameContains() etc.",
              ),
              context.dividerSpace(16),

              // ── Section 3: Initialization ─────────────────────────────────
              context.headTitle("3. Initialization", colorScheme.secondary),
              const SizedBox(height: 10),

              context.contentText("Opening the Isar database instance", isarColor),
              context.contentSectionContainer(
                """import 'package:path_provider/path_provider.dart';

// Call once at app startup (e.g., in main() or a service init())
Future<void> initIsar() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Step 1 - Get the platform's app document directory
  final dir = await getApplicationDocumentsDirectory();

  // Step 2 - Open Isar with the generated schema descriptors
  final isar = await Isar.open(
    [IsarContactSchema],  // Add more schemas here for more collections
    directory: dir.path,  // File stored as 'contacts_db.isar'
    name: 'contacts_db',  // Optional custom name for the .isar file
  );
}""",
              ),

              context.theoryContentText(
                "⚡ Key Differences vs Hive:\n"
                "• Hive.initFlutter() → Isar.open([...schemas...])\n"
                "• Hive.openBox() is embedded inside Isar.open()\n"
                "• No adapter registration needed — schemas are code-generated\n"
                "• Isar runs all I/O on a dedicated background isolate automatically",
              ),
              context.dividerSpace(16),

              // ── Section 4: CRUD Operations ─────────────────────────────────
              context.headTitle("4. CRUD Operations", colorScheme.secondary),
              const SizedBox(height: 10),

              // Create
              context.contentText("CREATE — Insert inside writeTxn()", isarColor),
              context.contentSectionContainer(
                """// ACID Rule: ALL writes must be wrapped in writeTxn().
// If any error occurs inside the callback, all changes are rolled back.

final contact = IsarContact()
  ..name = 'Alice Chen'
  ..email = 'alice@example.com'
  ..role = 'Admin'
  ..createdAt = DateTime.now();
// id = Isar.autoIncrement → Isar assigns id automatically (e.g., 1, 2, 3...)

final assignedId = await isar.writeTxn(() async {
  return await isar.isarContacts.put(contact);  // returns the assigned Id
});

print('New contact created with id: \$assignedId'); // e.g., 1""",
              ),

              // Read
              context.contentText("READ — Typed Query Builders", isarColor),
              context.contentSectionContainer(
                """// 1. Get ALL records (sorted by name via index)
final all = await isar.isarContacts.where().sortByName().findAll();

// 2. Get a SINGLE record by primary key (O(1) lookup)
final alice = await isar.isarContacts.get(1); // get by integer id

// 3. Count total records
final count = await isar.isarContacts.count();

// 4. Filter with a fluent type-safe builder
final admins = await isar.isarContacts
  .filter()
  .roleEqualTo('Admin')  // Uses the @Index on 'role'
  .sortByName()          // Sorted alphabetically
  .findAll();

// 5. Full-text partial match (case insensitive)
final results = await isar.isarContacts
  .filter()
  .nameContains('alice', caseSensitive: false)
  .findAll();""",
              ),

              // Update
              context.contentText("UPDATE — put() with existing id = overwrite", isarColor),
              context.contentSectionContainer(
                """// Fetch the existing record by its id
final contact = await isar.isarContacts.get(1);

if (contact != null) {
  // Mutate the fields
  contact.name = 'Alice Smith';
  contact.role = 'User';

  // Re-put inside writeTxn() — because the id already exists,
  // Isar treats this as an UPDATE, not an insert.
  await isar.writeTxn(() async {
    await isar.isarContacts.put(contact);
  });
}""",
              ),

              // Delete
              context.contentText("DELETE — delete() by primary key", isarColor),
              context.contentSectionContainer(
                """// Delete a single record by its auto-incremented integer id
await isar.writeTxn(() async {
  final deleted = await isar.isarContacts.delete(1); // returns bool
  print('Was deleted: \$deleted');
});

// Delete ALL records from the collection
await isar.writeTxn(() async {
  await isar.isarContacts.clear();
});""",
              ),

              context.theoryContentText(
                "🔐 ACID Transactions Explained:\n"
                "• Atomic — either ALL puts/deletes inside writeTxn succeed, or NONE do\n"
                "• Consistent — DB is never left in a corrupt half-written state\n"
                "• Isolated — concurrent reads never see partial writes\n"
                "• Durable — once writeTxn returns, data is flushed to the OS file system",
              ),
              context.dividerSpace(16),

              // ── Section 5: Reactive Streams ────────────────────────────────
              context.headTitle("5. Reactive Streams (Watchers)", colorScheme.secondary),
              const SizedBox(height: 10),

              context.contentText("Watch a query for real-time UI updates", isarColor),
              context.contentSectionContainer(
                """// Build a query you want to watch
final query = isar.isarContacts.where().sortByName().build();

// .watch(fireImmediately: true) emits:
//   1. Current results immediately on subscription
//   2. Fresh results every time a writeTxn commits a change
final stream = query.watch(fireImmediately: true);

// Use with StreamBuilder in Flutter UI
StreamBuilder<List<IsarContact>>(
  stream: stream,
  builder: (context, snapshot) {
    final contacts = snapshot.data ?? [];
    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, i) => Text(contacts[i].name),
    );
  },
);

// Shorthand using the collection accessor
final collectionStream = isar.isarContacts.watchLazy(); // emits void signals""",
              ),

              context.theoryContentText(
                "⚡ Isar Watchers vs Hive ValueListenableBuilder:\n"
                "• Hive uses ValueListenable (in-memory event only)\n"
                "• Isar's watch() is a true reactive stream backed by DB change events\n"
                "• The stream fires AFTER writeTxn commits — never mid-write\n"
                "• Works across isolates — background sync updates the UI automatically",
              ),
              context.dividerSpace(16),

              // ── Section 6: Advanced Queries ────────────────────────────────
              context.headTitle("6. Advanced Queries & Indexes", colorScheme.secondary),
              const SizedBox(height: 10),

              context.contentText("Multi-condition queries using .and() / .or()", isarColor),
              context.contentSectionContainer(
                """// Compound filter: Admins AND name starts with 'A'
final results = await isar.isarContacts
  .filter()
  .roleEqualTo('Admin')
  .and()
  .nameStartsWith('A')
  .findAll();

// OR condition: role is Admin OR Guest
final results2 = await isar.isarContacts
  .filter()
  .roleEqualTo('Admin')
  .or()
  .roleEqualTo('Guest')
  .findAll();

// Pagination: skip first 10, return next 10
final page2 = await isar.isarContacts
  .where()
  .sortByName()
  .offset(10)
  .limit(10)
  .findAll();""",
              ),

              context.contentText("Index types and when to use them", isarColor),
              context.contentSectionContainer(
                """@collection
class Article {
  Id id = Isar.autoIncrement;

  // IndexType.value — for equality (==) and sort queries  
  @Index(type: IndexType.value)
  String category = '';

  // IndexType.hash — for equality only; smaller storage, no sort
  @Index(type: IndexType.hash)
  String authorId = '';

  // IndexType.hashElements — for List fields (index each element)
  @Index(type: IndexType.hashElements)
  List<String> tags = [];

  // @Index(unique: true) — enforces uniqueness constraint (like UNIQUE SQL)
  @Index(unique: true)
  String slug = '';
}""",
              ),

              context.theoryContentText(
                "🗂️ Index Strategy Guide:\n"
                "• IndexType.value → enables sortBy, greaterThan, lessThan, between\n"
                "• IndexType.hash → only equality; 50% smaller on disk than value\n"
                "• IndexType.hashElements → for searching inside List<String> fields\n"
                "• unique: true → Isar rejects duplicates automatically\n"
                "• Composite indexes: @Index(composite: [CompositeIndex('field2')])",
              ),
              context.dividerSpace(16),

              // ── Section 7: Isar Inspector ──────────────────────────────────
              context.headTitle("7. Isar Inspector (Debug Tool)", colorScheme.secondary),
              const SizedBox(height: 10),

              context.contentText("Browse your live database from a web browser", isarColor),
              context.contentSectionContainer(
                """// The Isar Inspector launches automatically in debug mode.
// Look for this line in your Flutter debug console:
//
//   Connect to the Isar Inspector: http://localhost:8080
//
// Features of the Isar Inspector:
//   ✓ Browse all collections and records live
//   ✓ Run filter queries from the browser UI
//   ✓ Edit and delete records interactively
//   ✓ Switch between Isar instances (if you have multiple)
//
// No extra setup needed — just run in debug mode!
// Run your app with:
//   flutter run
// Then open: http://localhost:8080 in Chrome""",
              ),

              context.theoryContentText(
                "🔍 The Isar Inspector is equivalent to:\n"
                "• DB Browser for SQLite — but for Isar\n"
                "• MongoDB Compass — but embedded directly in your Flutter app\n"
                "It's one of Isar's most praised developer experience features.",
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}