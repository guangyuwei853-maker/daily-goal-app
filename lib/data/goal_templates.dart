/// 目标模板数据模型和内置模板库
class GoalTemplate {
  final String id;
  final String name;
  final String icon;
  final String category; // fitness, study, life, work
  final String description;
  final List<String> subTasks;

  const GoalTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.category,
    required this.description,
    required this.subTasks,
  });
}

class GoalTemplateLibrary {
  static const List<GoalTemplate> templates = [
    GoalTemplate(
      id: 'fitness_weight_loss',
      name: '减肥瘦身',
      icon: '🏃',
      category: 'fitness',
      description: '科学减脂，养成健康饮食和运动习惯',
      subTasks: [
        '晨起空腹喝一杯温水(300ml)',
        '早餐控制在400大卡以内',
        '午餐以蔬菜和蛋白质为主',
        '下午做30分钟有氧运动',
        '晚餐在7点前吃完且控量',
        '记录今日体重和饮食',
        '步行不少于8000步',
        '不喝含糖饮料',
      ],
    ),
    GoalTemplate(
      id: 'study_reading',
      name: '每日阅读',
      icon: '📚',
      category: 'study',
      description: '培养阅读习惯，每天汲取新知识',
      subTasks: [
        '阅读至少30页书籍',
        '做读书笔记(至少3个要点)',
        '摘抄一段喜欢的句子',
        '回顾昨天的阅读内容',
        '睡前阅读15分钟',
      ],
    ),
    GoalTemplate(
      id: 'life_early_rise',
      name: '早起习惯',
      icon: '🌅',
      category: 'life',
      description: '养成早起习惯，精力充沛开启每一天',
      subTasks: [
        '闹钟响后5秒内起床',
        '起床后立即拉开窗帘',
        '喝一杯温水',
        '做5分钟拉伸运动',
        '冷水洗脸提神',
        '用10分钟规划今天的任务',
      ],
    ),
    GoalTemplate(
      id: 'study_english',
      name: '英语学习',
      icon: '🇬🇧',
      category: 'study',
      description: '系统提升英语听说读写能力',
      subTasks: [
        '背诵20个新单词',
        '听英语听力15分钟',
        '朗读一篇英语短文',
        '用英语写3个句子',
        '看一段英语视频(无字幕)',
        '复习昨天的单词',
      ],
    ),
    GoalTemplate(
      id: 'fitness_running',
      name: '跑步训练',
      icon: '🏃‍♂️',
      category: 'fitness',
      description: '坚持跑步锻炼，提升心肺功能和耐力',
      subTasks: [
        '跑前热身拉伸10分钟',
        '慢跑3-5公里',
        '跑后拉伸放松10分钟',
        '记录今日跑步距离和配速',
        '补充水分和蛋白质',
        '检查跑鞋磨损情况',
      ],
    ),
    GoalTemplate(
      id: 'life_meditation',
      name: '冥想正念',
      icon: '🧘',
      category: 'life',
      description: '通过冥想减压，提升专注力和内心平静',
      subTasks: [
        '找一个安静的地方坐下',
        '做10分钟深呼吸冥想',
        '进行5分钟身体扫描',
        '写下3件今天感恩的事',
        '睡前做5分钟放松冥想',
      ],
    ),
    GoalTemplate(
      id: 'study_programming',
      name: '编程学习',
      icon: '💻',
      category: 'study',
      description: '每日编程练习，持续提升技术能力',
      subTasks: [
        '学习一个新的知识点或API',
        '写至少50行练习代码',
        '阅读优秀开源项目代码30分钟',
        '解决一道算法题',
        '整理今日学习笔记',
        '复习昨天的代码',
      ],
    ),
    GoalTemplate(
      id: 'life_healthy_diet',
      name: '健康饮食',
      icon: '🥗',
      category: 'life',
      description: '均衡营养，养成科学健康的饮食习惯',
      subTasks: [
        '早餐必须吃且营养均衡',
        '每餐至少一份蔬菜',
        '每天喝够8杯水(2000ml)',
        '下午茶用水果代替零食',
        '晚餐七分饱不吃宵夜',
        '记录今日饮食内容',
      ],
    ),
    GoalTemplate(
      id: 'work_finance',
      name: '理财记账',
      icon: '💰',
      category: 'work',
      description: '记录开支，培养理财意识和储蓄习惯',
      subTasks: [
        '记录今日所有支出',
        '检查是否有不必要的消费',
        '查看账户余额',
        '学习一条理财知识',
        '制定明天的预算',
      ],
    ),
    GoalTemplate(
      id: 'study_writing',
      name: '写作练习',
      icon: '✍️',
      category: 'study',
      description: '坚持写作输出，提升表达和思考能力',
      subTasks: [
        '自由写作15分钟不停笔',
        '修改昨天的文章',
        '阅读一篇优秀文章并分析',
        '积累3个好的表达或素材',
        '构思明天的写作主题',
      ],
    ),
    GoalTemplate(
      id: 'life_digital_detox',
      name: '戒手机',
      icon: '📵',
      category: 'life',
      description: '减少手机依赖，夺回专注力和时间',
      subTasks: [
        '起床后1小时不看手机',
        '工作/学习时手机静音放远',
        '吃饭时不看手机',
        '设置每日屏幕使用时间上限',
        '睡前1小时放下手机',
        '记录今日屏幕使用时间',
      ],
    ),
    GoalTemplate(
      id: 'work_career',
      name: '职场提升',
      icon: '💼',
      category: 'work',
      description: '提升职场竞争力，高效工作稳步成长',
      subTasks: [
        '提前10分钟到达工作岗位',
        '列出今日3件最重要的工作',
        '专注完成一项深度工作(不少于2小时)',
        '主动与同事沟通一次',
        '下班前整理工作台和明日计划',
        '学习一个行业相关知识',
      ],
    ),
  ];

  /// 按关键词搜索模板（模糊匹配名称、描述、子任务）
  static List<GoalTemplate> search(String keyword) {
    if (keyword.trim().isEmpty) return templates;
    final lowerKeyword = keyword.toLowerCase();
    return templates.where((t) {
      if (t.name.toLowerCase().contains(lowerKeyword)) return true;
      if (t.description.toLowerCase().contains(lowerKeyword)) return true;
      for (final task in t.subTasks) {
        if (task.toLowerCase().contains(lowerKeyword)) return true;
      }
      return false;
    }).toList();
  }

  /// 按分类筛选模板
  static List<GoalTemplate> getByCategory(String category) {
    if (category.isEmpty || category == 'all') return templates;
    return templates.where((t) => t.category == category).toList();
  }
}
