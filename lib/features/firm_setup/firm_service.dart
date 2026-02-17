import '../../core/services/powersync_service.dart';
import 'firm_model.dart';

class FirmService {
  static const String tableName = 'firms';

  /// ✅ Add new firm with proper activation logic
  /// - If it's the first firm, auto-activate it
  /// - Otherwise, keep it inactive (user will activate from settings)
  static Future<String> addFirm(Firm firm) async {
    try {
      final String firmId =
          firm.id ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Check if this is the first firm
      final count = await getFirmCount();
      final shouldActivate = count == 0; // Auto-activate first firm

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
        'active': shouldActivate ? 1 : 0, // ✅ Auto-activate first firm
        'created_at': firm.created_at,
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ Firm added: $firmId (active: $shouldActivate)');
      return firmId;
    } catch (e) {
      print('❌ Error adding firm: $e');
      rethrow;
    }
  }

  /// Get all firms
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

  /// Get specific firm by ID
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

  /// ✅ Get active firm (only one should have active = 1)
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

  /// Update firm details
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

  /// Delete firm (only if not active)
  static Future<void> deleteFirm(String id) async {
    try {
      // 1️⃣ Check if firm is active
      final firm = await getFirmById(id);

      if (firm == null) {
        throw Exception('फर्म मिळाले नाही');
      }

      if (firm.active) {
        throw Exception('सक्रिय फर्म हटवू शकत नाही');
      }

      // 2️⃣ Prevent deleting last firm
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

  /// Deactivate firm (soft delete)
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

  /// Get firm count
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

  /// ✅ Set active firm (only one active at a time)
  /// - Deactivates all other firms
  /// - Activates the selected firm
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

      print('✅ Active firm set to: $firmId');
    } catch (e) {
      print('❌ Error setting active firm: $e');
      rethrow;
    }
  }
}
