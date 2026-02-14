import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/journal.dart';
import '../../../data/repositories/journal_repository.dart';
import '../../../core/utils/app_utils.dart';

/// Journal state
class JournalState {
  final List<Journal> journals;
  final bool isLoading;
  final String? errorMessage;
  final Journal? selectedJournal;

  const JournalState({
    this.journals = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedJournal,
  });

  JournalState copyWith({
    List<Journal>? journals,
    bool? isLoading,
    String? errorMessage,
    Journal? selectedJournal,
  }) {
    return JournalState(
      journals: journals ?? this.journals,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedJournal: selectedJournal ?? this.selectedJournal,
    );
  }
}

/// Journal notifier
class JournalNotifier extends StateNotifier<JournalState> {
  final JournalRepository _repository;

  JournalNotifier(this._repository) : super(const JournalState()) {
    loadJournals();
  }

  /// Load all journals
  Future<void> loadJournals({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final journals = await _repository.getJournals(forceRefresh: forceRefresh);
      state = state.copyWith(journals: journals, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load journals',
      );
    }
  }

  /// Create a new text journal
  Future<Journal?> createTextJournal(String content) async {
    state = state.copyWith(isLoading: true);

    try {
      final journal = Journal.text(
        id: UuidGenerator.generate(),
        userId: SupabaseConfig.currentUserId!,
        content: content,
      );

      final created = await _repository.createJournal(journal);
      state = state.copyWith(
        journals: [created, ...state.journals],
        isLoading: false,
      );
      return created;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create journal',
      );
      return null;
    }
  }

  /// Create a voice journal
  Future<Journal?> createVoiceJournal(String content, String audioUrl) async {
    state = state.copyWith(isLoading: true);

    try {
      final journal = Journal.voice(
        id: UuidGenerator.generate(),
        userId: SupabaseConfig.currentUserId!,
        content: content,
        audioUrl: audioUrl,
      );

      final created = await _repository.createJournal(journal);
      state = state.copyWith(
        journals: [created, ...state.journals],
        isLoading: false,
      );
      return created;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create voice journal',
      );
      return null;
    }
  }

  /// Update a journal
  Future<void> updateJournal(Journal journal) async {
    try {
      final updated = await _repository.updateJournal(journal);
      final index = state.journals.indexWhere((j) => j.id == journal.id);
      if (index != -1) {
        final newList = List<Journal>.from(state.journals);
        newList[index] = updated;
        state = state.copyWith(journals: newList);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update journal');
    }
  }

  /// Delete a journal
  Future<void> deleteJournal(String id) async {
    try {
      await _repository.deleteJournal(id);
      state = state.copyWith(
        journals: state.journals.where((j) => j.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete journal');
    }
  }

  /// Search journals
  Future<void> searchJournals(String query) async {
    if (query.isEmpty) {
      await loadJournals();
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final results = await _repository.searchJournals(query);
      state = state.copyWith(journals: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Search failed',
      );
    }
  }

  /// Select a journal for viewing/editing
  void selectJournal(Journal? journal) {
    state = state.copyWith(selectedJournal: journal);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Repository provider
final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository();
});

/// Journal provider
final journalProvider = StateNotifierProvider<JournalNotifier, JournalState>((ref) {
  final repository = ref.watch(journalRepositoryProvider);
  return JournalNotifier(repository);
});

/// Recent journals provider (for home page)
final recentJournalsProvider = Provider<List<Journal>>((ref) {
  final state = ref.watch(journalProvider);
  return state.journals.take(5).toList();
});

/// Journal stats provider
final journalStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final journals = ref.watch(journalProvider).journals;
  
  if (journals.isEmpty) {
    return {
      'total': 0,
      'avgMood': 0.0,
      'avgEnergy': 0,
      'streakDays': 0,
    };
  }

  final moodScores = journals.where((j) => j.moodScore != null).map((j) => j.moodScore!);
  final energyLevels = journals.where((j) => j.energyLevel != null).map((j) => j.energyLevel!);

  return {
    'total': journals.length,
    'avgMood': moodScores.isEmpty ? 0.0 : moodScores.reduce((a, b) => a + b) / moodScores.length,
    'avgEnergy': energyLevels.isEmpty ? 0 : (energyLevels.reduce((a, b) => a + b) / energyLevels.length).round(),
    'streakDays': _calculateStreak(journals),
  };
});

int _calculateStreak(List<Journal> journals) {
  if (journals.isEmpty) return 0;

  final now = DateTime.now();
  final sorted = journals.map((j) => j.createdAt).toList()..sort((a, b) => b.compareTo(a));
  
  int streak = 0;
  DateTime checkDate = DateTime(now.year, now.month, now.day);

  for (final date in sorted) {
    final journalDate = DateTime(date.year, date.month, date.day);
    if (journalDate == checkDate || journalDate == checkDate.subtract(const Duration(days: 1))) {
      if (journalDate == checkDate) {
        streak++;
      } else if (journalDate == checkDate.subtract(const Duration(days: 1))) {
        streak++;
        checkDate = journalDate;
      }
    } else {
      break;
    }
  }

  return streak;
}
