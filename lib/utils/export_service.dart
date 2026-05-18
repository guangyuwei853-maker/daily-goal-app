import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';

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
