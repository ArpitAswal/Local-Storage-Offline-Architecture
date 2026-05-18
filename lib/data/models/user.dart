import 'package:hive/hive.dart';

// FLOW: Step 1 - Define the part file.
// This indicates to build_runner that it needs to generate 'user.g.dart'.
// The generated file will contain the actual UserAdapter class responsible
// for serializing/deserializing this class to/from binary format.
part 'user.g.dart';

// FLOW: Step 2 - Annotate the class with @HiveType.
// Every custom object class saved in Hive needs a unique typeId.
// Crucial Rule: The typeId MUST be between 0 and 223, and it must NOT conflict with other adapters.
@HiveType(typeId: 0)
class User extends HiveObject {
  // FLOW: Step 3 - Annotate each field with @HiveField.
  // Each field needs a unique index within the class.
  // Crucial Rule: Do NOT change index numbers once data is written, otherwise older data will break!
  // If you deprecate a field, keep the index reserved; do not reuse it.
  
  @HiveField(0)
  final String id; // A unique identifier (UUID or timestamp) used as the lookup key in the Box.

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String role; // Stores User roles: 'Admin', 'User', or 'Guest'.

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  // FLOW: Step 4 - Override toString for easier console logging and inspection in our sandbox console.
  @override
  String toString() => 'User(id: $id, name: $name, email: $email, role: $role)';
}
