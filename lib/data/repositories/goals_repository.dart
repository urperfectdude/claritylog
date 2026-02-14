import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../models/goal.dart';

import '../models/sync_item.dart';
import '../../services/sync_service.dart';

/// Repository for goals operations with offline-first support
class GoalsRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  Box get _goalsBox => Hive.box(AppConstants.goalsBoxName);

  /// Get all goals for the current user
  Future<List<Goal>> getGoals({bool forceRefresh = false}) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return [];

    if (await NetworkUtils.isOnline || forceRefresh) {
      try {
        final response = await _supabase
            .from('goals')
            .select()
            .eq('user_id', userId)
            .eq('is_deleted', false)
            .order('created_at', ascending: false);

        final goals =
            (response as List).map((e) => Goal.fromSupabase(e)).toList();

        // Cache locally
        for (final goal in goals) {
          await _goalsBox.put(goal.id, goal.toJson());
        }

        return goals;
      } catch (e) {
        // Fall back to local cache
      }
    }

    // Return from local cache
    return _goalsBox.values
        .map((e) => Goal.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((g) => g.userId == userId && !g.isDeleted)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get goals by status
  Future<List<Goal>> getGoalsByStatus(String status) async {
    final goals = await getGoals();
    return goals.where((g) => g.status == status).toList();
  }

  /// Get active goals count
  Future<int> getActiveGoalsCount() async {
    final goals = await getGoalsByStatus('active');
    return goals.length;
  }

  /// Create a new goal
  Future<Goal> createGoal(Goal goal) async {
    await _goalsBox.put(goal.id, goal.toJson());

    if (await NetworkUtils.isOnline) {
      try {
        await _supabase.from('goals').insert(goal.toSupabase());
        final synced = goal.copyWith(isSynced: true);
        await _goalsBox.put(goal.id, synced.toJson());
        return synced;
      } catch (e) {
        await SyncService.instance.addToQueue(
          SyncItem.create(
            entityId: goal.id,
            entityType: SyncEntityType.goal,
            data: goal.toSupabase(),
          ),
        );
      }
    } else {
      await SyncService.instance.addToQueue(
        SyncItem.create(
          entityId: goal.id,
          entityType: SyncEntityType.goal,
          data: goal.toSupabase(),
        ),
      );
    }

    return goal;
  }

  /// Update a goal
  Future<Goal> updateGoal(Goal goal) async {
    await _goalsBox.put(goal.id, goal.toJson());

    if (await NetworkUtils.isOnline) {
      try {
        await _supabase
            .from('goals')
            .update(goal.toSupabase())
            .eq('id', goal.id);
        final synced = goal.copyWith(isSynced: true);
        await _goalsBox.put(goal.id, synced.toJson());
        return synced;
      } catch (e) {
        await SyncService.instance.addToQueue(
          SyncItem.update(
            entityId: goal.id,
            entityType: SyncEntityType.goal,
            data: goal.toSupabase(),
          ),
        );
      }
    } else {
      await SyncService.instance.addToQueue(
        SyncItem.update(
          entityId: goal.id,
          entityType: SyncEntityType.goal,
          data: goal.toSupabase(),
        ),
      );
    }

    return goal;
  }

  /// Update goal progress
  Future<Goal> updateProgress(String goalId, double value,
      {String? note, String source = 'manual'}) async {
    final local = _goalsBox.get(goalId);
    if (local == null) throw Exception('Goal not found');

    final goal = Goal.fromJson(Map<String, dynamic>.from(local as Map));
    final updated = goal.copyWith(
      currentValue: value,
      lastUpdate: DateTime.now(),
      status: goal.targetValue != null && value >= goal.targetValue!
          ? 'completed'
          : goal.status,
    );

    await _goalsBox.put(goalId, updated.toJson());

    // Create goal update record
    final update = GoalUpdate(
      id: UuidGenerator.generate(),
      goalId: goalId,
      value: value,
      note: note,
      source: source,
      createdAt: DateTime.now(),
    );

    if (await NetworkUtils.isOnline) {
      try {
        await _supabase.from('goal_updates').insert(update.toJson());
        await _supabase
            .from('goals')
            .update(updated.toSupabase())
            .eq('id', goalId);
      } catch (e) {
        // Queue for later
      }
    }

    return updated;
  }

  /// Delete a goal (soft delete)
  Future<void> deleteGoal(String id) async {
    final local = _goalsBox.get(id);
    if (local != null) {
      final goal = Goal.fromJson(Map<String, dynamic>.from(local as Map));
      final deleted = goal.copyWith(isDeleted: true);
      await _goalsBox.put(id, deleted.toJson());
    }

    if (await NetworkUtils.isOnline) {
      try {
        await _supabase.from('goals').update({'is_deleted': true}).eq('id', id);
      } catch (e) {
        await SyncService.instance.addToQueue(
          SyncItem.update(
            entityId: id,
            entityType: SyncEntityType.goal,
            data: {'is_deleted': true},
          ),
        );
      }
    }
  }

  /// Get goal updates/history
  Future<List<GoalUpdate>> getGoalUpdates(String goalId) async {
    if (await NetworkUtils.isOnline) {
      try {
        final response = await _supabase
            .from('goal_updates')
            .select()
            .eq('goal_id', goalId)
            .order('created_at', ascending: false);

        return (response as List).map((e) => GoalUpdate.fromJson(e)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  /// Stream of goal updates (real-time)
  Stream<List<Goal>> watchGoals() {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('goals')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data
            .where((e) => e['is_deleted'] != true)
            .map((e) => Goal.fromSupabase(e))
            .toList());
  }
}
