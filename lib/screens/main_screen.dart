import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/goal_provider.dart';
import '../utils/update_service.dart';
import '../widgets/update_dialog.dart';
import 'home/home_screen.dart';
import 'home/photo_gallery_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        final dateStr = DateTime.now().toIso8601String().substring(0, 10);
        context.read<GoalProvider>().loadGoals(auth.currentUser!.id!, dateStr);
      }
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    if (kIsWeb) return;
    try {
      debugPrint('[UpdateCheck] currentVersion=${AppConfig.currentVersion}, url=${AppConfig.updateCheckUrl}');
      final updateInfo = await UpdateService().checkForUpdate();
      debugPrint('[UpdateCheck] result=${updateInfo?.version ?? "no update"}');
      if (updateInfo != null && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => UpdateDialog(updateInfo: updateInfo),
        );
      }
    } catch (e) {
      debugPrint('[UpdateCheck] error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.currentUser?.id ?? 0;
    final screens = [
      HomeScreen(userId: userId),
      const _CalendarScreen(),
      const _StatsScreen(),
      _ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryStart,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: '今日',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '日历',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '统计',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

// ===== 日历页面 =====
class _CalendarScreen extends StatefulWidget {
  const _CalendarScreen();

  @override
  State<_CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<_CalendarScreen> {
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final goalProvider = context.watch<GoalProvider>();
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday;

    return Scaffold(
      appBar: AppBar(
        title: const Text('日历'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Month selector
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(year, month - 1);
                    });
                  },
                ),
                Text(
                  '$year年$month月',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(year, month + 1);
                    });
                  },
                ),
              ],
            ),
          ),
          // Weekday headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['一', '二', '三', '四', '五', '六', '日']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: firstWeekday - 1 + daysInMonth,
              itemBuilder: (context, index) {
                if (index < firstWeekday - 1) {
                  return const SizedBox();
                }
                final day = index - (firstWeekday - 1) + 1;
                final date = DateTime(year, month, day);
                final isToday = _isToday(date);
                final isSelected = _selectedDay != null &&
                    _selectedDay!.year == date.year &&
                    _selectedDay!.month == date.month &&
                    _selectedDay!.day == date.day;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDay = date);
                    final auth = context.read<AuthProvider>();
                    final userId = auth.currentUser?.id ?? 0;
                    goalProvider.loadGoals(userId, date.toIso8601String().substring(0, 10));
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryStart
                          : isToday
                              ? AppColors.primaryStart.withValues(alpha: 0.1)
                              : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: isToday ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          // Selected day's goals
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('选择一个日期查看目标', style: TextStyle(color: Colors.grey)))
                : goalProvider.todayGoals.isEmpty
                    ? const Center(child: Text('该日期没有目标', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: goalProvider.todayGoals.length,
                        itemBuilder: (context, index) {
                          final goal = goalProvider.todayGoals[index];
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                goal.status == 'completed' ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: goal.status == 'completed' ? Colors.green : Colors.grey,
                              ),
                              title: Text(
                                goal.title,
                                style: TextStyle(
                                  decoration: goal.status == 'completed' ? TextDecoration.lineThrough : null,
                                  color: goal.status == 'completed' ? Colors.grey : null,
                                ),
                              ),
                              subtitle: Text('${goal.startTime ?? ''} - ${goal.endTime ?? ''}'),
                              trailing: _priorityChip(goal.priority),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Widget _priorityChip(String priority) {
    Color color;
    switch (priority) {
      case 'high':
        color = AppColors.priorityHigh;
        break;
      case 'medium':
        color = AppColors.priorityMedium;
        break;
      default:
        color = AppColors.priorityLow;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority == 'high' ? '高' : priority == 'medium' ? '中' : '低',
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}

// ===== 统计页面 =====
class _StatsScreen extends StatelessWidget {
  const _StatsScreen();

  @override
  Widget build(BuildContext context) {
    final goalProvider = context.watch<GoalProvider>();
    final rate = (goalProvider.completionRate * 100).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(title: const Text('统计'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Completion rate card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('今日完成率', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Text('$rate%',
                        style: const TextStyle(
                            fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primaryStart)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: goalProvider.completionRate,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primaryStart),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Stats cards row
            Row(
              children: [
                Expanded(
                  child: _statCard('今日目标', '${goalProvider.todayGoals.length}', Icons.flag, AppColors.primaryStart),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                      '已完成',
                      '${goalProvider.todayGoals.where((g) => g.status == "completed").length}',
                      Icons.check_circle,
                      Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                      '进行中',
                      '${goalProvider.todayGoals.where((g) => g.status == "pending").length}',
                      Icons.schedule,
                      Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Tips
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: AppColors.priorityMedium),
                        SizedBox(width: 8),
                        Text('小贴士', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '坚持每天设定并完成小目标，积少成多！\n建议每天设定3-5个核心目标，保持专注。',
                      style: TextStyle(color: Colors.grey.shade700, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ===== 我的页面 =====
class _ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('我的'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // User info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primaryStart,
                    child: Text(
                      (user?.username ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.username ?? '未登录',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('加入时间：${user?.createdAt.substring(0, 10) ?? '-'}',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Menu items
          Card(
            child: Column(
              children: [
                _menuItem(Icons.dark_mode, '深色模式', trailing: const Text('即将推出', style: TextStyle(color: Colors.grey, fontSize: 13))),
                const Divider(height: 1),
                _menuItem(Icons.file_download, '导出数据', trailing: const Text('即将推出', style: TextStyle(color: Colors.grey, fontSize: 13))),
                const Divider(height: 1),
                _menuItem(Icons.info_outline, '关于', trailing: Text('v${AppConfig.currentVersion}', style: const TextStyle(color: Colors.grey, fontSize: 13))),
                const Divider(height: 1),
                _buildCheckUpdateItem(context),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Logout button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                auth.logout();
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('退出登录', style: TextStyle(color: Colors.red, fontSize: 16)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, {Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryStart),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }

  Widget _buildCheckUpdateItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.system_update, color: AppColors.primaryStart),
      title: const Text('检查更新'),
      trailing: Text('v${AppConfig.currentVersion}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
      onTap: () async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        String debugInfo = '';
        try {
          final url = AppConfig.updateCheckUrl;
          debugInfo += '请求: $url\n';
          final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
          debugInfo += '状态码: ${response.statusCode}\n';
          debugInfo += '响应: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}\n';

          final updateInfo = await UpdateService().checkForUpdate();
          if (!context.mounted) return;
          Navigator.of(context).pop();

          if (updateInfo != null) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => UpdateDialog(updateInfo: updateInfo),
            );
          } else {
            debugInfo += '本地版本: ${AppConfig.currentVersion}\n结论: 已是最新';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('当前已是最新版本\n$debugInfo'), duration: const Duration(seconds: 5)),
            );
          }
        } catch (e) {
          if (!context.mounted) return;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('检查失败: $e\n$debugInfo'), duration: const Duration(seconds: 8)),
          );
        }
      },
    );
  }
}
