class DailyRecord {
  final int? id;
  final int goalId;
  final String date; // YYYY-MM-DD
  final String status; // pending, completed, skipped
  final String? completedAt;

  DailyRecord({
    this.id,
    required this.goalId,
    required this.date,
    this.status = 'pending',
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'date': date,
      'status': status,
      'completed_at': completedAt,
    };
  }

  factory DailyRecord.fromMap(Map<String, dynamic> map) {
    return DailyRecord(
      id: map['id'] as int?,
      goalId: map['goal_id'] as int,
      date: map['date'] as String,
      status: map['status'] as String,
      completedAt: map['completed_at'] as String?,
    );
  }
}
