import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../models/journal.dart';
import '../models/sync_item.dart';
import '../../services/sync_service.dart';

/// Repository for journal operations with offline-first support
class JournalRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  Box get _journalBox => Hive.box(AppConstants.journalBoxName);

  /// Get all journals for the current user
  Future<List<Journal>> getJournals({bool forceRefresh = false}) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return [];

    // Try to fetch from Supabase if online
    if (await NetworkUtils.isOnline || forceRefresh) {
      try {
        final response = await _supabase
            .from('journals')
            .select()
            .eq('user_id', userId)
            .eq('is_deleted', false)
            .order('created_at', ascending: false);

        final journals =
            (response as List).map((e) => Journal.fromSupabase(e)).toList();

        // Cache locally
        for (final journal in journals) {
          await _journalBox.put(journal.id, journal.toJson());
        }

        return journals;
      } catch (e) {
        // Fall back to local cache
      }
    }

    // Return from local cache
    return _journalBox.values
        .map((e) => Journal.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((j) => j.userId == userId && !j.isDeleted)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get a single journal by ID
  Future<Journal?> getJournal(String id) async {
    // Try local first
    final local = _journalBox.get(id);
    if (local != null) {
      return Journal.fromJson(Map<String, dynamic>.from(local as Map));
    }

    // Try remote
    if (await NetworkUtils.isOnline) {
      try {
        final response =
            await _supabase.from('journals').select().eq('id', id).single();
        return Journal.fromSupabase(response);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Create a new journal
  Future<Journal> createJournal(Journal journal) async {
    // Save locally first
    await _journalBox.put(journal.id, journal.toJson());

    if (await NetworkUtils.isOnline) {
      try {
        await _supabase.from('journals').insert(journal.toSupabase());

        // Trigger AI analysis asynchronously
        _triggerAnalysis(journal.id, journal.content);

        // Update local as synced
        final synced = journal.copyWith(isSynced: true);
        await _journalBox.put(journal.id, synced.toJson());
        return synced;
      } catch (e) {
        // Add to sync queue
        await SyncService.instance.addToQueue(
          SyncItem.create(
            entityId: journal.id,
            entityType: SyncEntityType.journal,
            data: journal.toSupabase(),
          ),
        );
      }
    } else {
      // Add to sync queue for later
      await SyncService.instance.addToQueue(
        SyncItem.create(
          entityId: journal.id,
          entityType: SyncEntityType.journal,
          data: journal.toSupabase(),
        ),
      );
    }

    return journal;
  }

  /// Update an existing journal
  Future<Journal> updateJournal(Journal journal) async {
    final updated = journal.copyWith(updatedAt: DateTime.now());
    await _journalBox.put(journal.id, updated.toJson());

    if (await NetworkUtils.isOnline) {
      try {
        await _supabase
            .from('journals')
            .update(updated.toSupabase())
            .eq('id', journal.id);

        final synced = updated.copyWith(isSynced: true);
        await _journalBox.put(journal.id, synced.toJson());
        return synced;
      } catch (e) {
        await SyncService.instance.addToQueue(
          SyncItem.update(
            entityId: journal.id,
            entityType: SyncEntityType.journal,
            data: updated.toSupabase(),
          ),
        );
      }
    } else {
      await SyncService.instance.addToQueue(
        SyncItem.update(
          entityId: journal.id,
          entityType: SyncEntityType.journal,
          data: updated.toSupabase(),
        ),
      );
    }

    return updated;
  }

  /// Delete a journal (soft delete)
  Future<void> deleteJournal(String id) async {
    final local = _journalBox.get(id);
    if (local != null) {
      final journal = Journal.fromJson(Map<String, dynamic>.from(local as Map));
      final deleted = journal.copyWith(isDeleted: true);
      await _journalBox.put(id, deleted.toJson());
    }

    if (await NetworkUtils.isOnline) {
      try {
        await _supabase
            .from('journals')
            .update({'is_deleted': true}).eq('id', id);
      } catch (e) {
        await SyncService.instance.addToQueue(
          SyncItem.update(
            entityId: id,
            entityType: SyncEntityType.journal,
            data: {'is_deleted': true},
          ),
        );
      }
    }
  }

  /// Search journals by semantic similarity
  Future<List<Journal>> searchJournals(String query) async {
    if (!await NetworkUtils.isOnline) {
      // Fallback to local text search
      return _localSearch(query);
    }

    try {
      // Generate embedding for query
      final response = await _supabase.functions.invoke(
        'generate-embedding',
        body: {'content': query},
      );

      if (response.data != null && response.data['embedding'] != null) {
        // Use semantic search
        final searchResult = await _supabase.rpc(
          'search_journals',
          params: {
            'query_embedding': response.data['embedding'],
            'match_count': 20,
            'user_id_filter': SupabaseConfig.currentUserId,
          },
        );

        return (searchResult as List)
            .map((e) => Journal.fromSupabase(e))
            .toList();
      }
    } catch (e) {
      // Fallback to local search
    }

    return _localSearch(query);
  }

  List<Journal> _localSearch(String query) {
    final lower = query.toLowerCase();
    final userId = SupabaseConfig.currentUserId;

    return _journalBox.values
        .map((e) => Journal.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((j) =>
            j.userId == userId &&
            !j.isDeleted &&
            j.content.toLowerCase().contains(lower))
        .toList();
  }

  /// Trigger AI analysis for journal
  Future<void> _triggerAnalysis(String journalId, String content) async {
    try {
      await _supabase.functions.invoke(
        'analyze-journal',
        body: {'journal_id': journalId, 'content': content},
      );

      // Generate embedding
      await _supabase.functions.invoke(
        'generate-embedding',
        body: {'journal_id': journalId, 'content': content},
      );
    } catch (e) {
      // Analysis failed, but journal was still created
    }
  }

  /// Stream of journal updates (real-time)
  Stream<List<Journal>> watchJournals() {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('journals')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data
            .where((e) => e['is_deleted'] != true)
            .map((e) => Journal.fromSupabase(e))
            .toList());
  }
}
