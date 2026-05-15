import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../screens/goal/goal_detail_screen.dart';

class GoalCard extends StatefulWidget {
  final Goal goal;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  const GoalCard({
    super.key,
    required this.goal,
    required this.onToggleComplete,
    required this.onDelete,
  });

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _isCompleted = false;

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

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.goal.status == 'completed';
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(GoalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goal.status != widget.goal.status) {
      setState(() {
        _isCompleted = widget.goal.status == 'completed';
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleToggle() async {
    _animController.forward().then((_) => _animController.reverse());
    setState(() {
      _isCompleted = !_isCompleted;
    });
    widget.onToggleComplete();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = priorityColors[widget.goal.priority] ?? priorityColors['medium']!;

    return Dismissible(
      key: Key('goal_${widget.goal.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete(),
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
              builder: (_) => GoalDetailScreen(goal: widget.goal),
            ),
          );
        },
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _isCompleted ? Colors.grey.shade100 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(color: _isCompleted ? Colors.grey.shade400 : borderColor, width: 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isCompleted ? 0.02 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _handleToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCompleted ? borderColor : Colors.transparent,
                        border: Border.all(
                          color: _isCompleted ? borderColor : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isCompleted
                            ? const Icon(Icons.check, color: Colors.white, size: 18, key: ValueKey('check'))
                            : const SizedBox(key: ValueKey('empty')),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: _isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                            color: _isCompleted ? Colors.grey : Colors.black87,
                          ),
                          child: Text(widget.goal.title),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (widget.goal.startTime != null && widget.goal.endTime != null) ...[
                              Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.goal.startTime}-${widget.goal.endTime}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: borderColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${categoryIcons[widget.goal.category] ?? ''} ${_categoryLabel(widget.goal.category)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: borderColor.computeLuminance() > 0.5 ? Colors.black87 : borderColor,
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
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'work': return '工作';
      case 'study': return '学习';
      case 'fitness': return '健身';
      case 'life': return '生活';
      default: return '其他';
    }
  }
}
