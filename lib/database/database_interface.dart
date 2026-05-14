import '../models/user.dart';
import '../models/goal.dart';
import '../models/sub_task.dart';
import '../models/daily_record.dart';

abstract class DatabaseInterface {
  Future<int> insertUser(User user);
  Future<User?> getUserByUsername(String username);
  Future<User?> getUserById(int id);

  Future<int> insertGoal(Goal goal);
  Future<int> updateGoal(Goal goal);
  Future<int> deleteGoal(int id);
  Future<List<Goal>> getGoalsByDate(int userId, String date);
  Future<List<Goal>> getRepeatGoals(int userId);

  Future<int> insertSubTask(SubTask subTask);
  Future<int> updateSubTask(SubTask subTask);
  Future<int> deleteSubTask(int id);
  Future<List<SubTask>> getSubTasksByGoalId(int goalId);

  Future<int> insertRecord(DailyRecord record);
  Future<int> updateRecord(DailyRecord record);
  Future<List<DailyRecord>> getRecordsByDate(String date);
  Future<List<DailyRecord>> getRecordsByGoalId(int goalId);

  Future<Map<String, dynamic>?> getStreak(int goalId);
  Future<void> updateStreak(int goalId);

  Future<double> getCompletionRate(int userId, String startDate, String endDate);
  Future<Map<String, int>> getWeeklyStats(int userId);
}
