import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/sub_task.dart';
import '../database/database_helper.dart';
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
  bool _isExpanded = false;
  List<SubTask> _subTasks = [];
  bool _subTasksLoaded = false;

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
    final willComplete = !_isCompleted;
    setState(() {
      _isCompleted = willComplete;
    });
    widget.onToggleComplete();

    // 主任务完成时，子任务全部跟着完成
    if (willComplete && widget.goal.id != null) {
      final db = DatabaseHelper();
      final tasks = await db.getSubTasksByGoalId(widget.goal.id!);
      for (final task in tasks) {
        if (!task.isCompleted) {
          await db.updateSubTask(SubTask(
            id: task.id,
            goalId: task.goalId,
            title: task.title,
            isCompleted: true,
            orderNum: task.orderNum,
          ));
        }
      }
      // 刷新展开区域的子任务状态
      if (_subTasksLoaded && mounted) {
        setState(() {
          _subTasks = tasks.map((t) => SubTask(
            id: t.id,
            goalId: t.goalId,
            title: t.title,
            isCompleted: true,
            orderNum: t.orderNum,
          )).toList();
        });
      }
    }
  }

  Future<void> _loadSubTasks() async {
    if (widget.goal.id == null) return;
    final db = DatabaseHelper();
    final tasks = await db.getSubTasksByGoalId(widget.goal.id!);
    if (mounted) {
      setState(() {
        _subTasks = tasks;
        _subTasksLoaded = true;
      });
    }
  }

  void _toggleExpand() {
    if (!_subTasksLoaded) {
      _loadSubTasks();
    }
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Future<void> _toggleSubTask(SubTask subTask) async {
    final db = DatabaseHelper();
    final updated = SubTask(
      id: subTask.id,
      goalId: subTask.goalId,
      title: subTask.title,
      isCompleted: !subTask.isCompleted,
      orderNum: subTask.orderNum,
    );
    await db.updateSubTask(updated);

    setState(() {
      final idx = _subTasks.indexWhere((s) => s.id == subTask.id);
      if (idx != -1) {
        _subTasks = List<SubTask>.from(_subTasks);
        _subTasks[idx] = updated;
      }
    });

    // Auto-complete parent goal if all subtasks done
    final allDone = _subTasks.every((s) => s.isCompleted);
    if (allDone && !_isCompleted && _subTasks.isNotEmpty) {
      _handleToggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = priorityColors[widget.goal.priority] ?? priorityColors['medium']!;
    final completedCount = _subTasks.where((s) => s.isCompleted).length;
    final hasSubTasks = _subTasksLoaded ? _subTasks.isNotEmpty : true;

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
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _isCompleted ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).cardColor,
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
          child: Column(
            children: [
              // Main row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Row(
                  children: [
                    // Checkbox
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
                    // Content
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: widget.goal)),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: _isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                                color: _isCompleted ? Colors.grey : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
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
                                if (_subTasksLoaded && _subTasks.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '$completedCount/${_subTasks.length}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Expand button
                    GestureDetector(
                      onTap: _toggleExpand,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.expand_more,
                            color: Colors.grey.shade500,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Sub-tasks expandable section
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: _buildSubTaskList(borderColor),
                crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
                sizeCurve: Curves.easeInOut,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubTaskList(Color borderColor) {
    if (!_subTasksLoaded) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (_subTasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(52, 0, 16, 12),
        child: Text('暂无子任务', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      );
    }

    final completedCount = _subTasks.where((s) => s.isCompleted).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.only(left: 36, bottom: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: _subTasks.isEmpty ? 0 : completedCount / _subTasks.length,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(borderColor),
                minHeight: 4,
              ),
            ),
          ),
          // Sub-task items
          ..._subTasks.map((subTask) => _buildSubTaskItem(subTask, borderColor)),
        ],
      ),
    );
  }

  Widget _buildSubTaskItem(SubTask subTask, Color borderColor) {
    return GestureDetector(
      onTap: () => _toggleSubTask(subTask),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const SizedBox(width: 36),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: subTask.isCompleted ? borderColor : Colors.transparent,
                border: Border.all(
                  color: subTask.isCompleted ? borderColor : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: subTask.isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 13, key: ValueKey('done'))
                    : const SizedBox(key: ValueKey('undone')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 14,
                  decoration: subTask.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                  color: subTask.isCompleted ? Colors.grey.shade400 : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                ),
                child: Text(subTask.title),
              ),
            ),
          ],
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
