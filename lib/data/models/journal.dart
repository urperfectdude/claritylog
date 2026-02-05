import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'journal.freezed.dart';
part 'journal.g.dart';

@freezed
@HiveType(typeId: 0)
class Journal with _$Journal {
  const factory Journal({
    @HiveField(0) required String id,
    @HiveField(1) required String userId,
    @HiveField(2) required String content,
    @HiveField(3) String? audioUrl,
    @HiveField(4) @Default('text') String entryType, // 'text' | 'voice'
    @HiveField(5) double? moodScore, // -1 to 1 sentiment
    @HiveField(6) @Default([]) List<String> keyThemes,
    @HiveField(7) int? energyLevel, // 1-10
    @HiveField(8) required DateTime createdAt,
    @HiveField(9) DateTime? updatedAt,
    @HiveField(10) @Default(false) bool isSynced,
    @HiveField(11) @Default(false) bool isDeleted,
  }) = _Journal;

  factory Journal.fromJson(Map<String, dynamic> json) => _$JournalFromJson(json);

  /// Create a new text journal
  factory Journal.text({
    required String id,
    required String userId,
    required String content,
  }) {
    return Journal(
      id: id,
      userId: userId,
      content: content,
      entryType: 'text',
      createdAt: DateTime.now(),
    );
  }

  /// Create a new voice journal
  factory Journal.voice({
    required String id,
    required String userId,
    required String content,
    required String audioUrl,
  }) {
    return Journal(
      id: id,
      userId: userId,
      content: content,
      audioUrl: audioUrl,
      entryType: 'voice',
      createdAt: DateTime.now(),
    );
  }

  /// Convert from Supabase
  factory Journal.fromSupabase(Map<String, dynamic> data) {
    return Journal(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      content: data['content'] as String,
      audioUrl: data['audio_url'] as String?,
      entryType: data['entry_type'] as String? ?? 'text',
      moodScore: (data['mood_score'] as num?)?.toDouble(),
      keyThemes: (data['key_themes'] as List<dynamic>?)?.cast<String>() ?? [],
      energyLevel: data['energy_level'] as int?,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : null,
      isSynced: true,
    );
  }
}

extension JournalExtensions on Journal {
  /// Convert to Supabase insert/update format
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'audio_url': audioUrl,
      'entry_type': entryType,
      'mood_score': moodScore,
      'key_themes': keyThemes,
      'energy_level': energyLevel,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Get mood color based on score
  String get moodEmoji {
    if (moodScore == null) return '😐';
    if (moodScore! >= 0.6) return '😄';
    if (moodScore! >= 0.2) return '🙂';
    if (moodScore! >= -0.2) return '😐';
    if (moodScore! >= -0.6) return '😔';
    return '😢';
  }

  /// Check if voice entry
  bool get isVoice => entryType == 'voice';

  /// Preview of content
  String get preview {
    final text = content.replaceAll('\n', ' ');
    return text.length > 100 ? '${text.substring(0, 100)}...' : text;
  }
}
