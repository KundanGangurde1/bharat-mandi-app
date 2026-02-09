import 'powersync_service.dart';

class PowerSyncRepo {
  static Future<void> insertFarmer({
    required String code,
    required String name,
    String? phone,
    String? address,
  }) async {
    await powerSyncDB.execute(
      '''
      INSERT INTO farmers
      (code, name, phone, address, active, created_at, updated_at)
      VALUES (?, ?, ?, ?, 1, datetime('now'), datetime('now'))
      ''',
      [code, name, phone, address],
    );
  }

  static Future<void> insertBuyer({
    required String code,
    required String name,
  }) async {
    await powerSyncDB.execute(
      '''
      INSERT INTO buyers
      (code, name, active, created_at, updated_at)
      VALUES (?, ?, 1, datetime('now'), datetime('now'))
      ''',
      [code, name],
    );
  }

  static Future<void> insertTransaction({
    required int parchiId,
    required String farmerCode,
    required String buyerCode,
    required String produceCode,
    required double quantity,
    required double rate,
  }) async {
    await powerSyncDB.execute(
      '''
      INSERT INTO transactions
      (parchi_id, farmer_code, buyer_code, produce_code,
       quantity, rate, created_at)
      VALUES (?, ?, ?, ?, ?, ?, datetime('now'))
      ''',
      [parchiId, farmerCode, buyerCode, produceCode, quantity, rate],
    );
  }
}
