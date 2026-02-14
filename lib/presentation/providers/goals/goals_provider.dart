import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/goal.dart';
import '../../../data/repositories/goals_repository.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/constants/app_constants.dart';

/// Goals state
class GoalsState {
  final List<Goal> goals;
  final bool isLoading;
  final String? errorMessage;
  final Goal? selectedGoal;

  const GoalsState({
    this.goals = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedGoal,
  });

  GoalsState copyWith({
    List<Goal>? goals,
    bool? isLoading,
    String? errorMessage,
    Goal? selectedGoal,
  }) {
    return GoalsState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedGoal: selectedGoal ?? this.selectedGoal,
    );
  }

  List<Goal> get activeGoals => goals.where((g) => g.status == 'active').toList();
  List<Goal> get completedGoals => goals.where((g) => g.status == 'completed').toList();
  List<Goal> get overdueGoals => goals.where((g) => g.isOverdue).toList();
}

/// Goals notifier
class GoalsNotifier extends StateNotifier<GoalsState> {
  final GoalsRepository _repository;

  GoalsNotifier(this._repository) : super(const GoalsState()) {
    loadGoals();
  }

  /// Load all goals
  Future<void> loadGoals({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final goals = await _repository.getGoals(forceRefresh: forceRefresh);
      state = state.copyWith(goals: goals, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load goals',
      );
    }
  }

  /// Create a new goal
  Future<Goal?> createGoal({
    required String title,
    String? description,
    GoalCategory category = GoalCategory.personal,
    double? targetValue,
    String? unit,
    DateTime? deadline,
    ReminderFrequency reminderFrequency = ReminderFrequency.daily,
    String? reminderTime,
    EscalationLevel escalationLevel = EscalationLevel.pushOnly,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final goal = Goal.create(
        id: UuidGenerator.generate(),
        userId: SupabaseConfig.currentUserId!,
        title: title,
        description: description,
        category: category,
        targetValue: targetValue,
        unit: unit,
        deadline: deadline,
        reminderFrequency: reminderFrequency,
        reminderTime: reminderTime,
        escalationLevel: escalationLevel,
      );

      final created = await _repository.createGoal(goal);
      state = state.copyWith(
        goals: [created, ...state.goals],
        isLoading: false,
      );
      return created;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create goal',
      );
      return null;
    }
  }

  /// Update goal progress
  Future<void> updateProgress(String goalId, double value, {String? note}) async {
    try {
      final updated = await _repository.updateProgress(goalId, value, note: note);
      final index = state.goals.indexWhere((g) => g.id == goalId);
      if (index != -1) {
        final newList = List<Goal>.from(state.goals);
        newList[index] = updated;
        state = state.copyWith(goals: newList);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update progress');
    }
  }

  /// Update a goal
  Future<void> updateGoal(Goal goal) async {
    try {
      final updated = await _repository.updateGoal(goal);
      final index = state.goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        final newList = List<Goal>.from(state.goals);
        newList[index] = updated;
        state = state.copyWith(goals: newList);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update goal');
    }
  }

  /// Delete a goal
  Future<void> deleteGoal(String id) async {
    try {
      await _repository.deleteGoal(id);
      state = state.copyWith(
        goals: state.goals.where((g) => g.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete goal');
    }
  }

  /// Mark goal as completed
  Future<void> completeGoal(String id) async {
    final goal = state.goals.firstWhere((g) => g.id == id);
    final completed = goal.copyWith(status: 'completed');
    await updateGoal(completed);
  }

  /// Pause/unpause goal
  Future<void> togglePause(String id) async {
    final goal = state.goals.firstWhere((g) => g.id == id);
    final newStatus = goal.status == 'paused' ? 'active' : 'paused';
    final updated = goal.copyWith(status: newStatus);
    await updateGoal(updated);
  }

  /// Select a goal for viewing/editing
  void selectGoal(Goal? goal) {
    state = state.copyWith(selectedGoal: goal);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Repository provider
final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return GoalsRepository();
});

/// Goals provider
final goalsProvider = StateNotifierProvider<GoalsNotifier, GoalsState>((ref) {
  final repository = ref.watch(goalsRepositoryProvider);
  return GoalsNotifier(repository);
});

/// Active goals provider
final activeGoalsProvider = Provider<List<Goal>>((ref) {
  return ref.watch(goalsProvider).activeGoals;
});

/// Goals stats provider
final goalsStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final state = ref.watch(goalsProvider);
  
  final totalProgress = state.activeGoals.isEmpty
      ? 0.0
      : state.activeGoals.map((g) => g.progressPercent).reduce((a, b) => a + b) / state.activeGoals.length;

  return {
    'total': state.goals.length,
    'active': state.activeGoals.length,
    'completed': state.completedGoals.length,
    'overdue': state.overdueGoals.length,
    'avgProgress': totalProgress,
  };
});
