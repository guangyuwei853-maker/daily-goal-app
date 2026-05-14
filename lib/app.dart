import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/goal/create_goal_screen.dart';
import 'screens/goal/goal_detail_screen.dart';
import 'screens/home/photo_gallery_screen.dart';
import 'models/goal.dart';
import 'theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DailyGoal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoggedIn) {
            return const MainScreen();
          }
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainScreen(),
        '/photo/gallery': (context) => const PhotoGalleryScreen(),
      },
      onGenerateRoute: (settings) {
        final auth = WidgetsBinding.instance.rootElement != null
            ? null
            : null;

        if (settings.name == '/goal/create') {
          final userId = settings.arguments as int? ?? 0;
          return MaterialPageRoute(
            builder: (context) => CreateGoalScreen(userId: userId),
          );
        }
        if (settings.name == '/goal/detail') {
          final goal = settings.arguments as Goal;
          return MaterialPageRoute(
            builder: (context) => GoalDetailScreen(goal: goal),
          );
        }
        if (settings.name == '/goal/edit') {
          final goal = settings.arguments as Goal;
          return MaterialPageRoute(
            builder: (context) => CreateGoalScreen(userId: goal.userId, existingGoal: goal),
          );
        }
        return null;
      },
    );
  }
}
