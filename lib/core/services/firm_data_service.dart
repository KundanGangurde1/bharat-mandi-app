import 'package:powersync/powersync.dart';
import '../../core/services/powersync_service.dart';

/// ✅ Production Ready Firm Data Service
/// Uses DB active = 1 (NO Provider, NO BuildContext)

class FirmDataService {
  // ================= ACTIVE FIRM =================

  static Future<String?> getActiveFirmId() async {
    try {
      final data = await powerSyncDB.getAll(
        'SELECT id FROM firms WHERE active = 1 LIMIT 1',
      );

      if (data.isNotEmpty) {
        return data.first['id'] as String?;
      }
      return null;
    } catch (e) {
      print('❌ Error getting active firm id: $e');
      return null;
    }
  }

  // ================= FARMERS =================

  static Future<List<Map<String, dynamic>>> getFarmersForActiveFirm() async {
    final firmId = await getActiveFirmId();
    if (firmId == null) return [];

    return await powerSyncDB.getAll(
      'SELECT * FROM farmers WHERE firm_id = ? ORDER BY name ASC',
      [firmId],
    );
  }

  static Future<Map<String, dynamic>?> getFarmerByCodeForActiveFirm(
      String code) async {
    final firmId = await getActiveFirmId();
    if (firmId == null) return null;

    final data = await powerSyncDB.getAll(
      'SELECT * FROM farmers WHERE firm_id = ? AND code = ?',
      [firmId, code],
    );

    return data.isNotEmpty ? data.first : null;
  }

  // ================= BUYERS =================

  static Future<List<Map<String, dynamic>>> getBuyersForActiveFirm() async {
    final firmId = await getActiveFirmId();
    if (firmId == null) return [];

    return await powerSyncDB.getAll(
      'SELECT * FROM buyers WHERE firm_id = ? ORDER BY name ASC',
      [firmId],
    );
  }

  static Future<Map<String, dynamic>?> getBuyerByCodeForActiveFirm(
      String code) async {
    final firmId = await getActiveFirmId();
    if (firmId == null) return null;

    final data = await powerSyncDB.getAll(
      'SELECT * FROM buyers WHERE firm_id = ? AND code = ?',
      [firmId, code],
    );

    return data.isNotEmpty ? data.first : null;
  }

  // ================= PRODUCE =================

  static Future<List<Map<String, dynamic>>> getProduceForActiveFirm() async {
    final firmId = await getActiveFirmId();
    if (firmId == null) return [];

    return await powerSyncDB.getAll(
      'SELECT * FROM produce WHERE firm_id = ? ORDER BY name ASC',
      [firmId],
    );
  }

  static Future<Map<String, dynamic>?> getProduceByCodeForActiveFirm(
      String code) async {
    final firmId = await getActiveFirmId();
    if (firmId == null) return null;

    final data = await powerSyncDB.getAll(
      'SELECT * FROM produce WHERE firm_id = ? AND code = ?',
      [firmId, code],
    );

    return data.isNotEmpty ? data.first : null;
  }

  // ================= AREAS =================

  static Future<List<Map<String, dynamic>>> getAreasForActiveFirm() async {
    final firmId = await getActiveFirmId();
    if (firmId == null) return [];

    return await powerSyncDB.getAll(
      'SELECT * FROM areas WHERE firm_id = ? ORDER BY name ASC',
      [firmId],
    );
  }

  // ================= EXPENSE TYPES =================

  static Future<List<Map<String, dynamic>>>
      getExpenseTypesForActiveFirm() async {
    final firmId = await getActiveFirmId();
    if (firmId == null) return [];

    return await powerSyncDB.getAll(
      'SELECT * FROM expense_types WHERE firm_id = ? ORDER BY name ASC',
      [firmId],
    );
  }

  // ================= TRANSACTIONS =================

  static Future<List<Map<String, dynamic>>>
      getTransactionsForActiveFirm() async {
    final firmId = await getActiveFirmId();
    if (firmId == null) return [];

    return await powerSyncDB.getAll(
      'SELECT * FROM transactions WHERE firm_id = ? ORDER BY created_at DESC',
      [firmId],
    );
  }

  // ================= PAYMENTS =================

  static Future<List<Map<String, dynamic>>> getPaymentsForActiveFirm() async {
    final firmId = await getActiveFirmId();
    if (firmId == null) return [];

    return await powerSyncDB.getAll(
      'SELECT * FROM payments WHERE firm_id = ? ORDER BY created_at DESC',
      [firmId],
    );
  }

  // ================= INSERT WITH firm_id =================

  static Future<void> insertRecordWithFirmId(
    String table,
    Map<String, dynamic> data,
  ) async {
    final firmId = await getActiveFirmId();
    if (firmId == null) {
      throw Exception('No active firm selected');
    }

    data['firm_id'] = firmId;
    await insertRecord(table, data);
  }

  // ================= UPDATE BALANCES =================

  static Future<void> updateBuyerBalanceForActiveFirm(
    String buyerCode,
    double newBalance,
  ) async {
    final firmId = await getActiveFirmId();
    if (firmId == null) {
      throw Exception('No active firm selected');
    }

    await powerSyncDB.execute(
      'UPDATE buyers SET opening_balance = ?, updated_at = ? WHERE firm_id = ? AND code = ?',
      [newBalance, DateTime.now().toIso8601String(), firmId, buyerCode],
    );
  }

  static Future<void> updateFarmerBalanceForActiveFirm(
    String farmerCode,
    double newBalance,
  ) async {
    final firmId = await getActiveFirmId();
    if (firmId == null) {
      throw Exception('No active firm selected');
    }

    await powerSyncDB.execute(
      'UPDATE farmers SET opening_balance = ?, updated_at = ? WHERE firm_id = ? AND code = ?',
      [newBalance, DateTime.now().toIso8601String(), firmId, farmerCode],
    );
  }

  // ================= COUNT =================

  static Future<int> getCountForActiveFirm(String table) async {
    final firmId = await getActiveFirmId();
    if (firmId == null) return 0;

    final result = await powerSyncDB.getAll(
      'SELECT COUNT(*) as count FROM $table WHERE firm_id = ?',
      [firmId],
    );

    if (result.isNotEmpty) {
      return (result.first['count'] as int?) ?? 0;
    }

    return 0;
  }
}
