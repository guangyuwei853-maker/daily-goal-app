import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/goal.dart';
import '../models/daily_record.dart';
import '../utils/notification_service.dart';

class GoalProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Goal> _todayGoals = [];
  DateTime _selectedDate = DateTime.now();
  double _completionRate = 0.0;

  List<Goal> get todayGoals => _todayGoals;
  DateTime get selectedDate => _selectedDate;
  double get completionRate => _completionRate;

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> loadGoals(int userId, String date) async {
    // 1. 获取当天直接创建的非重复目标
    final directGoals = await _dbHelper.getGoalsByDate(userId, date);

    // 2. 获取所有重复目标，筛选出应在当天出现的
    final allRepeats = await _dbHelper.getRepeatGoals(userId);
    final todayRecords = await _dbHelper.getRecordsByDate(date);
    final recordMap = <int, DailyRecord>{};
    for (final r in todayRecords) {
      recordMap[r.goalId] = r;
    }

    final List<Goal> repeatGoalsForToday = [];
    for (final goal in allRepeats) {
      if (!_shouldRepeatOnDate(goal, date)) continue;

      // 跳过当天直接创建的（避免重复）
      if (directGoals.any((g) => g.id == goal.id)) continue;

      // 检查当天是否有完成记录
      final record = recordMap[goal.id];
      if (record != null) {
        repeatGoalsForToday.add(goal.copyWith(
          status: record.status,
          date: date,
        ));
      } else {
        // 创建当天的记录
        await _dbHelper.insertRecord(DailyRecord(
          goalId: goal.id!,
          date: date,
          status: 'pending',
        ));
        repeatGoalsForToday.add(goal.copyWith(
          status: 'pending',
          date: date,
        ));
      }
    }

    // 3. 合并：直接目标 + 重复目标
    _todayGoals = [...directGoals, ...repeatGoalsForToday];

    _scheduleNotificationsForLoadedGoals();
    _calculateCompletionRate();
    notifyListeners();
  }

  bool _shouldRepeatOnDate(Goal goal, String date) {
    if (goal.repeatRule == 'daily') return true;
    if (goal.repeatRule == 'weekdays') {
      final d = DateTime.parse(date);
      return d.weekday >= 1 && d.weekday <= 5;
    }
    return true;
  }

  Future<void> addGoal(Goal goal) async {
    final id = await _dbHelper.insertGoal(goal);
    final newGoal = goal.copyWith(id: id);
    _todayGoals = [..._todayGoals, newGoal];

    _scheduleNotificationForGoal(newGoal);

    _calculateCompletionRate();
    notifyListeners();
  }

  Future<void> updateGoal(Goal goal) async {
    await _dbHelper.updateGoal(goal);
    final index = _todayGoals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _todayGoals = List<Goal>.from(_todayGoals);
      _todayGoals[index] = goal;
    }
    _calculateCompletionRate();
    notifyListeners();
  }

  Future<void> deleteGoal(int id) async {
    await _dbHelper.deleteGoal(id);
    _todayGoals = _todayGoals.where((g) => g.id != id).toList();

    await NotificationService().cancelGoalReminder(id);

    _calculateCompletionRate();
    notifyListeners();
  }

  Future<void> toggleGoalComplete(Goal goal) async {
    final newStatus = goal.status == 'completed' ? 'pending' : 'completed';
    final updatedGoal = goal.copyWith(status: newStatus);
    await _dbHelper.updateGoal(updatedGoal);

    // 如果是重复目标，同时更新 daily_record
    if (goal.isRepeat) {
      final dateStr = goal.date;
      final records = await _dbHelper.getRecordsByDate(dateStr);
      final record = records.where((r) => r.goalId == goal.id).firstOrNull;
      if (record != null) {
        await _dbHelper.updateRecord(DailyRecord(
          id: record.id,
          goalId: goal.id!,
          date: dateStr,
          status: newStatus,
          completedAt: newStatus == 'completed' ? DateTime.now().toIso8601String() : null,
        ));
      }
    }

    final index = _todayGoals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _todayGoals = List<Goal>.from(_todayGoals);
      _todayGoals[index] = updatedGoal;
    }

    if (newStatus == 'completed') {
      await _dbHelper.updateStreak(goal.id!);
      await NotificationService().cancelGoalReminder(goal.id!);
    } else {
      _scheduleNotificationForGoal(updatedGoal);
    }

    _calculateCompletionRate();
    notifyListeners();
  }

  void _scheduleNotificationsForLoadedGoals() {
    for (final goal in _todayGoals) {
      if (goal.status == 'pending' && goal.endTime != null && goal.id != null) {
        _scheduleNotificationForGoal(goal);
      }
    }
  }

  void _scheduleNotificationForGoal(Goal goal) {
    if (goal.endTime == null || goal.id == null) return;
    if (goal.status == 'completed') return;

    try {
      final timeParts = goal.endTime!.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final goalDate = DateTime.parse(goal.date);
      final endDateTime = DateTime(
        goalDate.year, goalDate.month, goalDate.day, hour, minute,
      );

      NotificationService().scheduleGoalReminder(goal.id!, goal.title, endDateTime);
    } catch (_) {}
  }

  void _calculateCompletionRate() {
    if (_todayGoals.isEmpty) {
      _completionRate = 0.0;
      return;
    }
    final completed = _todayGoals.where((g) => g.status == 'completed').length;
    _completionRate = completed / _todayGoals.length;
  }
}
