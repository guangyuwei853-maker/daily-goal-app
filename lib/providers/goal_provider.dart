import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/goal.dart';
import '../models/daily_record.dart';

class GoalProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Goal> _todayGoals = [];
  List<Goal> _repeatGoals = [];
  DateTime _selectedDate = DateTime.now();
  double _completionRate = 0.0;

  List<Goal> get todayGoals => _todayGoals;
  List<Goal> get repeatGoals => _repeatGoals;
  DateTime get selectedDate => _selectedDate;
  double get completionRate => _completionRate;

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> loadGoals(int userId, String date) async {
    _todayGoals = await _dbHelper.getGoalsByDate(userId, date);

    // Generate daily records for repeat goals that don't have records yet
    final repeats = await _dbHelper.getRepeatGoals(userId);
    final existingRecords = await _dbHelper.getRecordsByDate(date);
    final existingGoalIds = existingRecords.map((r) => r.goalId).toSet();

    for (final goal in repeats) {
      if (!existingGoalIds.contains(goal.id) && _shouldRepeatOnDate(goal, date)) {
        final record = DailyRecord(
          goalId: goal.id!,
          date: date,
          status: 'pending',
        );
        await _dbHelper.insertRecord(record);
      }
    }

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
    _todayGoals.add(goal.copyWith(id: id));
    _calculateCompletionRate();
    notifyListeners();
  }

  Future<void> updateGoal(Goal goal) async {
    await _dbHelper.updateGoal(goal);
    final index = _todayGoals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _todayGoals[index] = goal;
    }
    _calculateCompletionRate();
    notifyListeners();
  }

  Future<void> deleteGoal(int id) async {
    await _dbHelper.deleteGoal(id);
    _todayGoals.removeWhere((g) => g.id == id);
    _calculateCompletionRate();
    notifyListeners();
  }

  Future<void> toggleGoalComplete(Goal goal) async {
    final newStatus = goal.status == 'completed' ? 'pending' : 'completed';
    final updatedGoal = goal.copyWith(status: newStatus);
    await _dbHelper.updateGoal(updatedGoal);

    final index = _todayGoals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _todayGoals[index] = updatedGoal;
    }

    if (newStatus == 'completed') {
      await _dbHelper.updateStreak(goal.id!);
    }

    _calculateCompletionRate();
    notifyListeners();
  }

  Future<void> loadRepeatGoals(int userId) async {
    _repeatGoals = await _dbHelper.getRepeatGoals(userId);
    notifyListeners();
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
