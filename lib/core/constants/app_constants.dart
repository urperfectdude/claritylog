/// App-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'ClarityLog';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String userBoxName = 'user_box';
  static const String journalBoxName = 'journal_box';
  static const String goalsBoxName = 'goals_box';
  static const String settingsBoxName = 'settings_box';
  static const String syncQueueBoxName = 'sync_queue_box';

  // Hive Type IDs
  static const int journalTypeId = 0;
  static const int goalTypeId = 1;
  static const int userProfileTypeId = 2;
  static const int syncItemTypeId = 3;

  // API Endpoints (Edge Functions)
  static const String transcribeAudioEndpoint = '/functions/v1/transcribe-audio';
  static const String analyzeJournalEndpoint = '/functions/v1/analyze-journal';
  static const String generateContentEndpoint = '/functions/v1/generate-social-content';
  static const String aiCallerEndpoint = '/functions/v1/ai-caller';

  // Default Values
  static const int maxRecordingDurationSeconds = 300; // 5 minutes
  static const int defaultEscalationLevel = 2;
  static const int maxEscalationLevel = 3;

  // Sync Settings
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxRetryAttempts = 3;
}

/// Escalation level descriptions
enum EscalationLevel {
  none(0, 'No reminders'),
  pushOnly(1, 'Push notification only'),
  pushWithReminder(2, 'Push + follow-up reminder'),
  aiCall(3, 'Push + AI phone call');

  final int level;
  final String description;

  const EscalationLevel(this.level, this.description);

  static EscalationLevel fromLevel(int level) {
    return EscalationLevel.values.firstWhere(
      (e) => e.level == level,
      orElse: () => EscalationLevel.pushOnly,
    );
  }
}

/// Goal categories
enum GoalCategory {
  health('Health & Fitness', '💪'),
  career('Career & Work', '💼'),
  personal('Personal Growth', '🌱'),
  learning('Learning & Skills', '📚'),
  finance('Finance', '💰'),
  relationships('Relationships', '❤️'),
  creativity('Creativity', '🎨'),
  other('Other', '✨');

  final String label;
  final String emoji;

  const GoalCategory(this.label, this.emoji);
}

/// Reminder frequency options
enum ReminderFrequency {
  daily('Daily'),
  weekdays('Weekdays only'),
  weekly('Weekly'),
  custom('Custom');

  final String label;

  const ReminderFrequency(this.label);
}
