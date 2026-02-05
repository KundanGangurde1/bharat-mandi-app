// ✅ CORRECTED MAIN.DART - POWERSYNC ONLY (NO SUPABASE INIT)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/expense_controller.dart';
import 'core/services/powersync_service.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/settings/settings_screen.dart';

void main() async {
  // ✅ STEP 1: Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ STEP 2: Initialize PowerSync (handles offline-first sync)
  try {
    await initPowerSync();
    print('✅ PowerSync initialized successfully');
  } catch (e) {
    print('❌ PowerSync initialization failed: $e');
  }

  // ✅ STEP 3: Start the app
  runApp(
    ChangeNotifierProvider<ExpenseController>(
      create: (context) => ExpenseController()..loadExpenseTypes(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'भारत मंडी',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
