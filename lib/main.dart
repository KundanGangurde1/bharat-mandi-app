// import 'package:flutter/material.dart';
// import 'features/auth/login_screen.dart';
// import 'features/dashboard/dashboard_screen.dart';
// import 'features/settings/settings_screen.dart';
// import 'package:provider/provider.dart'; // अॅड
// import './core/expense_controller.dart';

// void main() {
//   runApp(
//     ChangeNotifierProvider<ExpenseController>(
//       create: (context) => ExpenseController()..loadExpenseTypes(), // ऑटो लोड
//       child: const MyApp(),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'भारत मंडी',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: Colors.green,
//           brightness: Brightness.light,
//         ),
//         useMaterial3: true,
//         appBarTheme: const AppBarTheme(
//           centerTitle: true,
//           elevation: 2,
//           backgroundColor: Colors.green,
//           foregroundColor: Colors.white,
//         ),
//         cardTheme: CardThemeData(
//           elevation: 2,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           color: Colors.white,
//         ),
//         inputDecorationTheme: InputDecorationTheme(
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(10),
//             borderSide: const BorderSide(color: Colors.grey),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(10),
//             borderSide: const BorderSide(color: Colors.grey),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(10),
//             borderSide: const BorderSide(color: Colors.green, width: 2),
//           ),
//           filled: true,
//           fillColor: Colors.grey[50],
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.green,
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         ),
//       ),
//       home: const LoginScreen(),
//       routes: {
//         '/dashboard': (context) => const DashboardScreen(),
//         '/settings': (context) => const SettingsScreen(),
//       },
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// import 'package:sqflite/sqflite.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/expense_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/settings/settings_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/powersync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ REQUIRED FOR WINDOWS / DESKTOP
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await Supabase.initialize(
      url: 'https://tbwmkazufzwyucmyoddj.supabase.co',
      anonKey: 'sb_publishable_CYT-rFyMWzqy1nivhp1glQ_SxXVRzh8');
  await initPowerSync();
  runApp(
    ChangeNotifierProvider<ExpenseController>(
      create: (context) => ExpenseController()..loadExpenseTypes(), // ऑटो लोड
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
