/// [TodoItem] - The data model for our SQLite demo.
///
/// Represents a single row in the `todos` table.
///
/// SQLite types mapping:
///   id     → INTEGER PRIMARY KEY AUTOINCREMENT  (Dart: int?)
///   title  → TEXT NOT NULL                      (Dart: String)
///   isDone → INTEGER (0 or 1) — booleans are stored as int in SQLite!
///   dueDate → TEXT (ISO-8601 string) — DateTime is not a native SQLite type!
///   priority → INTEGER (1=Low, 2=Medium, 3=High)
///
/// ⚠️ IMPORTANT:
///   - SQLite has NO Boolean type → use INTEGER 0/1
///   - SQLite has NO DateTime type → store as TEXT (ISO-8601) or INTEGER (epoch ms)
///   - SQLite has NO List type → serialize to JSON string if needed
class TodoItem {
  final int? id;          // Null before INSERT (auto-assigned by SQLite)
  final String title;
  final bool isDone;
  final String? dueDate;  // Stored as ISO-8601 string: '2024-12-31'
  final int priority;     // 1=Low, 2=Medium, 3=High

  const TodoItem({
    this.id,
    required this.title,
    this.isDone = false,
    this.dueDate,
    this.priority = 1,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // toMap: Serialises this object to Map<String, Object?> for sqflite INSERT/UPDATE
  //
  // FLOW: sqflite's db.insert() and db.update() accept Map<String, Object?>
  //   where column name = key and cell value = value.
  //
  // Note: 'id' is excluded when null so SQLite can AUTOINCREMENT it.
  // Note: bool isDone → int (0/1) because SQLite has no Boolean type.
  // ──────────────────────────────────────────────────────────────────────────
  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'title': title,
      'is_done': isDone ? 1 : 0,    // bool → INTEGER (0 or 1)
      'due_date': dueDate,           // String? → TEXT or NULL
      'priority': priority,
    };
    if (id != null) map['id'] = id; // Include id only for UPDATE
    return map;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // fromMap: Deserialises a sqflite query result row back to a Dart object
  //
  // FLOW: db.query() returns List<Map<String, Object?>>
  //   Each Map is one row — key = column name, value = cell value.
  //
  // Note: INTEGER 0/1 → bool isDone via (map['is_done'] == 1)
  // ──────────────────────────────────────────────────────────────────────────
  factory TodoItem.fromMap(Map<String, Object?> map) {
    return TodoItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      isDone: (map['is_done'] as int) == 1,  // INTEGER → bool
      dueDate: map['due_date'] as String?,
      priority: (map['priority'] as int?) ?? 1,
    );
  }

  /// Returns a copy of this item with specific fields updated.
  /// This is the idiomatic way to update immutable model objects in Dart.
  TodoItem copyWith({
    int? id,
    String? title,
    bool? isDone,
    String? dueDate,
    int? priority,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
    );
  }

  /// Human-readable priority label.
  String get priorityLabel {
    switch (priority) {
      case 3: return 'High';
      case 2: return 'Medium';
      default: return 'Low';
    }
  }
}
