import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_profile.dart'; // Added UserProfile import
import '../../providers/auth/auth_provider.dart';
import '../../providers/journal/journal_provider.dart';
import '../../providers/goals/goals_provider.dart';
import '../../router/app_router.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final journalState = ref.watch(journalProvider);
    final goalsState = ref.watch(goalsProvider);
    final journalStats = ref.watch(journalStatsProvider);
    final goalsStats = ref.watch(goalsStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(journalProvider.notifier)
                .loadJournals(forceRefresh: true);
            await ref
                .read(goalsProvider.notifier)
                .loadGoals(forceRefresh: true);
          },
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${profile?.displayNameOrEmail ?? 'there'}',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getGreeting(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => context.go(Routes.profile),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.primary,
                              child: Text(
                                profile?.initials ?? 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingXl),

                      // Stats Cards
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Journal Streak',
                              value: '${journalStats['streakDays']}',
                              subtitle: 'days',
                              icon: Icons.local_fire_department,
                              color: AppTheme.accent,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: _StatCard(
                              title: 'Active Goals',
                              value: '${goalsStats['active']}',
                              subtitle: 'in progress',
                              icon: Icons.flag,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.edit_note,
                              label: 'New Journal',
                              onTap: () => context.go(Routes.journalCreate),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.add_task,
                              label: 'New Goal',
                              onTap: () => context.go(Routes.goalCreate),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Journals
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Journals',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go(Routes.journal),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                ),
              ),

              if (journalState.journals.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLg),
                    child: _EmptyState(
                      icon: Icons.book_outlined,
                      message: 'No journals yet. Start writing!',
                      actionLabel: 'Create Journal',
                      onAction: () => context.go(Routes.journalCreate),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= 3) return null;
                      final journal = journalState.journals[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingLg,
                          vertical: AppTheme.spacingXs,
                        ),
                        child: _JournalCard(journal: journal),
                      );
                    },
                    childCount: journalState.journals.length.clamp(0, 3),
                  ),
                ),

              // Active Goals
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Goals',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go(Routes.goals),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                ),
              ),

              if (goalsState.activeGoals.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLg),
                    child: _EmptyState(
                      icon: Icons.flag_outlined,
                      message: 'No active goals. Set one now!',
                      actionLabel: 'Create Goal',
                      onAction: () => context.go(Routes.goalCreate),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= 3) return null;
                      final goal = goalsState.activeGoals[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingLg,
                          vertical: AppTheme.spacingXs,
                        ),
                        child: _GoalCard(goal: goal),
                      );
                    },
                    childCount: goalsState.activeGoals.length.clamp(0, 3),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: _BottomNav(currentIndex: 0),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final dynamic journal;

  const _JournalCard({required this.journal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                journal.moodEmoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  _formatDate(journal.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ),
              if (journal.isVoice)
                Icon(Icons.mic, size: 16, color: AppTheme.secondary),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            journal.preview,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _GoalCard extends StatelessWidget {
  final dynamic goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                '${(goal.progressPercent * 100).toInt()}%',
                style: TextStyle(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progressPercent,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation(AppTheme.secondary),
              minHeight: 6,
            ),
          ),
          if (goal.deadline != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Due: ${_formatDeadline(goal.deadline)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: goal.isOverdue
                        ? AppTheme.error
                        : AppTheme.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDeadline(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppTheme.textSecondary),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ElevatedButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;

  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
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
                isSelected: currentIndex == 0,
                onTap: () => context.go(Routes.home),
              ),
              _NavItem(
                icon: Icons.book,
                label: 'Journal',
                isSelected: currentIndex == 1,
                onTap: () => context.go(Routes.journal),
              ),
              _NavItem(
                icon: Icons.flag,
                label: 'Goals',
                isSelected: currentIndex == 2,
                onTap: () => context.go(Routes.goals),
              ),
              _NavItem(
                icon: Icons.person,
                label: 'Profile',
                isSelected: currentIndex == 3,
                onTap: () => context.go(Routes.profile),
              ),
            ],
          ),
        ),
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
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
          ),
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
