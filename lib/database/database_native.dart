import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/goal.dart';
import '../models/sub_task.dart';
import '../models/daily_record.dart';
import 'database_interface.dart';

class DatabaseNative implements DatabaseInterface {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'daily_goal.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        priority TEXT NOT NULL DEFAULT 'medium',
        category TEXT NOT NULL DEFAULT 'other',
        start_time TEXT,
        end_time TEXT,
        is_repeat INTEGER NOT NULL DEFAULT 0,
        repeat_rule TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE sub_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        order_num INTEGER NOT NULL,
        FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE daily_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        completed_at TEXT,
        FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE streaks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL UNIQUE,
        current_streak INTEGER NOT NULL DEFAULT 0,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        last_completed_date TEXT,
        FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE
      )
    ''');
  }

  @override
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  @override
  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final maps = await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  @override
  Future<User?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  @override
  Future<int> insertGoal(Goal goal) async {
    final db = await database;
    return await db.insert('goals', goal.toMap());
  }

  @override
  Future<int> updateGoal(Goal goal) async {
    final db = await database;
    return await db.update('goals', goal.toMap(), where: 'id = ?', whereArgs: [goal.id]);
  }

  @override
  Future<int> deleteGoal(int id) async {
    final db = await database;
    await db.delete('sub_tasks', where: 'goal_id = ?', whereArgs: [id]);
    await db.delete('daily_records', where: 'goal_id = ?', whereArgs: [id]);
    await db.delete('streaks', where: 'goal_id = ?', whereArgs: [id]);
    return await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Goal>> getGoalsByDate(int userId, String date) async {
    final db = await database;
    final maps = await db.query('goals', where: 'user_id = ? AND date = ?', whereArgs: [userId, date]);
    return maps.map((m) => Goal.fromMap(m)).toList();
  }

  @override
  Future<List<Goal>> getRepeatGoals(int userId) async {
    final db = await database;
    final maps = await db.query('goals', where: 'user_id = ? AND is_repeat = 1', whereArgs: [userId]);
    return maps.map((m) => Goal.fromMap(m)).toList();
  }

  @override
  Future<List<Goal>> getAllGoalsByUserId(int userId) async {
    final db = await database;
    final maps = await db.query('goals', where: 'user_id = ?', whereArgs: [userId], orderBy: 'date DESC');
    return maps.map((m) => Goal.fromMap(m)).toList();
  }

  @override
  Future<int> insertSubTask(SubTask subTask) async {
    final db = await database;
    return await db.insert('sub_tasks', subTask.toMap());
  }

  @override
  Future<int> updateSubTask(SubTask subTask) async {
    final db = await database;
    return await db.update('sub_tasks', subTask.toMap(), where: 'id = ?', whereArgs: [subTask.id]);
  }

  @override
  Future<int> deleteSubTask(int id) async {
    final db = await database;
    return await db.delete('sub_tasks', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<SubTask>> getSubTasksByGoalId(int goalId) async {
    final db = await database;
    final maps = await db.query('sub_tasks', where: 'goal_id = ?', whereArgs: [goalId], orderBy: 'order_num ASC');
    return maps.map((m) => SubTask.fromMap(m)).toList();
  }

  @override
  Future<List<SubTask>> getAllSubTasksByUserId(int userId) async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT st.* FROM sub_tasks st INNER JOIN goals g ON st.goal_id = g.id WHERE g.user_id = ? ORDER BY st.goal_id, st.order_num',
      [userId],
    );
    return maps.map((m) => SubTask.fromMap(m)).toList();
  }

  @override
  Future<int> insertRecord(DailyRecord record) async {
    final db = await database;
    return await db.insert('daily_records', record.toMap());
  }

  @override
  Future<int> updateRecord(DailyRecord record) async {
    final db = await database;
    return await db.update('daily_records', record.toMap(), where: 'id = ?', whereArgs: [record.id]);
  }

  @override
  Future<List<DailyRecord>> getRecordsByDate(String date) async {
    final db = await database;
    final maps = await db.query('daily_records', where: 'date = ?', whereArgs: [date]);
    return maps.map((m) => DailyRecord.fromMap(m)).toList();
  }

  @override
  Future<List<DailyRecord>> getRecordsByGoalId(int goalId) async {
    final db = await database;
    final maps = await db.query('daily_records', where: 'goal_id = ?', whereArgs: [goalId], orderBy: 'date DESC');
    return maps.map((m) => DailyRecord.fromMap(m)).toList();
  }

  @override
  Future<List<DailyRecord>> getAllRecordsByUserId(int userId) async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT dr.* FROM daily_records dr INNER JOIN goals g ON dr.goal_id = g.id WHERE g.user_id = ? ORDER BY dr.date DESC',
      [userId],
    );
    return maps.map((m) => DailyRecord.fromMap(m)).toList();
  }

  @override
  Future<Map<String, dynamic>?> getStreak(int goalId) async {
    final db = await database;
    final maps = await db.query('streaks', where: 'goal_id = ?', whereArgs: [goalId]);
    if (maps.isEmpty) return null;
    return maps.first;
  }

  @override
  Future<void> updateStreak(int goalId) async {
    final db = await database;
    final existing = await getStreak(goalId);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (existing == null) {
      await db.insert('streaks', {
        'goal_id': goalId, 'current_streak': 1, 'longest_streak': 1, 'last_completed_date': today,
      });
    } else {
      final lastDate = existing['last_completed_date'] as String?;
      int cs = existing['current_streak'] as int;
      int ls = existing['longest_streak'] as int;
      if (lastDate != null) {
        final diff = DateTime.parse(today).difference(DateTime.parse(lastDate)).inDays;
        if (diff == 1) cs += 1; else if (diff > 1) cs = 1;
      } else { cs = 1; }
      if (cs > ls) ls = cs;
      await db.update('streaks', {'current_streak': cs, 'longest_streak': ls, 'last_completed_date': today},
          where: 'goal_id = ?', whereArgs: [goalId]);
    }
  }

  @override
  Future<double> getCompletionRate(int userId, String startDate, String endDate) async {
    final db = await database;
    final total = (await db.rawQuery(
        'SELECT COUNT(*) as c FROM goals WHERE user_id = ? AND date >= ? AND date <= ?',
        [userId, startDate, endDate])).first['c'] as int? ?? 0;
    if (total == 0) return 0.0;
    final completed = (await db.rawQuery(
        "SELECT COUNT(*) as c FROM goals WHERE user_id = ? AND date >= ? AND date <= ? AND status = 'completed'",
        [userId, startDate, endDate])).first['c'] as int? ?? 0;
    return completed / total;
  }

  @override
  Future<Map<String, int>> getWeeklyStats(int userId) async {
    final db = await database;
    final now = DateTime.now();
    final ws = now.subtract(Duration(days: now.weekday - 1));
    final stats = <String, int>{};
    for (int i = 0; i < 7; i++) {
      final d = ws.add(Duration(days: i)).toIso8601String().substring(0, 10);
      final r = await db.rawQuery(
          "SELECT COUNT(*) as c FROM goals WHERE user_id = ? AND date = ? AND status = 'completed'",
          [userId, d]);
      stats[d] = (r.first['c'] as int?) ?? 0;
    }
    return stats;
  }
}
