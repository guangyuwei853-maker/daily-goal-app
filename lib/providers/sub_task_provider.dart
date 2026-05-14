import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/sub_task.dart';
import '../models/goal.dart';

class SubTaskProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Map<int, List<SubTask>> _subTasks = {};

  Map<int, List<SubTask>> get subTasks => _subTasks;

  List<SubTask> getSubTasksForGoal(int goalId) {
    return _subTasks[goalId] ?? [];
  }

  Future<void> loadSubTasks(int goalId) async {
    final tasks = await _dbHelper.getSubTasksByGoalId(goalId);
    _subTasks[goalId] = tasks;
    notifyListeners();
  }

  Future<void> addSubTask(SubTask subTask) async {
    final id = await _dbHelper.insertSubTask(subTask);
    final newTask = SubTask(
      id: id,
      goalId: subTask.goalId,
      title: subTask.title,
      isCompleted: subTask.isCompleted,
      orderNum: subTask.orderNum,
    );

    if (_subTasks.containsKey(subTask.goalId)) {
      _subTasks[subTask.goalId]!.add(newTask);
    } else {
      _subTasks[subTask.goalId] = [newTask];
    }
    notifyListeners();
  }

  Future<void> toggleSubTask(SubTask subTask, {Goal? parentGoal}) async {
    final updated = SubTask(
      id: subTask.id,
      goalId: subTask.goalId,
      title: subTask.title,
      isCompleted: !subTask.isCompleted,
      orderNum: subTask.orderNum,
    );
    await _dbHelper.updateSubTask(updated);

    final tasks = _subTasks[subTask.goalId];
    if (tasks != null) {
      final index = tasks.indexWhere((t) => t.id == subTask.id);
      if (index != -1) {
        tasks[index] = updated;
      }
    }

    // Auto-mark parent goal as completed when all subtasks are done
    if (parentGoal != null && _subTasks[subTask.goalId] != null) {
      final allCompleted =
          _subTasks[subTask.goalId]!.every((t) => t.isCompleted);
      if (allCompleted && parentGoal.status != 'completed') {
        final updatedGoal = parentGoal.copyWith(status: 'completed');
        await _dbHelper.updateGoal(updatedGoal);
      }
    }

    notifyListeners();
  }

  Future<void> deleteSubTask(int id, int goalId) async {
    await _dbHelper.deleteSubTask(id);
    _subTasks[goalId]?.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
