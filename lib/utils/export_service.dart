import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import '../models/goal.dart';
import '../models/sub_task.dart';

class ExportService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<String> exportToJson(int userId) async {
    final goals = await _db.getAllGoalsByUserId(userId);
    final subTasks = await _db.getAllSubTasksByUserId(userId);
    final records = await _db.getAllRecordsByUserId(userId);

    final data = {
      'export_time': DateTime.now().toIso8601String(),
      'user_id': userId,
      'goals': goals.map((g) => g.toMap()).toList(),
      'sub_tasks': subTasks.map((s) => s.toMap()).toList(),
      'daily_records': records.map((r) => r.toMap()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<String> exportToCsv(int userId) async {
    final goals = await _db.getAllGoalsByUserId(userId);

    final buffer = StringBuffer();
    buffer.writeln('日期,标题,优先级,分类,状态,开始时间,结束时间');

    for (final goal in goals) {
      final title = goal.title.replaceAll(',', '，');
      final priority = _priorityLabel(goal.priority);
      final category = _categoryLabel(goal.category);
      final status = goal.status == 'completed' ? '已完成' : '进行中';
      final startTime = goal.startTime ?? '';
      final endTime = goal.endTime ?? '';
      buffer.writeln('${goal.date},$title,$priority,$category,$status,$startTime,$endTime');
    }

    return buffer.toString();
  }

  Future<String?> saveExportFile(String content, String filename) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }

      final file = File('${directory.path}/$filename');
      await file.writeAsString(content, encoding: utf8);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Validates JSON content and returns a summary of what will be imported.
  /// Returns null if the content is invalid.
  Map<String, dynamic>? validateImportJson(String jsonContent) {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      if (!data.containsKey('goals') || !data.containsKey('sub_tasks')) {
        return null;
      }
      final goals = data['goals'] as List;
      final subTasks = data['sub_tasks'] as List;
      return {
        'goals_count': goals.length,
        'sub_tasks_count': subTasks.length,
        'data': data,
      };
    } catch (e) {
      return null;
    }
  }

  /// Imports data from a JSON string into the database for the given user.
  /// Clears existing user data first, then inserts imported data.
  /// Returns the number of goals imported, or -1 on failure.
  Future<int> importFromJson(String jsonContent, int userId) async {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      if (!data.containsKey('goals') || !data.containsKey('sub_tasks')) {
        return -1;
      }

      final goalsData = data['goals'] as List;
      final subTasksData = data['sub_tasks'] as List;

      // Delete existing user data
      final existingGoals = await _db.getAllGoalsByUserId(userId);
      for (final goal in existingGoals) {
        if (goal.id != null) {
          // Delete subtasks for this goal first
          final subtasks = await _db.getSubTasksByGoalId(goal.id!);
          for (final st in subtasks) {
            await _db.deleteSubTask(st.id!);
          }
          await _db.deleteGoal(goal.id!);
        }
      }

      // Build a map of old goal id -> new goal id
      final Map<int, int> goalIdMap = {};

      // Insert goals
      for (final gMap in goalsData) {
        final map = Map<String, dynamic>.from(gMap);
        final oldId = map['id'] as int?;
        map.remove('id'); // Remove old id so DB assigns new one
        map['user_id'] = userId; // Override with current user

        final goal = Goal.fromMap({...map, 'id': null});
        final newId = await _db.insertGoal(goal);

        if (oldId != null) {
          goalIdMap[oldId] = newId;
        }
      }

      // Insert sub_tasks with updated goal_id references
      for (final stMap in subTasksData) {
        final map = Map<String, dynamic>.from(stMap);
        map.remove('id');
        final oldGoalId = map['goal_id'] as int;
        final newGoalId = goalIdMap[oldGoalId];
        if (newGoalId == null) continue; // Skip orphan subtasks

        map['goal_id'] = newGoalId;
        final subTask = SubTask.fromMap({...map, 'id': null});
        await _db.insertSubTask(subTask);
      }

      return goalsData.length;
    } catch (e) {
      return -1;
    }
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return '高';
      case 'medium':
        return '中';
      default:
        return '低';
    }
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'work':
        return '工作';
      case 'study':
        return '学习';
      case 'fitness':
        return '健身';
      case 'life':
        return '生活';
      default:
        return '其他';
    }
  }
}
