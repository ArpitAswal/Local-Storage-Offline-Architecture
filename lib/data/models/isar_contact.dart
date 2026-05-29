import 'package:isar/isar.dart';

// FLOW: Step 1 - Declare the generated code part file.
// build_runner will generate 'isar_contact.g.dart' containing
// IsarContactSchema and the strongly-typed query/filter extensions.
part 'isar_contact.g.dart';

// FLOW: Step 2 - Mark the class as an Isar @collection.
// Every Isar collection class must be annotated with @collection.
// Isar generates a full schema, typed queries, and CRUD wrappers
// from this annotation — completely automatically!
@collection
class IsarContact {
  // FLOW: Step 3 - Define the auto-incremented primary key.
  // Isar.autoIncrement is a sentinel constant (-9223372036854775808)
  // that tells Isar to assign the next integer ID automatically on insert.
  // Unlike Hive, you never manage IDs by hand.
  Id id = Isar.autoIncrement;

  // FLOW: Step 4 - Add a searchable indexed String field.
  // @Index(type: IndexType.value) creates a B-tree index on 'name'.
  // This makes filter().nameEqualTo() and sortByName() queries
  // orders of magnitude faster than a full-collection scan.
  @Index(type: IndexType.value)
  String name = '';

  // FLOW: Step 5 - A plain String field (no index needed here for demo).
  // Isar stores this in the same binary record alongside id and name.
  String email = '';

  // FLOW: Step 6 - Another indexed field — supports fast equality lookups.
  @Index(type: IndexType.value)
  String role = 'User'; // Possible values: 'Admin', 'User', 'Guest'

  // FLOW: Step 7 - A DateTime field; Isar natively serializes it.
  // DateTime.now() is stored as microseconds since epoch in the binary record.
  DateTime createdAt = DateTime.now();

  // FLOW: Step 8 - Override toString for console log readability.
  @override
  String toString() =>
      'IsarContact(id: $id, name: $name, email: $email, role: $role)';
}
