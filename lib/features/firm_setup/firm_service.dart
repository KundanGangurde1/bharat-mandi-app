import '../../core/services/powersync_service.dart';
import 'firm_model.dart';

class FirmService {
  static const String tableName = 'firms';

  // नवीन firm add करा
  static Future<String> addFirm(Firm firm) async {
    try {
      final String firmId =
          firm.id ?? DateTime.now().millisecondsSinceEpoch.toString();

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
        'active': 0, // 🔥 Always 0 here
        'created_at': firm.created_at,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return firmId;
    } catch (e) {
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
      final result = await powerSyncDB.getAll(
        'SELECT * FROM firms WHERE active = 1 LIMIT 1',
      );

      if (result.isNotEmpty) {
        return Firm.fromMap(result.first);
      }

      return null;
    } catch (e) {
      print('❌ Error getting active firm: $e');
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
      // 1️⃣ Check if firm is active
      final firm = await getFirmById(id);

      if (firm == null) {
        throw Exception('Firm not found');
      }

      if (firm.active) {
        throw Exception('सक्रिय फर्म हटवू शकत नाही');
      }

      // 2️⃣ Optional: Prevent deleting last firm
      final count = await getFirmCount();
      if (count <= 1) {
        throw Exception('किमान एक फर्म असणे आवश्यक आहे');
      }

      // 3️⃣ Delete
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

  // Firm को active करा (एक वेळी एकच active असू शकतो)
  static Future<void> setActiveFirm(String firmId) async {
    try {
      // First make all firms inactive
      await powerSyncDB.execute(
        'UPDATE firms SET active = 0',
      );

      // Then activate selected firm
      await powerSyncDB.execute(
        'UPDATE firms SET active = 1 WHERE id = ?',
        [firmId],
      );
    } catch (e) {
      print('❌ Error setting active firm: $e');
      rethrow;
    }
  }
}
