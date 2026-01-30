import 'package:sqflite/sqflite.dart';
import '../../core/services/db_service.dart';
import 'firm_model.dart';

class FirmService {
  static const String tableName = 'firms';

  // Database table तयार करा
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT UNIQUE,
        owner_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        address TEXT NOT NULL,
        city TEXT NOT NULL,
        state TEXT NOT NULL,
        pincode TEXT NOT NULL,
        gst_number TEXT,
        pan_number TEXT,
        active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
  }

  // नवीन firm add करा
  static Future<int> addFirm(Firm firm) async {
    final db = await DBService.database;
    return await db.insert(
      tableName,
      firm.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // सर्व firms मिळवा
  static Future<List<Firm>> getAllFirms() async {
    final db = await DBService.database;
    final maps = await db.query(tableName, orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => Firm.fromMap(maps[i]));
  }

  // एक specific firm मिळवा
  static Future<Firm?> getFirmById(int id) async {
    final db = await DBService.database;
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Firm.fromMap(maps.first);
    }
    return null;
  }

  // Active firm मिळवा (सर्वात नवीन)
  static Future<Firm?> getActiveFirm() async {
    final db = await DBService.database;
    final maps = await db.query(
      tableName,
      where: 'active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Firm.fromMap(maps.first);
    }
    return null;
  }

  // Firm update करा
  static Future<int> updateFirm(Firm firm) async {
    final db = await DBService.database;
    final updatedFirm = firm.copyWith(
      updated_at: DateTime.now().toIso8601String(),
    );
    return await db.update(
      tableName,
      updatedFirm.toMap(),
      where: 'id = ?',
      whereArgs: [firm.id],
    );
  }

  // Firm delete करा
  static Future<int> deleteFirm(int id) async {
    final db = await DBService.database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Firm को inactive करा (soft delete)
  static Future<int> deactivateFirm(int id) async {
    final db = await DBService.database;
    return await db.update(
      tableName,
      {'active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Firm count मिळवा
  static Future<int> getFirmCount() async {
    final db = await DBService.database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
