import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user.dart';
import '../models/goal.dart';
import '../models/sub_task.dart';
import '../models/daily_record.dart';
import 'database_interface.dart';
import 'database_web.dart';
import 'database_native.dart';

class DatabaseHelper implements DatabaseInterface {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  late final DatabaseInterface _delegate = kIsWeb ? DatabaseWeb() : DatabaseNative();

  @override
  Future<int> insertUser(User user) => _delegate.insertUser(user);
  @override
  Future<User?> getUserByUsername(String username) => _delegate.getUserByUsername(username);
  @override
  Future<User?> getUserById(int id) => _delegate.getUserById(id);

  @override
  Future<int> insertGoal(Goal goal) => _delegate.insertGoal(goal);
  @override
  Future<int> updateGoal(Goal goal) => _delegate.updateGoal(goal);
  @override
  Future<int> deleteGoal(int id) => _delegate.deleteGoal(id);
  @override
  Future<List<Goal>> getGoalsByDate(int userId, String date) => _delegate.getGoalsByDate(userId, date);
  @override
  Future<List<Goal>> getRepeatGoals(int userId) => _delegate.getRepeatGoals(userId);
  @override
  Future<List<Goal>> getAllGoalsByUserId(int userId) => _delegate.getAllGoalsByUserId(userId);

  @override
  Future<int> insertSubTask(SubTask subTask) => _delegate.insertSubTask(subTask);
  @override
  Future<int> updateSubTask(SubTask subTask) => _delegate.updateSubTask(subTask);
  @override
  Future<int> deleteSubTask(int id) => _delegate.deleteSubTask(id);
  @override
  Future<List<SubTask>> getSubTasksByGoalId(int goalId) => _delegate.getSubTasksByGoalId(goalId);
  @override
  Future<List<SubTask>> getAllSubTasksByUserId(int userId) => _delegate.getAllSubTasksByUserId(userId);

  @override
  Future<int> insertRecord(DailyRecord record) => _delegate.insertRecord(record);
  @override
  Future<int> updateRecord(DailyRecord record) => _delegate.updateRecord(record);
  @override
  Future<List<DailyRecord>> getRecordsByDate(String date) => _delegate.getRecordsByDate(date);
  @override
  Future<List<DailyRecord>> getRecordsByGoalId(int goalId) => _delegate.getRecordsByGoalId(goalId);
  @override
  Future<List<DailyRecord>> getAllRecordsByUserId(int userId) => _delegate.getAllRecordsByUserId(userId);

  @override
  Future<Map<String, dynamic>?> getStreak(int goalId) => _delegate.getStreak(goalId);
  @override
  Future<void> updateStreak(int goalId) => _delegate.updateStreak(goalId);

  @override
  Future<double> getCompletionRate(int userId, String startDate, String endDate) =>
      _delegate.getCompletionRate(userId, startDate, endDate);
  @override
  Future<Map<String, int>> getWeeklyStats(int userId) => _delegate.getWeeklyStats(userId);
}
