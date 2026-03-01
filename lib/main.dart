import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/powersync_service.dart';
import 'core/expense_controller.dart';
import 'core/active_firm_provider.dart';
import 'app/AppRootScreen.dart';
import 'core/services/initialization_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/auth_service.dart';
import 'core/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // =========================
  // SUPABASE INIT
  // =========================
  await Supabase.initialize(
    url: 'https://tbwmkazufzwyucmyoddj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRid21rYXp1Znp3eXVjbXlvZGRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxMDA3ODgsImV4cCI6MjA4NTY3Njc4OH0.7TY_Yy9B1rhqqLbadvYGlakfG-2lIRTbBluMm78muE8',
  );

  try {
    // =========================
    // POWERSYNC INIT
    // =========================
    await initPowerSync();
    print('✅ PowerSync initialization completed');

    await InitializationService.initializeDefaultData();

    runApp(const MyApp());
  } catch (e) {
    print('❌ Failed to initialize PowerSync: $e');
    runApp(const ErrorApp());
  }
}

// ======================================================
// MAIN APP
// ======================================================

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  Future<Widget> _getStartScreen() async {
    // Not logged in
    if (!AuthService.isLoggedIn()) {
      return const LoginScreen();
    }

    // Ensure user exists in app_users
    await AuthService.createUserIfNotExists();

    // Premium check
    final premium = await AuthService.isPremiumUser();

    if (premium) {
      return const AppRootScreen();
    } else {
      return const WaitingScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ExpenseController(),
        ),
        ChangeNotifierProvider(
          create: (_) => ActiveFirmProvider()..loadActiveFirm(),
        ),
      ],
      child: MaterialApp(
        title: 'भारत मंडी',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Color(0xFF1976D2),
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: FutureBuilder<Widget>(
          future: _getStartScreen(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return snapshot.data!;
          },
        ),
      ),
    );
  }
}

// ======================================================
// WAITING SCREEN (TEMP SIMPLE VERSION)
// ======================================================

class WaitingScreen extends StatelessWidget {
  const WaitingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "Account waiting for admin approval",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

// ======================================================
// ERROR APP
// ======================================================

class ErrorApp extends StatelessWidget {
  const ErrorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'भारत मंडी - Error',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Database Initialization Failed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please restart the application',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  runApp(const MyApp());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
