class SubTask {
  final int? id;
  final int goalId;
  final String title;
  final bool isCompleted;
  final int orderNum;

  SubTask({
    this.id,
    required this.goalId,
    required this.title,
    this.isCompleted = false,
    required this.orderNum,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
      'order_num': orderNum,
    };
  }

  factory SubTask.fromMap(Map<String, dynamic> map) {
    return SubTask(
      id: map['id'] as int?,
      goalId: map['goal_id'] as int,
      title: map['title'] as String,
      isCompleted: (map['is_completed'] as int) == 1,
      orderNum: map['order_num'] as int,
    );
  }
}
