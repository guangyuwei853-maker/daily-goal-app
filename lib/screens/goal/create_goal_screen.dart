import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/goal.dart';
import '../../models/sub_task.dart';
import '../../providers/goal_provider.dart';
import '../../database/database_helper.dart';
import 'template_selector.dart';

class CreateGoalScreen extends StatefulWidget {
  final int userId;
  final Goal? existingGoal;

  const CreateGoalScreen({
    super.key,
    required this.userId,
    this.existingGoal,
  });

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String _priority = 'medium';
  String _category = 'other';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isRepeat = false;
  String _repeatRule = '不重复';
  final List<TextEditingController> _subtaskControllers = [];

  bool get isEditing => widget.existingGoal != null;

  static const Map<String, Color> priorityColors = {
    'high': Color(0xFFFF6B6B),
    'medium': Color(0xFFFFD93D),
    'low': Color(0xFF6BCB77),
  };

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _prefillForm();
    }
  }

  void _prefillForm() {
    final goal = widget.existingGoal!;
    _titleController.text = goal.title;
    _descriptionController.text = goal.description ?? '';
    _priority = goal.priority;
    _category = goal.category;
    _isRepeat = goal.isRepeat;
    _repeatRule = goal.repeatRule ?? '不重复';

    if (goal.startTime != null) {
      final parts = goal.startTime!.split(':');
      _startTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    if (goal.endTime != null) {
      final parts = goal.endTime!.split(':');
      _endTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    // Load subtasks
    _loadExistingSubtasks();
  }

  Future<void> _loadExistingSubtasks() async {
    if (widget.existingGoal?.id != null) {
      final subtasks =
          await _dbHelper.getSubTasksByGoalId(widget.existingGoal!.id!);
      setState(() {
        for (final st in subtasks) {
          _subtaskControllers.add(TextEditingController(text: st.title));
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final c in _subtaskControllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (_endTime ?? const TimeOfDay(hour: 10, minute: 0)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _addSubtask() {
    setState(() {
      _subtaskControllers.add(TextEditingController());
    });
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtaskControllers[index].dispose();
      _subtaskControllers.removeAt(index);
    });
  }

  Future<void> _openTemplateSelector() async {
    final result = await Navigator.push<TemplateSelectionResult>(
      context,
      MaterialPageRoute(
        builder: (_) => const TemplateSelectorScreen(),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        // 填充标题
        _titleController.text = result.template.name;

        // 填充分类
        final category = result.template.category;
        if (['work', 'study', 'fitness', 'life', 'other']
            .contains(category)) {
          _category = category;
        }

        // 清空已有子任务并导入模板子任务
        for (final c in _subtaskControllers) {
          c.dispose();
        }
        _subtaskControllers.clear();
        for (final task in result.selectedSubTasks) {
          _subtaskControllers.add(TextEditingController(text: task));
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已导入模板：${result.template.name}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<GoalProvider>();
    final now = DateTime.now();
    final dateStr = isEditing
        ? widget.existingGoal!.date
        : '${provider.selectedDate.year}-${provider.selectedDate.month.toString().padLeft(2, '0')}-${provider.selectedDate.day.toString().padLeft(2, '0')}';

    String? repeatRuleValue;
    if (_isRepeat) {
      switch (_repeatRule) {
        case '每天':
          repeatRuleValue = 'daily';
          break;
        case '工作日':
          repeatRuleValue = 'weekdays';
          break;
        case '自定义':
          repeatRuleValue = 'custom';
          break;
        default:
          repeatRuleValue = null;
      }
    }

    final goal = Goal(
      id: isEditing ? widget.existingGoal!.id : null,
      userId: widget.userId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      priority: _priority,
      category: _category,
      startTime: _startTime != null ? _formatTimeOfDay(_startTime!) : null,
      endTime: _endTime != null ? _formatTimeOfDay(_endTime!) : null,
      isRepeat: _isRepeat,
      repeatRule: repeatRuleValue,
      status: isEditing ? widget.existingGoal!.status : 'pending',
      date: dateStr,
      createdAt: isEditing
          ? widget.existingGoal!.createdAt
          : now.toIso8601String(),
    );

    if (isEditing) {
      await provider.updateGoal(goal);
      // Update subtasks
      if (goal.id != null) {
        final existingSubtasks = await _dbHelper.getSubTasksByGoalId(goal.id!);
        for (final st in existingSubtasks) {
          await _dbHelper.deleteSubTask(st.id!);
        }
        for (int i = 0; i < _subtaskControllers.length; i++) {
          final text = _subtaskControllers[i].text.trim();
          if (text.isNotEmpty) {
            await _dbHelper.insertSubTask(SubTask(
              goalId: goal.id!,
              title: text,
              orderNum: i,
            ));
          }
        }
      }
    } else {
      await provider.addGoal(goal);
      // Save subtasks for new goal
      // The provider's addGoal returns, and the goal now has an id in todayGoals
      final savedGoals = provider.todayGoals;
      if (savedGoals.isNotEmpty) {
        final savedGoal = savedGoals.last;
        if (savedGoal.id != null) {
          for (int i = 0; i < _subtaskControllers.length; i++) {
            final text = _subtaskControllers[i].text.trim();
            if (text.isNotEmpty) {
              await _dbHelper.insertSubTask(SubTask(
                goalId: savedGoal.id!,
                title: text,
                orderNum: i,
              ));
            }
          }
        }
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        title: Text(
          isEditing ? '编辑目标' : '新建目标',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            _buildSectionLabel('标题'),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration('输入目标标题'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入标题';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Template button
            if (!isEditing)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: OutlinedButton.icon(
                  onPressed: _openTemplateSelector,
                  icon: const Icon(Icons.auto_fix_high,
                      size: 18, color: Color(0xFF667eea)),
                  label: const Text(
                    '选择模板',
                    style: TextStyle(color: Color(0xFF667eea)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF667eea)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                ),
              ),

            // Description
            _buildSectionLabel('描述'),
            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration('输入描述（可选）'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // Time range
            _buildSectionLabel('时间段'),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            _startTime != null
                                ? _formatTimeOfDay(_startTime!)
                                : '开始时间',
                            style: TextStyle(
                              color: _startTime != null
                                  ? Colors.black87
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('~', style: TextStyle(fontSize: 18)),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            _endTime != null
                                ? _formatTimeOfDay(_endTime!)
                                : '结束时间',
                            style: TextStyle(
                              color: _endTime != null
                                  ? Colors.black87
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Priority
            _buildSectionLabel('优先级'),
            Row(
              children: [
                _buildPriorityChip('high', '高'),
                const SizedBox(width: 8),
                _buildPriorityChip('medium', '中'),
                const SizedBox(width: 8),
                _buildPriorityChip('low', '低'),
              ],
            ),
            const SizedBox(height: 20),

            // Category
            _buildSectionLabel('分类'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCategoryChip('work', '\u{1F4BC} 工作'),
                _buildCategoryChip('study', '\u{1F4DA} 学习'),
                _buildCategoryChip('fitness', '\u{1F4AA} 健身'),
                _buildCategoryChip('life', '\u{1F3E0} 生活'),
                _buildCategoryChip('other', '\u{2B50} 其他'),
              ],
            ),
            const SizedBox(height: 20),

            // Repeat
            _buildSectionLabel('重复'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('开启重复', style: TextStyle(fontSize: 15)),
                  Switch(
                    value: _isRepeat,
                    activeColor: const Color(0xFF667eea),
                    onChanged: (val) {
                      setState(() {
                        _isRepeat = val;
                        if (!val) _repeatRule = '不重复';
                      });
                    },
                  ),
                ],
              ),
            ),
            if (_isRepeat) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _repeatRule,
                    items: ['不重复', '每天', '工作日', '自定义']
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _repeatRule = val ?? '不重复';
                      });
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Subtasks
            _buildSectionLabel('子任务'),
            ..._buildSubtaskList(),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _addSubtask,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF667eea).withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Color(0xFF667eea), size: 20),
                    SizedBox(width: 4),
                    Text(
                      '添加子任务',
                      style: TextStyle(
                        color: Color(0xFF667eea),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
              ),
              child: ElevatedButton(
                onPressed: _saveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEditing ? '保存修改' : '创建目标',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF667eea)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildPriorityChip(String value, String label) {
    final isSelected = _priority == value;
    final color = priorityColors[value]!;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final isSelected = _category == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => setState(() => _category = value),
      selectedColor: const Color(0xFF667eea).withOpacity(0.15),
      checkmarkColor: const Color(0xFF667eea),
      side: BorderSide(
        color: isSelected ? const Color(0xFF667eea) : Colors.grey.shade200,
      ),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF667eea) : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  List<Widget> _buildSubtaskList() {
    return List.generate(_subtaskControllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(Icons.drag_handle, color: Colors.grey.shade400, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _subtaskControllers[index],
                decoration: _inputDecoration('子任务 ${index + 1}'),
              ),
            ),
            IconButton(
              onPressed: () => _removeSubtask(index),
              icon: Icon(Icons.close, color: Colors.grey.shade400, size: 20),
            ),
          ],
        ),
      );
    });
  }
}
