class Goal {
  final int? id;
  final int userId;
  final String title;
  final String? description;
  final String priority; // high, medium, low
  final String category; // work, study, fitness, life, other
  final String? startTime; // HH:mm
  final String? endTime; // HH:mm
  final bool isRepeat;
  final String? repeatRule; // daily, weekdays, custom
  final String status; // pending, completed
  final String date; // YYYY-MM-DD
  final String createdAt;

  Goal({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    this.priority = 'medium',
    this.category = 'other',
    this.startTime,
    this.endTime,
    this.isRepeat = false,
    this.repeatRule,
    this.status = 'pending',
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'priority': priority,
      'category': category,
      'start_time': startTime,
      'end_time': endTime,
      'is_repeat': isRepeat ? 1 : 0,
      'repeat_rule': repeatRule,
      'status': status,
      'date': date,
      'created_at': createdAt,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      priority: map['priority'] as String,
      category: map['category'] as String,
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      isRepeat: (map['is_repeat'] as int) == 1,
      repeatRule: map['repeat_rule'] as String?,
      status: map['status'] as String,
      date: map['date'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  Goal copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    String? priority,
    String? category,
    String? startTime,
    String? endTime,
    bool? isRepeat,
    String? repeatRule,
    String? status,
    String? date,
    String? createdAt,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isRepeat: isRepeat ?? this.isRepeat,
      repeatRule: repeatRule ?? this.repeatRule,
      status: status ?? this.status,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
