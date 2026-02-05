import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'sync_item.freezed.dart';
part 'sync_item.g.dart';

/// Types of sync operations
enum SyncOperation {
  create,
  update,
  delete,
}

/// Types of syncable entities
enum SyncEntityType {
  journal,
  goal,
  goalUpdate,
  userProfile,
}

/// Represents an item pending sync to Supabase
@freezed
@HiveType(typeId: 3)
class SyncItem with _$SyncItem {
  const factory SyncItem({
    @HiveField(0) required String id,
    @HiveField(1) required String entityId,
    @HiveField(2) required String entityType, // 'journal', 'goal', etc.
    @HiveField(3) required String operation, // 'create', 'update', 'delete'
    @HiveField(4) required Map<String, dynamic> data,
    @HiveField(5) required DateTime createdAt,
    @HiveField(6) @Default(0) int retryCount,
    @HiveField(7) String? lastError,
  }) = _SyncItem;

  factory SyncItem.fromJson(Map<String, dynamic> json) => _$SyncItemFromJson(json);

  /// Create a sync item for a new entity
  factory SyncItem.create({
    required String entityId,
    required SyncEntityType entityType,
    required Map<String, dynamic> data,
  }) {
    return SyncItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_$entityId',
      entityId: entityId,
      entityType: entityType.name,
      operation: SyncOperation.create.name,
      data: data,
      createdAt: DateTime.now(),
    );
  }

  /// Create a sync item for an updated entity
  factory SyncItem.update({
    required String entityId,
    required SyncEntityType entityType,
    required Map<String, dynamic> data,
  }) {
    return SyncItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_$entityId',
      entityId: entityId,
      entityType: entityType.name,
      operation: SyncOperation.update.name,
      data: data,
      createdAt: DateTime.now(),
    );
  }

  /// Create a sync item for a deleted entity
  factory SyncItem.delete({
    required String entityId,
    required SyncEntityType entityType,
  }) {
    return SyncItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_$entityId',
      entityId: entityId,
      entityType: entityType.name,
      operation: SyncOperation.delete.name,
      data: {},
      createdAt: DateTime.now(),
    );
  }
}

extension SyncItemExtensions on SyncItem {
  /// Get entity type enum
  SyncEntityType get entityTypeEnum {
    return SyncEntityType.values.firstWhere(
      (e) => e.name == entityType,
      orElse: () => SyncEntityType.journal,
    );
  }

  /// Get operation enum
  SyncOperation get operationEnum {
    return SyncOperation.values.firstWhere(
      (e) => e.name == operation,
      orElse: () => SyncOperation.create,
    );
  }

  /// Check if max retries exceeded
  bool get maxRetriesExceeded => retryCount >= 3;

  /// Get table name for Supabase
  String get tableName {
    switch (entityTypeEnum) {
      case SyncEntityType.journal:
        return 'journals';
      case SyncEntityType.goal:
        return 'goals';
      case SyncEntityType.goalUpdate:
        return 'goal_updates';
      case SyncEntityType.userProfile:
        return 'user_profiles';
    }
  }
}
