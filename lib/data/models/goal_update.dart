/// Goal Update model for tracking progress changes
class GoalUpdate {
  final String id;
  final String goalId;
  final double value;
  final String? note;
  final String source;
  final DateTime createdAt;

  const GoalUpdate({
    required this.id,
    required this.goalId,
    required this.value,
    this.note,
    required this.source,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'goal_id': goalId,
        'value': value,
        'note': note,
        'source': source,
        'created_at': createdAt.toIso8601String(),
      };

  factory GoalUpdate.fromJson(Map<String, dynamic> json) {
    return GoalUpdate(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      value: (json['value'] as num).toDouble(),
      note: json['note'] as String?,
      source: json['source'] as String? ?? 'manual',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
