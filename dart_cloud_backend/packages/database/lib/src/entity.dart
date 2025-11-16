/// Base class for database entities
abstract class Entity {
  /// Get the table name for this entity
  String get tableName;

  /// Convert entity to a map for database operations
  Map<String, dynamic> toMap();

  /// Create entity from database row
  static T fromMap<T extends Entity>(Map<String, dynamic> map) {
    throw UnimplementedError('fromMap must be implemented by subclass');
  }
}

/// Annotation to mark a field as the primary key
class PrimaryKey {
  final bool autoIncrement;
  const PrimaryKey({this.autoIncrement = true});
}

/// Annotation to mark a field as unique
class Unique {
  const Unique();
}

/// Annotation to define a foreign key relationship
class ForeignKey {
  final String table;
  final String column;
  final String onDelete;

  const ForeignKey({
    required this.table,
    required this.column,
    this.onDelete = 'CASCADE',
  });
}

/// Annotation to define a column name (if different from field name)
class Column {
  final String name;
  const Column(this.name);
}

/// Annotation to define a one-to-many relationship
class HasMany {
  final Type entityType;
  final String foreignKey;

  const HasMany({
    required this.entityType,
    required this.foreignKey,
  });
}

/// Annotation to define a belongs-to relationship
class BelongsTo {
  final Type entityType;
  final String foreignKey;

  const BelongsTo({
    required this.entityType,
    required this.foreignKey,
  });
}

/// Annotation to define a many-to-many relationship
class ManyToMany {
  final Type entityType;
  final String pivotTable;
  final String foreignKey;
  final String relatedKey;

  const ManyToMany({
    required this.entityType,
    required this.pivotTable,
    required this.foreignKey,
    required this.relatedKey,
  });
}
