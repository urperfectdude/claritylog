import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'goal.freezed.dart';
part 'goal.g.dart';

@freezed
@HiveType(typeId: 1)
class Goal with _$Goal {
  const factory Goal({
    @HiveField(0) required String id,
    @HiveField(1) required String userId,
    @HiveField(2) required String title,
    @HiveField(3) String? description,
    @HiveField(4) @Default('personal') String category,
    @HiveField(5) double? targetValue,
    @HiveField(6) @Default(0) double currentValue,
    @HiveField(7) String? unit,
    @HiveField(8) DateTime? deadline,
    @HiveField(9) @Default('daily') String reminderFrequency,
    @HiveField(10) String? reminderTime, // Store as "HH:mm" string
    @HiveField(11) @Default('active') String status, // 'active', 'completed', 'paused', 'overdue'
    @HiveField(12) @Default(1) int escalationLevel, // 0-3
    @HiveField(13) DateTime? lastUpdate,
    @HiveField(14) required DateTime createdAt,
    @HiveField(15) @Default(false) bool isSynced,
    @HiveField(16) @Default(false) bool isDeleted,
    @HiveField(17) String? quietHoursStart, // "22:00"
    @HiveField(18) String? quietHoursEnd, // "08:00"
    @HiveField(19) @Default(0) int rejectedCallCount,
  }) = _Goal;

  factory Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);

  /// Create a new goal
  factory Goal.create({
    required String id,
    required String userId,
    required String title,
    String? description,
    GoalCategory category = GoalCategory.personal,
    double? targetValue,
    String? unit,
    DateTime? deadline,
    ReminderFrequency reminderFrequency = ReminderFrequency.daily,
    String? reminderTime,
    EscalationLevel escalationLevel = EscalationLevel.pushOnly,
  }) {
    return Goal(
      id: id,
      userId: userId,
      title: title,
      description: description,
      category: category.name,
      targetValue: targetValue,
      unit: unit,
      deadline: deadline,
      reminderFrequency: reminderFrequency.name,
      reminderTime: reminderTime,
      escalationLevel: escalationLevel.level,
      createdAt: DateTime.now(),
    );
  }

  /// Convert from Supabase
  factory Goal.fromSupabase(Map<String, dynamic> data) {
    return Goal(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      title: data['title'] as String,
      description: data['description'] as String?,
      category: data['category'] as String? ?? 'personal',
      targetValue: (data['target_value'] as num?)?.toDouble(),
      currentValue: (data['current_value'] as num?)?.toDouble() ?? 0,
      unit: data['unit'] as String?,
      deadline: data['deadline'] != null
          ? DateTime.parse(data['deadline'] as String)
          : null,
      reminderFrequency: data['reminder_frequency'] as String? ?? 'daily',
      reminderTime: data['reminder_time'] as String?,
      status: data['status'] as String? ?? 'active',
      escalationLevel: data['escalation_level'] as int? ?? 1,
      lastUpdate: data['last_update'] != null
          ? DateTime.parse(data['last_update'] as String)
          : null,
      createdAt: DateTime.parse(data['created_at'] as String),
      isSynced: true,
      quietHoursStart: data['quiet_hours_start'] as String?,
      quietHoursEnd: data['quiet_hours_end'] as String?,
      rejectedCallCount: data['rejected_call_count'] as int? ?? 0,
    );
  }
}

extension GoalExtensions on Goal {
  /// Convert to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'deadline': deadline?.toIso8601String(),
      'reminder_frequency': reminderFrequency,
      'reminder_time': reminderTime,
      'status': status,
      'escalation_level': escalationLevel,
      'last_update': lastUpdate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'rejected_call_count': rejectedCallCount,
    };
  }

  /// Get progress percentage
  double get progressPercent {
    if (targetValue == null || targetValue == 0) return 0;
    return (currentValue / targetValue!).clamp(0.0, 1.0);
  }

  /// Check if goal is overdue
  bool get isOverdue {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!) && status != 'completed';
  }

  /// Check if goal is completed
  bool get isCompleted => status == 'completed';

  /// Get category enum
  GoalCategory get categoryEnum {
    return GoalCategory.values.firstWhere(
      (e) => e.name == category,
      orElse: () => GoalCategory.other,
    );
  }

  /// Get escalation level enum
  EscalationLevel get escalationLevelEnum {
    return EscalationLevel.fromLevel(escalationLevel);
  }

  /// Check if within quiet hours
  bool get isQuietHours {
    if (quietHoursStart == null || quietHoursEnd == null) return false;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final startParts = quietHoursStart!.split(':');
    final endParts = quietHoursEnd!.split(':');

    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    if (startMinutes <= endMinutes) {
      // Same day range (e.g., 08:00 - 18:00)
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // Overnight range (e.g., 22:00 - 08:00)
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

  /// Should skip AI call due to rejected calls
  bool get shouldSkipAiCall => rejectedCallCount >= 3;
}

/// Goal update/progress entry
@freezed
class GoalUpdate with _$GoalUpdate {
  const factory GoalUpdate({
    required String id,
    required String goalId,
    required double value,
    String? note,
    @Default('manual') String source, // 'manual', 'ai_call', 'voice'
    required DateTime createdAt,
  }) = _GoalUpdate;

  factory GoalUpdate.fromJson(Map<String, dynamic> json) => _$GoalUpdateFromJson(json);

  factory GoalUpdate.fromSupabase(Map<String, dynamic> data) {
    return GoalUpdate(
      id: data['id'] as String,
      goalId: data['goal_id'] as String,
      value: (data['value'] as num).toDouble(),
      note: data['note'] as String?,
      source: data['source'] as String? ?? 'manual',
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }
}
