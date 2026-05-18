import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../data/goal_templates.dart';

/// AI 模板生成服务
/// 通过 AI API 根据用户输入的主题生成自定义每日子任务
class AiTemplateService {
  static const String _defaultApiUrl =
      'http://model.mify.ai.srv/v1/chat/completions';
  static const String _defaultModel = 'pa/claude-sonnet-4-5-20250929';
  static const Duration _timeout = Duration(seconds: 10);

  final String apiUrl;
  final String model;
  final String? apiKey;

  AiTemplateService({
    this.apiUrl = _defaultApiUrl,
    this.model = _defaultModel,
    this.apiKey,
  });

  /// 根据主题生成模板
  /// 如果 AI 请求失败，则回退到内置模板模糊匹配
  Future<GoalTemplate?> generateTemplate(String theme) async {
    if (theme.trim().isEmpty) return null;

    try {
      final result = await _callAiApi(theme).timeout(_timeout);
      if (result != null) return result;
    } catch (e) {
      // AI 请求超时或失败，使用回退策略
    }

    return _fallbackMatch(theme);
  }

  /// 调用 AI API 生成子任务
  Future<GoalTemplate?> _callAiApi(String theme) async {
    final prompt = '''你是一个每日目标规划助手。用户想养成"$theme"的习惯。
请为用户生成 5-8 个每天可以执行的具体子任务。

要求：
1. 每个子任务必须是具体、可执行、可量化的
2. 子任务按时间顺序或逻辑顺序排列
3. 难度适中，普通人可以每天坚持

请严格按以下 JSON 格式返回，不要包含其他文字：
{"name": "模板名称", "description": "一句话描述", "tasks": ["任务1", "任务2", ...]}''';

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.7,
      'max_tokens': 1024,
    });

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: body,
    );

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    final content = data['choices']?[0]?['message']?['content'] as String?;
    if (content == null) return null;

    return _parseAiResponse(content, theme);
  }

  /// 解析 AI 返回的 JSON 内容
  GoalTemplate? _parseAiResponse(String content, String theme) {
    try {
      // 尝试从响应中提取 JSON（可能被包裹在 markdown 代码块中）
      String jsonStr = content.trim();
      if (jsonStr.contains('```')) {
        final match = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```')
            .firstMatch(jsonStr);
        if (match != null) {
          jsonStr = match.group(1)!.trim();
        }
      }

      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      final name = parsed['name'] as String? ?? theme;
      final description = parsed['description'] as String? ?? '自定义目标：$theme';
      final tasks = (parsed['tasks'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      if (tasks.isEmpty) return null;

      return GoalTemplate(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        icon: '✨',
        category: _guessCategory(theme),
        description: description,
        subTasks: tasks,
      );
    } catch (e) {
      return null;
    }
  }

  /// 回退：通过模糊关键词匹配内置模板
  GoalTemplate? _fallbackMatch(String theme) {
    final results = GoalTemplateLibrary.search(theme);
    if (results.isNotEmpty) return results.first;
    return null;
  }

  /// 根据主题关键词猜测分类
  String _guessCategory(String theme) {
    const fitnessKeywords = ['减肥', '运动', '跑步', '健身', '锻炼', '瘦', '肌肉', '体重'];
    const studyKeywords = ['学习', '阅读', '读书', '编程', '英语', '写作', '考试', '背单词'];
    const workKeywords = ['工作', '职场', '理财', '赚钱', '副业', '升职', '效率'];
    const lifeKeywords = ['早起', '睡眠', '冥想', '饮食', '戒', '习惯', '整理', '护肤'];

    for (final kw in fitnessKeywords) {
      if (theme.contains(kw)) return 'fitness';
    }
    for (final kw in studyKeywords) {
      if (theme.contains(kw)) return 'study';
    }
    for (final kw in workKeywords) {
      if (theme.contains(kw)) return 'work';
    }
    for (final kw in lifeKeywords) {
      if (theme.contains(kw)) return 'life';
    }
    return 'other';
  }
}
