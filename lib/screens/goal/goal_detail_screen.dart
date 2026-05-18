import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/goal.dart';
import '../../models/sub_task.dart';
import '../../providers/goal_provider.dart';
import '../../database/database_helper.dart';
import 'create_goal_screen.dart';

class GoalDetailScreen extends StatefulWidget {
  final Goal goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<SubTask> _subtasks = [];
  late Goal _goal;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  static const Map<String, Color> priorityColors = {
    'high': Color(0xFFFF6B6B),
    'medium': Color(0xFFFFD93D),
    'low': Color(0xFF6BCB77),
  };

  static const Map<String, String> priorityLabels = {
    'high': '高优先级',
    'medium': '中优先级',
    'low': '低优先级',
  };

  static const Map<String, String> categoryLabels = {
    'work': '\u{1F4BC} 工作',
    'study': '\u{1F4DA} 学习',
    'fitness': '\u{1F4AA} 健身',
    'life': '\u{1F3E0} 生活',
    'other': '\u{2B50} 其他',
  };

  static const Map<String, String> repeatLabels = {
    'daily': '每天',
    'weekdays': '工作日',
    'custom': '自定义',
  };

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _loadSubtasks();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadSubtasks() async {
    if (_goal.id != null) {
      final subtasks = await _dbHelper.getSubTasksByGoalId(_goal.id!);
      setState(() {
        _subtasks = subtasks;
      });
    }
  }

  Future<void> _toggleSubtask(SubTask subtask) async {
    final updated = SubTask(
      id: subtask.id,
      goalId: subtask.goalId,
      title: subtask.title,
      isCompleted: !subtask.isCompleted,
      orderNum: subtask.orderNum,
    );
    await _dbHelper.updateSubTask(updated);
    await _loadSubtasks();
  }

  Future<void> _toggleGoalComplete() async {
    final newStatus = _goal.status == 'completed' ? 'pending' : 'completed';

    _animController.forward().then((_) => _animController.reverse());

    setState(() {
      _goal = _goal.copyWith(status: newStatus);
    });

    final provider = context.read<GoalProvider>();
    await provider.toggleGoalComplete(widget.goal);

    // 主任务完成时，子任务全部跟着完成
    if (newStatus == 'completed' && _subtasks.isNotEmpty) {
      for (final subtask in _subtasks) {
        if (!subtask.isCompleted) {
          await _dbHelper.updateSubTask(SubTask(
            id: subtask.id,
            goalId: subtask.goalId,
            title: subtask.title,
            isCompleted: true,
            orderNum: subtask.orderNum,
          ));
        }
      }
      await _loadSubtasks();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 'completed' ? '🎉 目标已完成！' : '目标已恢复为进行中'),
          backgroundColor: newStatus == 'completed' ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _deleteGoal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个目标吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<GoalProvider>().deleteGoal(_goal.id!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _goal.status == 'completed';
    final borderColor =
        priorityColors[_goal.priority] ?? priorityColors['medium']!;
    final completedSubtasks = _subtasks.where((s) => s.isCompleted).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        title: Text(
          _goal.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black54),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateGoalScreen(
                    userId: _goal.userId,
                    existingGoal: _goal,
                  ),
                ),
              );
              // Reload after edit
              _loadSubtasks();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteGoal,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Goal info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Priority and category row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: borderColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        priorityLabels[_goal.priority] ?? '中优先级',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: borderColor.computeLuminance() > 0.5
                              ? Colors.black87
                              : borderColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        categoryLabels[_goal.category] ?? '其他',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF667eea),
                        ),
                      ),
                    ),
                    if (isCompleted) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                size: 14, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              '已完成',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                // Time range
                if (_goal.startTime != null && _goal.endTime != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          '${_goal.startTime} - ${_goal.endTime}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Repeat info
                if (_goal.isRepeat && _goal.repeatRule != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.repeat,
                            size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          '重复: ${repeatLabels[_goal.repeatRule] ?? _goal.repeatRule}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Description
          if (_goal.description != null && _goal.description!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '描述',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _goal.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Subtasks
          if (_subtasks.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '子任务',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '$completedSubtasks/${_subtasks.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _subtasks.isEmpty
                          ? 0
                          : completedSubtasks / _subtasks.length,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF667eea)),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Subtask list
                  ...List.generate(_subtasks.length, (index) {
                    final subtask = _subtasks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => _toggleSubtask(subtask),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: subtask.isCompleted
                                    ? const Color(0xFF667eea)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: subtask.isCompleted
                                      ? const Color(0xFF667eea)
                                      : Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                              child: subtask.isCompleted
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 14)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 14,
                                  decoration: subtask.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: subtask.isCompleted
                                      ? Colors.grey
                                      : Colors.black87,
                                ),
                                child: Text(subtask.title),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 24),

          // Complete / Undo button
          ScaleTransition(
            scale: _scaleAnim,
            child: isCompleted
                ? OutlinedButton.icon(
                    onPressed: _toggleGoalComplete,
                    icon: const Icon(Icons.undo),
                    label: const Text('撤销完成'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _toggleGoalComplete,
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: const Text(
                        '完成目标',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
