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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}