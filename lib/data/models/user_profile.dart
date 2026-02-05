import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
@HiveType(typeId: 2)
class UserProfile with _$UserProfile {
  const factory UserProfile({
    @HiveField(0) required String id,
    @HiveField(1) required String email,
    @HiveField(2) String? displayName,
    @HiveField(3) String? phoneNumber,
    @HiveField(4) String? avatarUrl,
    @HiveField(5) @Default('UTC') String timezone,
    
    // AI-generated insights
    @HiveField(6) String? aiPersonalitySummary,
    @HiveField(7) @Default('casual') String aiCommunicationStyle,
    @HiveField(8) String? aiProductivityPatterns,
    @HiveField(9) @Default([]) List<String> commonThemes,
    @HiveField(10) @Default([]) List<String> strengths,
    @HiveField(11) @Default([]) List<String> growthAreas,
    
    // Notification preferences
    @HiveField(12) @Default(true) bool notificationsEnabled,
    @HiveField(13) @Default(true) bool emailNotificationsEnabled,
    @HiveField(14) @Default(true) bool aiCallsEnabled,
    @HiveField(15) String? defaultQuietHoursStart, // "22:00"
    @HiveField(16) String? defaultQuietHoursEnd, // "08:00"
    
    // AI preferences
    @HiveField(17) String? preferredVoice, // ElevenLabs voice
    @HiveField(18) @Default(2) int defaultEscalationLevel,
    @HiveField(19) @Default(false) bool offlineAiEnabled,
    
    // Metadata
    @HiveField(20) required DateTime createdAt,
    @HiveField(21) DateTime? updatedAt,
    @HiveField(22) @Default(false) bool isSynced,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  /// Create new profile from auth user
  factory UserProfile.fromAuthUser({
    required String id,
    required String email,
    String? displayName,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );
  }

  /// Convert from Supabase
  factory UserProfile.fromSupabase(Map<String, dynamic> data) {
    return UserProfile(
      id: data['id'] as String,
      email: data['email'] as String? ?? '',
      displayName: data['display_name'] as String?,
      phoneNumber: data['phone_number'] as String?,
      avatarUrl: data['avatar_url'] as String?,
      timezone: data['timezone'] as String? ?? 'UTC',
      aiPersonalitySummary: data['ai_personality_summary'] as String?,
      aiCommunicationStyle: data['ai_communication_style'] as String? ?? 'casual',
      aiProductivityPatterns: data['ai_productivity_patterns'] as String?,
      commonThemes:
          (data['common_themes'] as List<dynamic>?)?.cast<String>() ?? [],
      strengths: (data['strengths'] as List<dynamic>?)?.cast<String>() ?? [],
      growthAreas:
          (data['growth_areas'] as List<dynamic>?)?.cast<String>() ?? [],
      notificationsEnabled:
          data['notifications_enabled'] as bool? ?? true,
      emailNotificationsEnabled:
          data['email_notifications_enabled'] as bool? ?? true,
      aiCallsEnabled: data['ai_calls_enabled'] as bool? ?? true,
      defaultQuietHoursStart: data['default_quiet_hours_start'] as String?,
      defaultQuietHoursEnd: data['default_quiet_hours_end'] as String?,
      preferredVoice: data['preferred_voice'] as String?,
      defaultEscalationLevel: data['default_escalation_level'] as int? ?? 2,
      offlineAiEnabled: data['offline_ai_enabled'] as bool? ?? false,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : null,
      isSynced: true,
    );
  }
}

extension UserProfileExtensions on UserProfile {
  /// Convert to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'timezone': timezone,
      'ai_personality_summary': aiPersonalitySummary,
      'ai_communication_style': aiCommunicationStyle,
      'ai_productivity_patterns': aiProductivityPatterns,
      'common_themes': commonThemes,
      'strengths': strengths,
      'growth_areas': growthAreas,
      'notifications_enabled': notificationsEnabled,
      'email_notifications_enabled': emailNotificationsEnabled,
      'ai_calls_enabled': aiCallsEnabled,
      'default_quiet_hours_start': defaultQuietHoursStart,
      'default_quiet_hours_end': defaultQuietHoursEnd,
      'preferred_voice': preferredVoice,
      'default_escalation_level': defaultEscalationLevel,
      'offline_ai_enabled': offlineAiEnabled,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Get display name or email prefix
  String get displayNameOrEmail {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    return email.split('@').first;
  }

  /// Get initials for avatar
  String get initials {
    final name = displayNameOrEmail;
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  /// Check if phone number is configured for AI calls
  bool get canReceiveAiCalls =>
      aiCallsEnabled && phoneNumber != null && phoneNumber!.isNotEmpty;
}
