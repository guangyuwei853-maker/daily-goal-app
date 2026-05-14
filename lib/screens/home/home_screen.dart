import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/goal_provider.dart';
import '../../models/goal.dart';
import '../../widgets/goal_card.dart';
import '../../widgets/progress_ring.dart';
import '../goal/create_goal_screen.dart';
import 'photo_section.dart';
import 'photo_gallery_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final provider = context.read<GoalProvider>();
    final dateStr = _dateToString(provider.selectedDate);
    provider.loadGoals(widget.userId, dateStr);
    provider.loadRepeatGoals(widget.userId);
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}月${date.day}日 $weekday';
  }

  Future<void> _pickDate(BuildContext context) async {
    final provider = context.read<GoalProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) {
      provider.setSelectedDate(picked);
      provider.loadGoals(widget.userId, _dateToString(picked));
    }
  }

  void _previousDay() {
    final provider = context.read<GoalProvider>();
    final newDate = provider.selectedDate.subtract(const Duration(days: 1));
    provider.setSelectedDate(newDate);
    provider.loadGoals(widget.userId, _dateToString(newDate));
  }

  void _nextDay() {
    final provider = context.read<GoalProvider>();
    final newDate = provider.selectedDate.add(const Duration(days: 1));
    provider.setSelectedDate(newDate);
    provider.loadGoals(widget.userId, _dateToString(newDate));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Consumer<GoalProvider>(
        builder: (context, provider, child) {
          final pendingGoals =
              provider.todayGoals.where((g) => g.status == 'pending').toList();
          final completedGoals =
              provider.todayGoals.where((g) => g.status == 'completed').toList();

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadGoals(
                  widget.userId, _dateToString(provider.selectedDate));
              await provider.loadRepeatGoals(widget.userId);
            },
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  floating: true,
                  backgroundColor: const Color(0xFFF8F9FE),
                  elevation: 0,
                  title: const Text(
                    '每日目标',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  centerTitle: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.photo_library_outlined),
                      tooltip: '成长记录',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PhotoGalleryScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                // Date selector
                SliverToBoxAdapter(
                  child: _buildDateSelector(provider),
                ),
                // Progress section
                SliverToBoxAdapter(
                  child: _buildProgressSection(provider),
                ),
                // Photo section
                SliverToBoxAdapter(
                  child: PhotoSection(
                    dateStr: _dateToString(provider.selectedDate),
                  ),
                ),
                // Repeat tasks
                if (provider.repeatGoals.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildRepeatTasksSection(provider),
                  ),
                // Today's goals header
                SliverToBoxAdapter(
                  child: _buildGoalsHeader(provider),
                ),
                // Goals list
                if (provider.todayGoals.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyState(),
                  )
                else
                  SliverList(
                    delegate: SliverChildListDelegate([
                      // Pending goals first
                      ...pendingGoals.map(
                        (goal) => GoalCard(
                          goal: goal,
                          onToggleComplete: () =>
                              provider.toggleGoalComplete(goal),
                          onDelete: () => provider.deleteGoal(goal.id!),
                        ),
                      ),
                      // Completed goals at bottom
                      ...completedGoals.map(
                        (goal) => GoalCard(
                          goal: goal,
                          onToggleComplete: () =>
                              provider.toggleGoalComplete(goal),
                          onDelete: () => provider.deleteGoal(goal.id!),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ]),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateGoalScreen(userId: widget.userId),
            ),
          );
          _loadData();
        },
        backgroundColor: const Color(0xFF667eea),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildDateSelector(GoalProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _previousDay,
            icon: const Icon(Icons.chevron_left, color: Colors.black54),
          ),
          GestureDetector(
            onTap: () => _pickDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _formatDate(provider.selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _nextDay,
            icon: const Icon(Icons.chevron_right, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(GoalProvider provider) {
    final total = provider.todayGoals.length;
    final completed =
        provider.todayGoals.where((g) => g.status == 'completed').length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          ProgressRing(
            progress: provider.completionRate,
            size: 140,
            strokeWidth: 14,
          ),
          const SizedBox(height: 12),
          Text(
            '已完成 $completed/$total 个目标',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatTasksSection(GoalProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '每日打卡 \u{1F525}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: provider.repeatGoals.length,
            itemBuilder: (context, index) {
              final goal = provider.repeatGoals[index];
              final isCompleted = goal.status == 'completed';
              return Container(
                width: 130,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF667eea).withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF667eea)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '连续7天',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => provider.toggleGoalComplete(goal),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? const Color(0xFF667eea)
                                : Colors.transparent,
                            border: Border.all(
                              color: isCompleted
                                  ? const Color(0xFF667eea)
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: isCompleted
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 14)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsHeader(GoalProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          const Text(
            '今日目标',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${provider.todayGoals.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF667eea),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(Icons.flag_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '今天还没有目标',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击 + 添加新目标',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
