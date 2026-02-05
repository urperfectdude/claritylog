import 'dart:async';
import 'package:hive/hive.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/app_utils.dart';
import '../data/models/models.dart';

/// Service for managing offline sync queue
class SyncService {
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();

  SyncService._();

  Timer? _syncTimer;
  bool _isSyncing = false;

  Box get _syncBox => HiveConfig.syncQueueBox;

  /// Initialize sync service and start periodic sync
  void init() {
    _syncTimer = Timer.periodic(
      AppConstants.syncInterval,
      (_) => syncPendingItems(),
    );

    // Also sync when connectivity changes
    NetworkUtils.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        syncPendingItems();
      }
    });
  }

  /// Dispose sync service
  void dispose() {
    _syncTimer?.cancel();
  }

  /// Add item to sync queue
  Future<void> addToQueue(SyncItem item) async {
    await _syncBox.put(item.id, item.toJson());
  }

  /// Get all pending sync items
  List<SyncItem> getPendingItems() {
    return _syncBox.values
        .map((e) => SyncItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((item) => !item.maxRetriesExceeded)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Get count of pending items
  int get pendingCount => _syncBox.length;

  /// Sync all pending items
  Future<void> syncPendingItems() async {
    if (_isSyncing) return;

    final isOnline = await NetworkUtils.isOnline;
    if (!isOnline) return;

    _isSyncing = true;

    try {
      final items = getPendingItems();

      for (final item in items) {
        try {
          await _syncItem(item);
          await _syncBox.delete(item.id);
        } catch (e) {
          // Increment retry count
          final updatedItem = item.copyWith(
            retryCount: item.retryCount + 1,
            lastError: e.toString(),
          );
          await _syncBox.put(item.id, updatedItem.toJson());
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single item to Supabase
  Future<void> _syncItem(SyncItem item) async {
    final supabase = SupabaseConfig.client;
    final table = item.tableName;

    switch (item.operationEnum) {
      case SyncOperation.create:
        await supabase.from(table).insert(item.data);
        break;

      case SyncOperation.update:
        await supabase.from(table).update(item.data).eq('id', item.entityId);
        break;

      case SyncOperation.delete:
        await supabase.from(table).delete().eq('id', item.entityId);
        break;
    }
  }

  /// Force sync now
  Future<void> forceSync() async {
    await syncPendingItems();
  }

  /// Clear all pending items (use with caution)
  Future<void> clearQueue() async {
    await _syncBox.clear();
  }
}
