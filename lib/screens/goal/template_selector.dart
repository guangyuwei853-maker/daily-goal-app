import 'package:flutter/material.dart';
import '../../data/goal_templates.dart';
import '../../utils/ai_template_service.dart';

/// 模板选择结果
class TemplateSelectionResult {
  final GoalTemplate template;
  final List<String> selectedSubTasks;

  const TemplateSelectionResult({
    required this.template,
    required this.selectedSubTasks,
  });
}

/// 模板选择页面
class TemplateSelectorScreen extends StatefulWidget {
  const TemplateSelectorScreen({super.key});

  @override
  State<TemplateSelectorScreen> createState() => _TemplateSelectorScreenState();
}

class _TemplateSelectorScreenState extends State<TemplateSelectorScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'all';
  List<GoalTemplate> _filteredTemplates = GoalTemplateLibrary.templates;
  int? _expandedIndex;
  Map<int, Set<int>> _deselectedTasks = {};

  // AI 生成相关状态
  bool _isAiGenerating = false;
  GoalTemplate? _aiGeneratedTemplate;
  bool _showAiSuggestion = false;

  static const List<Map<String, String>> _categories = [
    {'key': 'all', 'label': '全部'},
    {'key': 'fitness', 'label': '健身'},
    {'key': 'study', 'label': '学习'},
    {'key': 'life', 'label': '生活'},
    {'key': 'work', 'label': '工作'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterTemplates();
  }

  void _filterTemplates() {
    final keyword = _searchController.text.trim();
    setState(() {
      List<GoalTemplate> results;
      if (keyword.isEmpty) {
        results = GoalTemplateLibrary.templates;
      } else {
        results = GoalTemplateLibrary.search(keyword);
      }

      if (_selectedCategory != 'all') {
        results =
            results.where((t) => t.category == _selectedCategory).toList();
      }

      _filteredTemplates = results;
      _expandedIndex = null;

      // 如果搜索有内容但无结果，显示 AI 建议
      _showAiSuggestion = keyword.isNotEmpty && results.isEmpty;
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterTemplates();
  }

  void _toggleExpand(int index) {
    setState(() {
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else {
        _expandedIndex = index;
      }
    });
  }

  void _toggleSubTask(int templateIndex, int taskIndex) {
    setState(() {
      _deselectedTasks.putIfAbsent(templateIndex, () => {});
      if (_deselectedTasks[templateIndex]!.contains(taskIndex)) {
        _deselectedTasks[templateIndex]!.remove(taskIndex);
      } else {
        _deselectedTasks[templateIndex]!.add(taskIndex);
      }
    });
  }

  void _useTemplate(GoalTemplate template, int displayIndex) {
    final deselected = _deselectedTasks[displayIndex] ?? {};
    final selectedTasks = <String>[];
    for (int i = 0; i < template.subTasks.length; i++) {
      if (!deselected.contains(i)) {
        selectedTasks.add(template.subTasks[i]);
      }
    }

    if (selectedTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个子任务')),
      );
      return;
    }

    Navigator.pop(
      context,
      TemplateSelectionResult(
        template: template,
        selectedSubTasks: selectedTasks,
      ),
    );
  }

  void _useAiTemplate() {
    if (_aiGeneratedTemplate == null) return;

    final deselected = _deselectedTasks[-1] ?? {};
    final selectedTasks = <String>[];
    for (int i = 0; i < _aiGeneratedTemplate!.subTasks.length; i++) {
      if (!deselected.contains(i)) {
        selectedTasks.add(_aiGeneratedTemplate!.subTasks[i]);
      }
    }

    if (selectedTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个子任务')),
      );
      return;
    }

    Navigator.pop(
      context,
      TemplateSelectionResult(
        template: _aiGeneratedTemplate!,
        selectedSubTasks: selectedTasks,
      ),
    );
  }

  Future<void> _generateAiTemplate() async {
    final theme = _searchController.text.trim();
    if (theme.isEmpty) return;

    setState(() {
      _isAiGenerating = true;
      _aiGeneratedTemplate = null;
    });

    final service = AiTemplateService();
    final result = await service.generateTemplate(theme);

    if (mounted) {
      setState(() {
        _isAiGenerating = false;
        _aiGeneratedTemplate = result;
      });

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('生成失败，请稍后重试')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        title: const Text(
          '选择模板',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '输入主题，如：减肥、学英语...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon:
                    Icon(Icons.search, color: Colors.grey.shade400),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade400),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF667eea)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          // 分类筛选
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['key'];
                return FilterChip(
                  selected: isSelected,
                  label: Text(cat['label']!),
                  onSelected: (_) => _onCategorySelected(cat['key']!),
                  selectedColor: const Color(0xFF667eea).withOpacity(0.15),
                  checkmarkColor: const Color(0xFF667eea),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF667eea)
                        : Colors.grey.shade200,
                  ),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color:
                        isSelected ? const Color(0xFF667eea) : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // 模板列表
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_filteredTemplates.isEmpty && !_showAiSuggestion && _aiGeneratedTemplate == null) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // AI 生成建议区域
        if (_showAiSuggestion || _aiGeneratedTemplate != null)
          _buildAiSection(),

        // 模板列表
        ..._filteredTemplates.asMap().entries.map((entry) {
          return _buildTemplateCard(entry.value, entry.key);
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '没有找到相关模板',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '试试 AI 智能生成？',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isAiGenerating ? null : _generateAiTemplate,
            icon: const Text('✨', style: TextStyle(fontSize: 18)),
            label: const Text('AI 智能生成'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667eea).withOpacity(0.08),
            const Color(0xFF764ba2).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF667eea).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI 为你生成专属模板',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF667eea),
                  ),
                ),
              ),
              if (!_isAiGenerating && _aiGeneratedTemplate == null)
                TextButton(
                  onPressed: _generateAiTemplate,
                  child: const Text(
                    '生成',
                    style: TextStyle(color: Color(0xFF667eea)),
                  ),
                ),
            ],
          ),
          if (_isAiGenerating) ...[
            const SizedBox(height: 16),
            const Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF667eea),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '正在为你生成专属模板...',
                    style: TextStyle(
                      color: Color(0xFF667eea),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_aiGeneratedTemplate != null) ...[
            const SizedBox(height: 12),
            _buildAiTemplateContent(),
          ],
        ],
      ),
    );
  }

  Widget _buildAiTemplateContent() {
    final template = _aiGeneratedTemplate!;
    final deselected = _deselectedTasks[-1] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${template.icon} ${template.name}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          template.description,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        ...template.subTasks.asMap().entries.map((entry) {
          final isSelected = !deselected.contains(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: InkWell(
              onTap: () => _toggleAiSubTask(entry.key),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: 20,
                    color: isSelected
                        ? const Color(0xFF667eea)
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? Colors.black87
                            : Colors.grey.shade400,
                        decoration: isSelected
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _useAiTemplate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              '使用此模板',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleAiSubTask(int taskIndex) {
    setState(() {
      _deselectedTasks.putIfAbsent(-1, () => {});
      if (_deselectedTasks[-1]!.contains(taskIndex)) {
        _deselectedTasks[-1]!.remove(taskIndex);
      } else {
        _deselectedTasks[-1]!.add(taskIndex);
      }
    });
  }

  Widget _buildTemplateCard(GoalTemplate template, int index) {
    final isExpanded = _expandedIndex == index;
    final deselected = _deselectedTasks[index] ?? {};

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? const Color(0xFF667eea).withOpacity(0.4)
              : Colors.grey.shade100,
        ),
        boxShadow: [
          if (isExpanded)
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _toggleExpand(index),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 卡片头部
                Row(
                  children: [
                    Text(template.icon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            template.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${template.subTasks.length}项',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF667eea),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),

                // 展开内容
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  ...template.subTasks.asMap().entries.map((entry) {
                    final isSelected = !deselected.contains(entry.key);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () => _toggleSubTask(index, entry.key),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 20,
                              color: isSelected
                                  ? const Color(0xFF667eea)
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected
                                      ? Colors.black87
                                      : Colors.grey.shade400,
                                  decoration: isSelected
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _useTemplate(template, index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '使用此模板',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
