import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DBService {
  static Database? _database;
  static bool _initialized = false;

  static Future<Database> get database async {
    if (_database != null) return _database!;

    if (!_initialized) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _initialized = true;
    }

    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bharat_mandi.db');

    return await openDatabase(
      path,
      version: 8,
      onCreate: (Database db, int version) async {
        await _createAllTables(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        await _handleMigrations(db, oldVersion, newVersion);
      },
    );
  }

  static Future<void> _createAllTables(Database db) async {
    // Farmers
    await db.execute('''
      CREATE TABLE farmers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        opening_balance REAL DEFAULT 0,
        active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Traders (खरेदीदार)
    await db.execute('''
      CREATE TABLE traders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        firm_name TEXT,
        area TEXT,
        area_id,
        opening_balance REAL DEFAULT 0,
        active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Produce (माल)
    await db.execute('''
      CREATE TABLE produce (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        variety TEXT,
        category TEXT,
        active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Expense Types (खर्च प्रकार)
    await db.execute('''
      CREATE TABLE expense_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        apply_on TEXT NOT NULL,
        calculation_type TEXT NOT NULL DEFAULT 'per_dag',
        default_value REAL DEFAULT 0,
        active INTEGER DEFAULT 1,
        show_in_report INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Transactions (पर्ची)
    await db.execute('''
  CREATE TABLE transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,  
    parchi_id INTEGER NOT NULL, 
    farmer_code TEXT,
    farmer_name TEXT,
    trader_code TEXT,
    trader_name TEXT,
    produce_code TEXT,
    produce_name TEXT,
    dag REAL DEFAULT 0,
    quantity REAL,
    rate REAL,
    gross REAL,
    total_expense REAL DEFAULT 0,
    net REAL,
    created_at TEXT
  )
''');

    // Transaction Expenses (खर्च लॉग)
    await db.execute('''
      CREATE TABLE transaction_expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parchi_id TEXT NOT NULL,
        expense_type_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Payments (वसूली)
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trader_code TEXT,
        trader_name TEXT,
        amount REAL,
        payment_mode TEXT,
        notes TEXT,
        created_at TEXT
      )
    ''');
    await db.execute('''
  CREATE TABLE areas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    active INTEGER DEFAULT 1,
    created_at TEXT,
    updated_at TEXT
  )
''');
  }

  static Future<void> _handleMigrations(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE expense_types ADD COLUMN area_id calculation_type TEXT DEFAULT "per_dag"',
      );
      print("Migration: Added 'calculation_type' column to expense_types");
    }
    if (oldVersion < 7) {
      await db.execute('''
    CREATE TABLE IF NOT EXISTS areas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      active INTEGER DEFAULT 1,
      created_at TEXT,
      updated_at TEXT
    )
  ''');
      if (oldVersion < 8) {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN id INTEGER PRIMARY KEY AUTOINCREMENT',
        );
        await db.execute(
          'ALTER TABLE transactions DROP COLUMN parchi_id',
        ); // जुना काढून टाक
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN parchi_id INTEGER NOT NULL DEFAULT 0',
        );
        print("Migration: Updated transactions table for parchi_id grouping");
      }
      await db.execute(
        'ALTER TABLE traders ADD COLUMN area_id INTEGER DEFAULT NULL',
      );
      print("Migration: Added 'areas' table and 'area_id' column to traders");
    }
  }

  // ============ VALIDATION METHODS ============
  static Future<bool> isCodeUnique(String code) async {
    final db = await database;
    final upperCode = code.toUpperCase();

    final farmers = await db.query(
      'farmers',
      where: 'code = ?',
      whereArgs: [upperCode],
    );
    final traders = await db.query(
      'traders',
      where: 'code = ?',
      whereArgs: [upperCode],
    );
    final produce = await db.query(
      'produce',
      where: 'code = ?',
      whereArgs: [upperCode],
    );

    return farmers.isEmpty && traders.isEmpty && produce.isEmpty;
  }

  static Future<bool> isCodeUsedInTransaction(String code, String table) async {
    final db = await database;

    String column = '';
    switch (table) {
      case 'farmers':
        column = 'farmer_code';
        break;
      case 'traders':
        column = 'trader_code';
        break;
      case 'produce':
        column = 'produce_code';
        break;
      default:
        return false;
    }

    final result = await db.query(
      'transactions',
      where: '$column = ?',
      whereArgs: [code.toUpperCase()],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // ============ EXPENSE TYPE METHODS ============
  static Future<List<Map<String, dynamic>>> getExpenseTypes({
    String? applyOn,
    bool activeOnly = true,
  }) async {
    final db = await database;

    String where = '';
    List<Object?> whereArgs = [];

    if (applyOn != null) {
      where = 'apply_on = ?';
      whereArgs.add(applyOn);
    }

    if (activeOnly) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'active = 1';
    }

    return await db.query(
      'expense_types',
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'apply_on, name ASC',
    );
  }

  static Future<int> addExpenseType({
    required String name,
    required String applyOn,
    required String calculation_type,
    required double default_value,
    bool active = true,
    bool show_in_report = true,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.insert('expense_types', {
      'name': name,
      'apply_on': applyOn,
      'calculation_type': calculation_type,
      'default_value': default_value,
      'active': active ? 1 : 0,
      'show_in_report': show_in_report ? 1 : 0,
      'created_at': now,
    });
  }

  static Future<void> updateExpenseType(
    int id,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();

    await db.update('expense_types', data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> toggleExpenseType(int id, bool active) async {
    final db = await database;

    await db.update(
      'expense_types',
      {
        'active': active ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteExpenseType(int id) async {
    final db = await database;
    await db.delete('expense_types', where: 'id = ?', whereArgs: [id]);
  }

  // ============ DATABASE RESET ============
  static Future<void> resetDatabase() async {
    await close();

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bharat_mandi.db');

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      print("Database deleted and will be recreated on next run");
    }

    _database = null;
    _initialized = false;
  }

  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // शेतकरी थकबाकी (Farmer Dues)
  static Future<List<Map<String, dynamic>>> getFarmerDues() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT f.id, f.name, f.phone, f.opening_balance,
           COALESCE(SUM(t.net), 0) as total_paid,
           (f.opening_balance - COALESCE(SUM(t.net), 0)) as dues
    FROM farmers f
    LEFT JOIN transactions t ON f.code = t.farmer_code
    WHERE f.active = 1
    GROUP BY f.id
    HAVING dues > 0
    ORDER BY f.name ASC
  ''');
  }

  // खरेदीदार थकबाकी (Trader Recovery)
  static Future<List<Map<String, dynamic>>> getTraderRecovery({
    String? areaId,
  }) async {
    final db = await database;

    String query = '''
    SELECT t.id, t.name, t.firm_name, t.phone, t.area, t.opening_balance,
           COALESCE(SUM(tr.gross), 0) as total_gross,
           COALESCE(SUM(tr.total_expense), 0) as total_expense,
           (t.opening_balance + COALESCE(SUM(tr.gross), 0) - COALESCE(SUM(tr.total_expense), 0)) as receivable
    FROM traders t
    LEFT JOIN transactions tr ON t.code = tr.trader_code
    WHERE t.active = 1
  ''';

    List<Object?> args = [];

    if (areaId != null) {
      query += ' AND t.area_id = ?';
      args.add(areaId);
    }

    query += ' GROUP BY t.id HAVING receivable > 0 ORDER BY t.name ASC';

    return await db.rawQuery(query, args);
  }

  static Future<void> deletePavti(String parchiId) async {
    final db = await database;

    // थकबाकी अपडेट (recovery update)
    final transactions = await db.query(
      'transactions',
      where: 'parchi_id = ?',
      whereArgs: [parchiId],
    );
    for (var tr in transactions) {
      final traderCode = tr['trader_code'] as String;
      final net = tr['net'] as double? ?? 0.0;

      await db.rawUpdate(
        'UPDATE traders SET opening_balance = opening_balance - ? WHERE code = ?',
        [net, traderCode],
      );
    }

    // transactions आणि transaction_expenses डिलीट कर
    await db.delete(
      'transactions',
      where: 'parchi_id = ?',
      whereArgs: [parchiId],
    );
    await db.delete(
      'transaction_expenses',
      where: 'parchi_id = ?',
      whereArgs: [parchiId],
    );
  }
}
