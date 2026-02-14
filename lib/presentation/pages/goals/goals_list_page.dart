import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/goals/goals_provider.dart';
import '../../router/app_router.dart';

class GoalsListPage extends ConsumerWidget {
  const GoalsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsState = ref.watch(goalsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('My Goals'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
              Tab(text: 'All'),
            ],
          ),
        ),
        body: goalsState.isLoading && goalsState.goals.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _GoalsList(
                    goals: goalsState.activeGoals,
                    emptyMessage: 'No active goals. Create one!',
                    onCreatePressed: () => context.go(Routes.goalCreate),
                  ),
                  _GoalsList(
                    goals: goalsState.completedGoals,
                    emptyMessage: 'No completed goals yet.',
                  ),
                  _GoalsList(
                    goals: goalsState.goals,
                    emptyMessage: 'No goals yet. Create your first!',
                    onCreatePressed: () => context.go(Routes.goalCreate),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go(Routes.goalCreate),
          icon: const Icon(Icons.add),
          label: const Text('New Goal'),
          backgroundColor: AppTheme.primary,
        ),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                  icon: Icons.home,
                  label: 'Home',
                  onTap: () => context.go(Routes.home)),
              _NavItem(
                  icon: Icons.book,
                  label: 'Journal',
                  onTap: () => context.go(Routes.journal)),
              _NavItem(
                  icon: Icons.flag,
                  label: 'Goals',
                  isSelected: true,
                  onTap: () {}),
              _NavItem(
                  icon: Icons.person,
                  label: 'Profile',
                  onTap: () => context.go(Routes.profile)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalsList extends ConsumerWidget {
  final List<dynamic> goals;
  final String emptyMessage;
  final VoidCallback? onCreatePressed;

  const _GoalsList({
    required this.goals,
    required this.emptyMessage,
    this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            if (onCreatePressed != null) ...[
              const SizedBox(height: AppTheme.spacingLg),
              ElevatedButton(
                onPressed: onCreatePressed,
                child: const Text('Create Goal'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(goalsProvider.notifier).loadGoals(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          final goal = goals[index];
          return _GoalCard(goal: goal);
        },
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final dynamic goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getCategoryIcon(goal.category),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    goal.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert, color: AppTheme.textSecondary),
                  itemBuilder: (context) => [
                    if (goal.status == 'active')
                      PopupMenuItem(
                        child: const Text('Complete'),
                        onTap: () => ref
                            .read(goalsProvider.notifier)
                            .completeGoal(goal.id),
                      ),
                    PopupMenuItem(
                      child: Text(goal.status == 'paused' ? 'Resume' : 'Pause'),
                      onTap: () =>
                          ref.read(goalsProvider.notifier).togglePause(goal.id),
                    ),
                    PopupMenuItem(
                      child: const Text('Delete',
                          style: TextStyle(color: AppTheme.error)),
                      onTap: () => _confirmDelete(context, ref, goal.id),
                    ),
                  ],
                ),
              ],
            ),
            if (goal.description != null) ...[
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                goal.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppTheme.spacingMd),

            // Progress bar
            if (goal.targetValue != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: goal.progressPercent,
                            backgroundColor: AppTheme.border,
                            valueColor: AlwaysStoppedAnimation(
                              goal.isCompleted
                                  ? AppTheme.success
                                  : AppTheme.secondary,
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${goal.currentValue}/${goal.targetValue} ${goal.unit ?? ''}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Text(
                    '${(goal.progressPercent * 100).toInt()}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: goal.isCompleted
                              ? AppTheme.success
                              : AppTheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],

            // Quick progress update
            if (goal.status == 'active' && goal.targetValue != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showProgressDialog(context, ref, goal),
                      icon: const Icon(Icons.add),
                      label: const Text('Update Progress'),
                    ),
                  ),
                ],
              ),
            ],

            // Status and deadline
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(goal.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    goal.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(goal.status),
                    ),
                  ),
                ),
                const Spacer(),
                if (goal.deadline != null)
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: goal.isOverdue
                            ? AppTheme.error
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDeadline(goal.deadline),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: goal.isOverdue
                                  ? AppTheme.error
                                  : AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    final icons = {
      'personal': Icons.person,
      'health': Icons.fitness_center,
      'career': Icons.work,
      'finance': Icons.attach_money,
      'relationships': Icons.people,
      'learning': Icons.school,
      'other': Icons.star,
    };
    return Icon(icons[category] ?? Icons.flag, color: AppTheme.secondary);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppTheme.secondary;
      case 'completed':
        return AppTheme.success;
      case 'paused':
        return AppTheme.textSecondary;
      case 'overdue':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatDeadline(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.isNegative) return 'Overdue';
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 7) return '${diff.inDays} days';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(goalsProvider.notifier).deleteGoal(id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showProgressDialog(BuildContext context, WidgetRef ref, dynamic goal) {
    final controller =
        TextEditingController(text: goal.currentValue.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Progress'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Current Value',
            suffix: Text(goal.unit ?? ''),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                ref.read(goalsProvider.notifier).updateProgress(goal.id, value);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
