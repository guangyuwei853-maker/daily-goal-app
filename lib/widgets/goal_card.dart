import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../screens/goal/goal_detail_screen.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  const GoalCard({
    super.key,
    required this.goal,
    required this.onToggleComplete,
    required this.onDelete,
  });

  static const Map<String, Color> priorityColors = {
    'high': Color(0xFFFF6B6B),
    'medium': Color(0xFFFFD93D),
    'low': Color(0xFF6BCB77),
  };

  static const Map<String, String> categoryIcons = {
    'work': '\u{1F4BC}',
    'study': '\u{1F4DA}',
    'fitness': '\u{1F4AA}',
    'life': '\u{1F3E0}',
    'other': '\u{2B50}',
  };

  bool get isCompleted => goal.status == 'completed';

  @override
  Widget build(BuildContext context) {
    final borderColor = priorityColors[goal.priority] ?? priorityColors['medium']!;

    return Dismissible(
      key: Key('goal_${goal.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GoalDetailScreen(goal: goal),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isCompleted ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: borderColor, width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: onToggleComplete,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? borderColor : Colors.transparent,
                      border: Border.all(
                        color: isCompleted ? borderColor : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Center content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? Colors.grey : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (goal.startTime != null &&
                              goal.endTime != null) ...[
                            Icon(Icons.access_time,
                                size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              '${goal.startTime}-${goal.endTime}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: borderColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${categoryIcons[goal.category] ?? ''} ${_categoryLabel(goal.category)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: borderColor.computeLuminance() > 0.5
                                    ? Colors.black87
                                    : borderColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'work':
        return '工作';
      case 'study':
        return '学习';
      case 'fitness':
        return '健身';
      case 'life':
        return '生活';
      default:
        return '其他';
    }
  }
}
