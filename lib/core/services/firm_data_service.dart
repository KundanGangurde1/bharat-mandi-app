import 'package:powersync/powersync.dart';
import '../../features/firm_setup/firm_service.dart';
import 'powersync_service.dart';

/// ✅ Helper service to fetch data filtered by active firm
/// This ensures data isolation - each firm only sees its own data
class FirmDataService {
  /// Get active firm ID
  static Future<String?> getActiveFirmId() async {
    try {
      final firm = await FirmService.getActiveFirm();
      return firm?.id;
    } catch (e) {
      print('❌ Error getting active firm: $e');
      return null;
    }
  }

  // ============ FARMERS ============

  /// Get all farmers for active firm
  static Future<List<Map<String, dynamic>>> getFarmersForActiveFirm() async {
    try {
      final firmId = await getActiveFirmId();
      if (firmId == null) {
        print('⚠️ No active firm found');
        return [];
      }

      final data = await powerSyncDB.getAll(
        'SELECT * FROM farmers WHERE firm_id = ? ORDER BY name ASC',
        [firmId],
      );

      return data;
    } catch (e) {
      print('❌ Error loading farmers: $e');
      return [];
    }
  }

  /// Get farmer by code for active firm
  static Future<Map<String, dynamic>?> getFarmerByCodeForActiveFirm(
      String code) async {
    try {
      final firmId = await getActiveFirmId();
      if (firmId == null) {
        print('⚠️ No active firm found');
        return null;
      }

      final data = await powerSyncDB.getAll(
        'SELECT * FROM farmers WHERE firm_id = ? AND code = ?',
        [firmId, code],
      );

      if (data.isNotEmpty) {
        return data.first;
      }
      return null;
    } catch (e) {
      print('❌ Error loading farmer: $e');
      return null;
    }
  }

  // ============ BUYERS ============

  /// Get all buyers for active firm
  static Future<List<Map<String, dynamic>>> getBuyersForActiveFirm() async {
    try {
      final firmId = await getActiveFirmId();
      if (firmId == null) {
        print('⚠️ No active firm found');
        return [];
      }

      final data = await powerSyncDB.getAll(
        'SELECT * FROM buyers WHERE firm_id = ? ORDER BY name ASC',
        [firmId],
      );

      return data;
    } catch (e) {
      print('❌ Error loading buyers: $e');
      return [];
    }
  }

  /// Get buyer by code for active firm
  static Future<Map<String, dynamic>?> getBuyerByCodeForActiveFirm(
      String code) async {
    try {
      final firmId = await getActiveFirmId();
      if (firmId == null) {
        print('⚠️ No active firm found');
        return null;
      }

      final data = await powerSyncDB.getAll(
        'SELECT * FROM buyers WHERE firm_id = ? AND code = ?',
        [firmId, code],
      );

      if (data.isNotEmpty) {
        return data.first;
      }
      return null;
    } catch (e) {
      print('❌ Error loading buyer: $e');
      return null;
    }
  }

  // ============ PRODUCE ============

  /// Get all produce for active firm
  static Future<List<Map<String, dynamic>>> getProduceForActiveFirm() async {
    try {
      final firmId = await getActiveFirmId();
      if (firmId == null) {
        print('⚠️ No active firm found');
        return [];
      }

      final data = await powerSyncDB.getAll(
        'SELECT * FROM produce WHERE firm_id = ? ORDER BY name ASC',
        [firmId],
      );

      return data;
    } catch (e) {
      print('❌ Error loading produce: $e');
      return [];
    }
  }

  /// Get produce by code for active firm
  static Future<Map<String, dynamic>?> getProduceByCodeForActiveFirm(
      String code) async {
    try {
      final firmId = await getActiveFirmId();
      if (firmId == null) {
        print('⚠️ No active firm found');
        return null;
      }

      final data = await powerSyncDB.getAll(
        'SELECT * FROM produce WHERE firm_id = ? AND code = ?',
        [firmId, code],
      );

      if (data.isNotEmpty) {
        return data.first;
      }
      return null;
    } catch (e) {
      print('❌ Error loading produce: $e');
      return null;
    }
  }

  // ============ AREAS ============

  /// Get all areas for active firm
  static Future<List<Map<String, dynamic>>> getAreasForActiveFirm() async {
    try {
      final firmId = await getActiveFirmId();
      if (firmId == null) {
        print('⚠️ No active firm found');
        return [];
      }

      final data = await powerSyncDB.getAll(
        'SELECT * FROM areas WHERE firm_id = ? ORDER BY name ASC',
        [firmId],
      );

      return data;
    } catch (e) {
      print('❌ Error loading areas: $e');
      return [];
    }
  }

  // ============ EXPENSE TYPES ============

  /// Get all expense types for active firm
  static Future<List<Map<String, dynamic>>>
      getExpenseTypesForActiveFirm() async {
    try {
      final firmId = await getActiveFirmId();
      if (firmId == null) {
        print('⚠️ No active firm found');
        return [];
      }

      final data = await powerSyncDB.getAll(
        'SELECT * FROM expense_types WHERE firm_id = ? ORDER BY name ASC',
        [firmId],
      );

      return data;
    } catch (e) {
      print('❌ Error loading expense types: $e');
      return [];
    }
  }

  // ============ TRANSACTIONS ============

  /// Get all transactions for active firm
  static Future<List<Map<String, dynamic>>>
      getTransactionsForActiveFirm() async {
    try {
      final firmId = await getActiveFirmId();
      if (firmId == null) {
        print('⚠️ No active firm found');
        return [];
      }

      final data = await powerSyncDB.getAll(
        'SELECT * FROM transactions WHERE firm_id = ? ORDER BY created_at DESC',
        [firmId],
      );

      return data;
    } catch (e) {
      print('❌ Error loading transactions: $e');
      return [];
    }
  }

  // ============ PAYMENTS ============

  /// Get all payments for active firm
  static Future<List<Map<String, dynamic>>> getPaymentsForActiveFirm() async {
    try {
      final firmId = await getActiveFirmId();
      if (firmId == null) {
        print('⚠️ No active firm found');
        return [];
      }

      final data = await powerSyncDB.getAll(
        'SELECT * FROM payments WHERE firm_id = ? ORDER BY created_at DESC',
        [firmId],
      );

      return data;
    } catch (e) {
      print('❌ Error loading payments: $e');
      return [];
    }
  }

  // ============ INSERT WITH FIRM_ID ============

  /// Insert record with active firm_id
  static Future<void> insertRecordWithFirmId(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final firmId = await getActiveFirmId();
      if (firmId == null) {
        throw Exception('No active firm found');
      }

      data['firm_id'] = firmId;
      await insertRecord(table, data);
    } catch (e) {
      print('❌ Error inserting record: $e');
      rethrow;
    }
  }

  // ============ UPDATE BALANCES ============

  /// Update buyer balance for active firm
  static Future<void> updateBuyerBalanceForActiveFirm(
    String buyerCode,
    double newBalance,
  ) async {
    try {
      final firmId = await getActiveFirmId();
      if (firmId == null) {
        throw Exception('No active firm found');
      }

      await powerSyncDB.execute(
        'UPDATE buyers SET opening_balance = ?, updated_at = ? WHERE firm_id = ? AND code = ?',
        [newBalance, DateTime.now().toIso8601String(), firmId, buyerCode],
      );
    } catch (e) {
      print('❌ Error updating buyer balance: $e');
      rethrow;
    }
  }

  /// Update farmer balance for active firm
  static Future<void> updateFarmerBalanceForActiveFirm(
    String farmerCode,
    double newBalance,
  ) async {
    try {
      final firmId = await getActiveFirmId();
      if (firmId == null) {
        throw Exception('No active firm found');
      }

      await powerSyncDB.execute(
        'UPDATE farmers SET opening_balance = ?, updated_at = ? WHERE firm_id = ? AND code = ?',
        [newBalance, DateTime.now().toIso8601String(), firmId, farmerCode],
      );
    } catch (e) {
      print('❌ Error updating farmer balance: $e');
      rethrow;
    }
  }

  // ============ COUNT METHODS ============

  /// Get count of farmers for active firm
  static Future<int> getFarmerCountForActiveFirm() async {
    try {
      final firmId = await getActiveFirmId();
      if (firmId == null) return 0;

      final result = await powerSyncDB.getAll(
        'SELECT COUNT(*) as count FROM farmers WHERE firm_id = ?',
        [firmId],
      );

      if (result.isNotEmpty) {
        return (result.first['count'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      print('❌ Error getting farmer count: $e');
      return 0;
    }
  }

  /// Get count of buyers for active firm
  static Future<int> getBuyerCountForActiveFirm() async {
    try {
      final firmId = await getActiveFirmId();
      if (firmId == null) return 0;

      final result = await powerSyncDB.getAll(
        'SELECT COUNT(*) as count FROM buyers WHERE firm_id = ?',
        [firmId],
      );

      if (result.isNotEmpty) {
        return (result.first['count'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      print('❌ Error getting buyer count: $e');
      return 0;
    }
  }

  /// Get count of transactions for active firm
  static Future<int> getTransactionCountForActiveFirm() async {
    try {
      final firmId = await getActiveFirmId();
      if (firmId == null) return 0;

      final result = await powerSyncDB.getAll(
        'SELECT COUNT(*) as count FROM transactions WHERE firm_id = ?',
        [firmId],
      );

      if (result.isNotEmpty) {
        return (result.first['count'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      print('❌ Error getting transaction count: $e');
      return 0;
    }
  }

  /// Get count of payments for active firm
  static Future<int> getPaymentCountForActiveFirm() async {
    try {
      final firmId = await getActiveFirmId();
      if (firmId == null) return 0;

      final result = await powerSyncDB.getAll(
        'SELECT COUNT(*) as count FROM payments WHERE firm_id = ?',
        [firmId],
      );

      if (result.isNotEmpty) {
        return (result.first['count'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      print('❌ Error getting payment count: $e');
      return 0;
    }
  }
}
