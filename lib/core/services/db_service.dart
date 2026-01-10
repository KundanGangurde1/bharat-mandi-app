import 'dart:io';
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
    final path = '$dbPath/bharat_mandi.db';

    return await openDatabase(
      path,
      version: 3, // ⬅️ VERSION 2 से 3 कर दिया
      onCreate: (db, version) async {
        await _createTablesV3(db); // NEW V3 tables
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migrate from version 1 to 2
        if (oldVersion < 2) {
          await _migrateV1ToV2(db);
        }

        // Migrate from version 2 to 3
        if (oldVersion < 3) {
          await _migrateV2ToV3(db);
        }
      },
    );
  }

  static Future<void> _createTablesV3(Database db) async {
    // Farmers table
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

    // Traders table
    await db.execute('''
      CREATE TABLE traders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        firm_name TEXT,
        area TEXT,
        opening_balance REAL DEFAULT 0,
        active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Produce table
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

    // ============ EXPENSE TYPES TABLE V3 ============
    await db.execute('''
      CREATE TABLE expense_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        apply_on TEXT NOT NULL,           -- 'farmer' or 'trader'
        mode TEXT NOT NULL,               -- 'fixed', 'percentage', 'per_piece', 'per_bag', 'per_weight'
        default_value REAL DEFAULT 0,
        active INTEGER DEFAULT 1,
        show_in_report INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parchi_id TEXT,
        farmer_code TEXT,
        farmer_name TEXT,
        trader_code TEXT,
        trader_name TEXT,
        produce_code TEXT,
        produce_name TEXT,
        unit TEXT,
        quantity REAL,
        rate REAL,
        gross REAL,
        hamali REAL DEFAULT 0,
        tolai REAL DEFAULT 0,
        advance REAL DEFAULT 0,
        other_expense REAL DEFAULT 0,
        total_expense REAL DEFAULT 0,
        net REAL,
        created_at TEXT
      )
    ''');

    // Payments table
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
  }

  static Future<void> _migrateV1ToV2(Database db) async {
    print("Migrating database from version 1 to 2...");

    // Add missing columns to farmers
    try {
      await db.execute('ALTER TABLE farmers ADD COLUMN phone TEXT');
      await db.execute('ALTER TABLE farmers ADD COLUMN address TEXT');
      await db.execute(
          'ALTER TABLE farmers ADD COLUMN opening_balance REAL DEFAULT 0');
      await db.execute('ALTER TABLE farmers ADD COLUMN updated_at TEXT');
    } catch (e) {
      print("Error in farmers migration V1→V2: $e");
    }

    // Add missing columns to traders
    try {
      await db.execute('ALTER TABLE traders ADD COLUMN phone TEXT');
      await db.execute('ALTER TABLE traders ADD COLUMN firm_name TEXT');
      await db.execute('ALTER TABLE traders ADD COLUMN area TEXT');
      await db.execute(
          'ALTER TABLE traders ADD COLUMN opening_balance REAL DEFAULT 0');
      await db.execute('ALTER TABLE traders ADD COLUMN updated_at TEXT');
    } catch (e) {
      print("Error in traders migration V1→V2: $e");
    }

    // Add missing columns to produce
    try {
      await db.execute('ALTER TABLE produce ADD COLUMN variety TEXT');
      await db.execute('ALTER TABLE produce ADD COLUMN category TEXT');
      await db.execute('ALTER TABLE produce ADD COLUMN updated_at TEXT');
    } catch (e) {
      print("Error in produce migration V1→V2: $e");
    }

    print("Database migration V1→V2 completed!");
  }

  static Future<void> _migrateV2ToV3(Database db) async {
    print("Migrating database from version 2 to 3...");

    // Check if expense_types table exists (old schema)
    try {
      // First, check what columns exist in old table
      final oldData = await db.query('expense_types', limit: 1);

      if (oldData.isNotEmpty) {
        // If old table has 'expense_type' column instead of 'apply_on'
        if (oldData.first.containsKey('expense_type') &&
            !oldData.first.containsKey('apply_on')) {
          print("Old expense_types table found. Migrating columns...");

          // Create a new table with correct schema
          await db.execute('''
            CREATE TABLE expense_types_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT UNIQUE NOT NULL,
              apply_on TEXT NOT NULL,
              mode TEXT NOT NULL,
              default_value REAL DEFAULT 0,
              active INTEGER DEFAULT 1,
              show_in_report INTEGER DEFAULT 1,
              created_at TEXT,
              updated_at TEXT
            )
          ''');

          // Copy data from old table to new table
          final oldRows = await db.query('expense_types');
          for (final row in oldRows) {
            // Convert 'expense_type' to 'apply_on'
            final applyOn = row['expense_type']?.toString() ?? 'farmer';

            await db.insert('expense_types_new', {
              'name': row['name'],
              'apply_on': applyOn,
              'mode': 'fixed', // Default mode for old data
              'default_value': row['default_rate'] ?? 0,
              'active': row['active'] ?? 1,
              'show_in_report': row['show_in_report'] ?? 1,
              'created_at': row['created_at'],
              'updated_at':
                  row['updated_at'] ?? DateTime.now().toIso8601String(),
            });
          }

          // Drop old table and rename new table
          await db.execute('DROP TABLE expense_types');
          await db
              .execute('ALTER TABLE expense_types_new RENAME TO expense_types');

          print("Expense types table migrated successfully!");
        }
      }
    } catch (e) {
      print("Error in expense_types migration V2→V3: $e");

      // If migration fails, drop and recreate table
      try {
        await db.execute('DROP TABLE IF EXISTS expense_types');
        await db.execute('''
          CREATE TABLE expense_types (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            apply_on TEXT NOT NULL,
            mode TEXT NOT NULL,
            default_value REAL DEFAULT 0,
            active INTEGER DEFAULT 1,
            show_in_report INTEGER DEFAULT 1,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
        print("Expense types table recreated with new schema.");
      } catch (e2) {
        print("Error recreating expense_types table: $e2");
      }
    }

    print("Database migration V2→V3 completed!");
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
    String? applyOn, // 'farmer' or 'trader'
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
    required String applyOn, // 'farmer' or 'trader'
    required String
        mode, // 'fixed', 'percentage', 'per_piece', 'per_bag', 'per_weight'
    required double defaultValue,
    bool active = true,
    bool showInReport = true,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.insert('expense_types', {
      'name': name,
      'apply_on': applyOn,
      'mode': mode,
      'default_value': defaultValue,
      'active': active ? 1 : 0,
      'show_in_report': showInReport ? 1 : 0,
      'created_at': now,
    });
  }

  static Future<void> updateExpenseType(
      int id, Map<String, dynamic> data) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();

    await db.update(
      'expense_types',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
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
    final path = '$dbPath/bharat_mandi.db';

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      print("Database deleted: $path");
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
}
