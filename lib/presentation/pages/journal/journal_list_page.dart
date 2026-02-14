import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/journal.dart'; // Added Journal import
import '../../providers/journal/journal_provider.dart';
import '../../router/app_router.dart';

class JournalListPage extends ConsumerWidget {
  const JournalListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalState = ref.watch(journalProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Journals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context, ref),
          ),
        ],
      ),
      body: journalState.isLoading && journalState.journals.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : journalState.journals.isEmpty
              ? _EmptyState(
                  onCreatePress: () => context.go(Routes.journalCreate),
                )
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(journalProvider.notifier)
                      .loadJournals(forceRefresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    itemCount: journalState.journals.length,
                    itemBuilder: (context, index) {
                      final journal = journalState.journals[index];
                      return _JournalListItem(
                        journal: journal,
                        onTap: () {
                          // Navigate to detail or expand inline
                        },
                        onDelete: () {
                          _confirmDelete(context, ref, journal.id);
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(Routes.journalCreate),
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
        backgroundColor: AppTheme.primary,
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  void _showSearch(BuildContext context, WidgetRef ref) {
    showSearch(
      context: context,
      delegate: _JournalSearchDelegate(ref),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Journal?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(journalProvider.notifier).deleteJournal(id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
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
                  isSelected: true,
                  onTap: () {}),
              _NavItem(
                  icon: Icons.flag,
                  label: 'Goals',
                  onTap: () => context.go(Routes.goals)),
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

class _JournalListItem extends StatelessWidget {
  final dynamic journal;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _JournalListItem({
    required this.journal,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(journal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppTheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
        color: AppTheme.surface,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(journal.moodEmoji,
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(journal.createdAt),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          if (journal.keyThemes.isNotEmpty)
                            Text(
                              journal.keyThemes.take(3).join(' • '),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    if (journal.isVoice)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mic,
                                size: 14, color: AppTheme.secondary),
                            const SizedBox(width: 4),
                            Text(
                              'Voice',
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.secondary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  journal.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (journal.energyLevel != null) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  Row(
                    children: [
                      Icon(Icons.bolt, size: 16, color: AppTheme.accent),
                      const SizedBox(width: 4),
                      Text(
                        'Energy: ${journal.energyLevel}/10',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreatePress;

  const _EmptyState({required this.onCreatePress});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 80, color: AppTheme.textSecondary),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Start Your Journey',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Create your first journal entry to begin tracking your thoughts and mood.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            ElevatedButton.icon(
              onPressed: onCreatePress,
              icon: const Icon(Icons.add),
              label: const Text('Create First Entry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  _JournalSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) return const SizedBox.shrink();

    return FutureBuilder(
      future: _search(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildList(context);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(context);
  }

  Future<void> _search() async {
    await ref.read(journalProvider.notifier).searchJournals(query);
  }

  Widget _buildList(BuildContext context) {
    final journals = ref.watch(journalProvider).journals;
    final filtered = journals
        .where((j) => j.content.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text('No results for "$query"'),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final journal = filtered[index];
        return ListTile(
          leading:
              Text(journal.moodEmoji, style: const TextStyle(fontSize: 24)),
          title: Text(journal.preview),
          subtitle: Text(_formatDate(journal.createdAt)),
          onTap: () => close(context, journal.id),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
