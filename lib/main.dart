import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/sub_task_provider.dart';
import 'utils/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService().initialize();
  await NotificationService().requestPermissions();

  final authProvider = AuthProvider();
  await authProvider.checkLoginState();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => SubTaskProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
