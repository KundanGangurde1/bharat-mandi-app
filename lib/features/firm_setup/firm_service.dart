import '../../core/services/powersync_service.dart';
import 'firm_model.dart';

class FirmService {
  static const String tableName = 'firms';

  // नवीन firm add करा
  static Future<String> addFirm(Firm firm) async {
    try {
      // ✅ 1. ID स्वतः generate करा
      final String firmId = DateTime.now().millisecondsSinceEpoch.toString();

      // ✅ 2. insertRecord void आहे — return expect करू नका
      await insertRecord(tableName, {
        'id': firmId,
        'name': firm.name,
        'code': firm.code,
        'owner_name': firm.owner_name,
        'phone': firm.phone,
        'email': firm.email,
        'address': firm.address,
        'city': firm.city,
        'state': firm.state,
        'pincode': firm.pincode,
        'gst_number': firm.gst_number,
        'pan_number': firm.pan_number,
        'active': firm.active ? 1 : 0,
        'created_at': firm.created_at,
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ Firm added with ID: $firmId');

      // ✅ 3. String ID return करा
      return firmId;
    } catch (e) {
      print("❌ Error adding firm: $e");
      rethrow;
    }
  }

  // सर्व firms मिळवा
  static Future<List<Firm>> getAllFirms() async {
    try {
      final maps = await powerSyncDB.getAll(
        'SELECT * FROM $tableName ORDER BY created_at DESC',
      );

      return maps.map((map) => Firm.fromMap(map)).toList();
    } catch (e) {
      print("❌ Error getting all firms: $e");
      return [];
    }
  }

  // एक specific firm मिळवा
  static Future<Firm?> getFirmById(String id) async {
    try {
      final maps = await powerSyncDB.getAll(
        'SELECT * FROM $tableName WHERE id = ?',
        [id],
      );

      if (maps.isNotEmpty) {
        return Firm.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print("❌ Error getting firm by ID: $e");
      return null;
    }
  }

  // Active firm मिळवा (सर्वात नवीन)
  static Future<Firm?> getActiveFirm() async {
    try {
      final maps = await powerSyncDB.getAll(
        'SELECT * FROM $tableName WHERE active = 1 ORDER BY created_at DESC LIMIT 1',
      );

      if (maps.isNotEmpty) {
        return Firm.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print("❌ Error getting active firm: $e");
      return null;
    }
  }

  // Firm update करा
  static Future<void> updateFirm(Firm firm) async {
    try {
      if (firm.id == null) {
        throw Exception('Firm ID cannot be null for update');
      }

      await updateRecord(tableName, firm.id.toString(), {
        'name': firm.name,
        'code': firm.code,
        'owner_name': firm.owner_name,
        'phone': firm.phone,
        'email': firm.email,
        'address': firm.address,
        'city': firm.city,
        'state': firm.state,
        'pincode': firm.pincode,
        'gst_number': firm.gst_number,
        'pan_number': firm.pan_number,
        'active': firm.active ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ Firm updated: ${firm.id}');
    } catch (e) {
      print("❌ Error updating firm: $e");
      rethrow;
    }
  }

  // Firm delete करा
  static Future<void> deleteFirm(String id) async {
    try {
      await deleteRecord(tableName, id);
      print('✅ Firm deleted: $id');
    } catch (e) {
      print("❌ Error deleting firm: $e");
      rethrow;
    }
  }

  // Firm को inactive करा (soft delete)
  static Future<void> deactivateFirm(String id) async {
    try {
      await updateRecord(tableName, id, {
        'active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ Firm deactivated: $id');
    } catch (e) {
      print("❌ Error deactivating firm: $e");
      rethrow;
    }
  }

  // Firm count मिळवा
  static Future<int> getFirmCount() async {
    try {
      final result = await powerSyncDB.getAll(
        'SELECT COUNT(*) as count FROM $tableName',
      );

      if (result.isNotEmpty) {
        return (result.first['count'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      print("❌ Error getting firm count: $e");
      return 0;
    }
  }
}
