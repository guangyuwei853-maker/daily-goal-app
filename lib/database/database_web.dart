import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/goal.dart';
import '../models/sub_task.dart';
import '../models/daily_record.dart';
import 'database_interface.dart';

class DatabaseWeb implements DatabaseInterface {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _goals = [];
  List<Map<String, dynamic>> _subTasks = [];
  List<Map<String, dynamic>> _dailyRecords = [];
  List<Map<String, dynamic>> _streaks = [];
  int _userIdCounter = 0;
  int _goalIdCounter = 0;
  int _subTaskIdCounter = 0;
  int _recordIdCounter = 0;
  int _streakIdCounter = 0;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    _users = _loadList(prefs, 'db_users');
    _goals = _loadList(prefs, 'db_goals');
    _subTasks = _loadList(prefs, 'db_subTasks');
    _dailyRecords = _loadList(prefs, 'db_dailyRecords');
    _streaks = _loadList(prefs, 'db_streaks');
    _userIdCounter = prefs.getInt('db_userIdCounter') ?? 0;
    _goalIdCounter = prefs.getInt('db_goalIdCounter') ?? 0;
    _subTaskIdCounter = prefs.getInt('db_subTaskIdCounter') ?? 0;
    _recordIdCounter = prefs.getInt('db_recordIdCounter') ?? 0;
    _streakIdCounter = prefs.getInt('db_streakIdCounter') ?? 0;
  }

  List<Map<String, dynamic>> _loadList(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('db_users', jsonEncode(_users));
    await prefs.setString('db_goals', jsonEncode(_goals));
    await prefs.setString('db_subTasks', jsonEncode(_subTasks));
    await prefs.setString('db_dailyRecords', jsonEncode(_dailyRecords));
    await prefs.setString('db_streaks', jsonEncode(_streaks));
    await prefs.setInt('db_userIdCounter', _userIdCounter);
    await prefs.setInt('db_goalIdCounter', _goalIdCounter);
    await prefs.setInt('db_subTaskIdCounter', _subTaskIdCounter);
    await prefs.setInt('db_recordIdCounter', _recordIdCounter);
    await prefs.setInt('db_streakIdCounter', _streakIdCounter);
  }

  @override
  Future<int> insertUser(User user) async {
    await _ensureInitialized();
    _userIdCounter++;
    final map = user.toMap();
    map['id'] = _userIdCounter;
    _users.add(map);
    await _persist();
    return _userIdCounter;
  }

  @override
  Future<User?> getUserByUsername(String username) async {
    await _ensureInitialized();
    for (final map in _users) {
      if (map['username'] == username) return User.fromMap(map);
    }
    return null;
  }

  @override
  Future<User?> getUserById(int id) async {
    await _ensureInitialized();
    for (final map in _users) {
      if (map['id'] == id) return User.fromMap(map);
    }
    return null;
  }

  @override
  Future<int> insertGoal(Goal goal) async {
    await _ensureInitialized();
    _goalIdCounter++;
    final map = goal.toMap();
    map['id'] = _goalIdCounter;
    _goals.add(map);
    await _persist();
    return _goalIdCounter;
  }

  @override
  Future<int> updateGoal(Goal goal) async {
    await _ensureInitialized();
    for (int i = 0; i < _goals.length; i++) {
      if (_goals[i]['id'] == goal.id) {
        final map = goal.toMap(); map['id'] = goal.id;
        _goals[i] = map;
        await _persist();
        return 1;
      }
    }
    return 0;
  }

  @override
  Future<int> deleteGoal(int id) async {
    await _ensureInitialized();
    _goals.removeWhere((g) => g['id'] == id);
    _subTasks.removeWhere((s) => s['goal_id'] == id);
    _dailyRecords.removeWhere((r) => r['goal_id'] == id);
    _streaks.removeWhere((s) => s['goal_id'] == id);
    await _persist();
    return 1;
  }

  @override
  Future<List<Goal>> getGoalsByDate(int userId, String date) async {
    await _ensureInitialized();
    return _goals.where((g) => g['user_id'] == userId && g['date'] == date)
        .map((g) => Goal.fromMap(g)).toList();
  }

  @override
  Future<List<Goal>> getRepeatGoals(int userId) async {
    await _ensureInitialized();
    return _goals.where((g) => g['user_id'] == userId && (g['is_repeat'] == 1 || g['is_repeat'] == true))
        .map((g) => Goal.fromMap(g)).toList();
  }

  @override
  Future<int> insertSubTask(SubTask subTask) async {
    await _ensureInitialized();
    _subTaskIdCounter++;
    final map = subTask.toMap(); map['id'] = _subTaskIdCounter;
    _subTasks.add(map);
    await _persist();
    return _subTaskIdCounter;
  }

  @override
  Future<int> updateSubTask(SubTask subTask) async {
    await _ensureInitialized();
    for (int i = 0; i < _subTasks.length; i++) {
      if (_subTasks[i]['id'] == subTask.id) {
        final map = subTask.toMap(); map['id'] = subTask.id;
        _subTasks[i] = map;
        await _persist();
        return 1;
      }
    }
    return 0;
  }

  @override
  Future<int> deleteSubTask(int id) async {
    await _ensureInitialized();
    _subTasks.removeWhere((s) => s['id'] == id);
    await _persist();
    return 1;
  }

  @override
  Future<List<SubTask>> getSubTasksByGoalId(int goalId) async {
    await _ensureInitialized();
    return _subTasks.where((s) => s['goal_id'] == goalId)
        .map((s) => SubTask.fromMap(s)).toList()
      ..sort((a, b) => a.orderNum.compareTo(b.orderNum));
  }

  @override
  Future<int> insertRecord(DailyRecord record) async {
    await _ensureInitialized();
    _recordIdCounter++;
    final map = record.toMap(); map['id'] = _recordIdCounter;
    _dailyRecords.add(map);
    await _persist();
    return _recordIdCounter;
  }

  @override
  Future<int> updateRecord(DailyRecord record) async {
    await _ensureInitialized();
    for (int i = 0; i < _dailyRecords.length; i++) {
      if (_dailyRecords[i]['id'] == record.id) {
        final map = record.toMap(); map['id'] = record.id;
        _dailyRecords[i] = map;
        await _persist();
        return 1;
      }
    }
    return 0;
  }

  @override
  Future<List<DailyRecord>> getRecordsByDate(String date) async {
    await _ensureInitialized();
    return _dailyRecords.where((r) => r['date'] == date)
        .map((r) => DailyRecord.fromMap(r)).toList();
  }

  @override
  Future<List<DailyRecord>> getRecordsByGoalId(int goalId) async {
    await _ensureInitialized();
    return _dailyRecords.where((r) => r['goal_id'] == goalId)
        .map((r) => DailyRecord.fromMap(r)).toList();
  }

  @override
  Future<Map<String, dynamic>?> getStreak(int goalId) async {
    await _ensureInitialized();
    for (final s in _streaks) {
      if (s['goal_id'] == goalId) return Map<String, dynamic>.from(s);
    }
    return null;
  }

  @override
  Future<void> updateStreak(int goalId) async {
    await _ensureInitialized();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final idx = _streaks.indexWhere((s) => s['goal_id'] == goalId);
    if (idx == -1) {
      _streakIdCounter++;
      _streaks.add({'id': _streakIdCounter, 'goal_id': goalId, 'current_streak': 1, 'longest_streak': 1, 'last_completed_date': today});
    } else {
      final existing = _streaks[idx];
      final lastDate = existing['last_completed_date'] as String?;
      int cs = existing['current_streak'] as int;
      int ls = existing['longest_streak'] as int;
      if (lastDate != null) {
        final diff = DateTime.parse(today).difference(DateTime.parse(lastDate)).inDays;
        if (diff == 1) cs += 1; else if (diff > 1) cs = 1;
      } else { cs = 1; }
      if (cs > ls) ls = cs;
      _streaks[idx] = {...existing, 'current_streak': cs, 'longest_streak': ls, 'last_completed_date': today};
    }
    await _persist();
  }

  @override
  Future<double> getCompletionRate(int userId, String startDate, String endDate) async {
    await _ensureInitialized();
    final m = _goals.where((g) => g['user_id'] == userId && g['date'] != null && g['date'].compareTo(startDate) >= 0 && g['date'].compareTo(endDate) <= 0);
    if (m.isEmpty) return 0.0;
    return m.where((g) => g['status'] == 'completed').length / m.length;
  }

  @override
  Future<Map<String, int>> getWeeklyStats(int userId) async {
    await _ensureInitialized();
    final now = DateTime.now();
    final ws = now.subtract(Duration(days: now.weekday - 1));
    final stats = <String, int>{};
    for (int i = 0; i < 7; i++) {
      final d = ws.add(Duration(days: i)).toIso8601String().substring(0, 10);
      stats[d] = _goals.where((g) => g['user_id'] == userId && g['date'] == d && g['status'] == 'completed').length;
    }
    return stats;
  }
}
