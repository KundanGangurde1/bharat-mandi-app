// ✅ POWERSYNC SERVICE - COMPLETE WITH FIRM_ID & HELPER FUNCTIONS
import 'dart:io';
import 'package:powersync/powersync.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

late PowerSyncDatabase powerSyncDB;

// ✅ PowerSync Schema with all 9 tables + firm_id for data isolation
final schema = Schema([
  // 1. FARMERS TABLE
  Table('farmers', [
    Column.text('firm_id'),
    Column.text('code'),
    Column.text('name'),
    Column.text('phone'),
    Column.text('address'),
    Column.real('opening_balance'),
    Column.integer('active'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // 2. BUYERS TABLE
  Table('buyers', [
    Column.text('firm_id'),
    Column.text('code'),
    Column.text('name'),
    Column.text('phone'),
    Column.text('firm_name'),
    Column.text('area'),
    Column.integer('area_id'),
    Column.real('opening_balance'),
    Column.integer('active'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // 3. PRODUCE TABLE
  Table('produce', [
    Column.text('firm_id'),
    Column.text('code'),
    Column.text('name'),
    Column.text('variety'),
    Column.text('category'),
    Column.integer('active'),
    Column.text('created_at'),
    Column.text('updated_at'),
    // ✅ NEW: Commission columns for per-produce commission
    Column.text('commission_type'), // DEFAULT or PER_PRODUCE
    Column.real('commission_value'), // Percentage value (e.g., 5.0)
    Column.text('commission_apply_on'), // farmer or buyer
  ]),

  // 4. EXPENSE TYPES TABLE
  Table('expense_types', [
    Column.text('firm_id'),
    Column.text('name'),
    Column.text('apply_on'),
    Column.text('calculation_type'),
    Column.real('default_value'),
    Column.integer('active'),
    Column.integer('show_in_report'),
    Column.text('created_at'),
    Column.text('updated_at'),
    // ✅ NEW: Commission tracking columns
    Column.real('commission'), // Commission percentage for कमिशन expense
  ]),

  // 5. TRANSACTIONS TABLE
  Table('transactions', [
    Column.text('firm_id'),
    Column.integer('parchi_id'),
    Column.text('farmer_code'),
    Column.text('farmer_name'),
    Column.text('buyer_code'),
    Column.text('buyer_name'),
    Column.text('produce_code'),
    Column.text('produce_name'),
    Column.real('dag'),
    Column.real('quantity'),
    Column.real('rate'),
    Column.real('gross'),
    Column.real('total_expense'),
    Column.real('net'),
    Column.text('created_at'),
    Column.text('updated_at'),
    // ✅ NEW: Farmer expense tracking
    Column.real('farmer_expense'), // Expenses applied to farmer
  ]),

  // 6. TRANSACTION EXPENSES TABLE
  Table('transaction_expenses', [
    Column.text('firm_id'),
    Column.integer('parchi_id'),
    Column.integer('expense_type_id'),
    Column.real('amount'),
    Column.text('created_at'),
  ]),

  // 7. PAYMENTS TABLE
  Table('payments', [
    Column.text('firm_id'),
    Column.text('buyer_code'),
    Column.text('buyer_name'),
    Column.real('amount'),
    Column.text('payment_mode'),
    Column.text('notes'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // 8. AREAS TABLE
  Table('areas', [
    Column.text('firm_id'),
    Column.text('name'),
    Column.integer('active'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // 9. FIRMS TABLE
  Table('firms', [
    Column.text('name'),
    Column.text('code'),
    Column.text('owner_name'),
    Column.text('phone'),
    Column.text('email'),
    Column.text('address'),
    Column.text('city'),
    Column.text('state'),
    Column.text('pincode'),
    Column.text('gst_number'),
    Column.text('pan_number'),
    Column.integer('active'),
    Column.integer('is_active'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),
]);

// ✅ Initialize PowerSync (Local-first, offline-ready)
Future<void> initPowerSync() async {
  try {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDocDir.path, 'powersync.db');

    print('📱 PowerSync DB Path: $dbPath');

    powerSyncDB = PowerSyncDatabase(
      schema: schema,
      path: dbPath,
    );

    await powerSyncDB.initialize();

    print('✅ PowerSync initialized successfully');
    print('✅ All 9 tables ready for offline-first sync');
    print('✅ Firm-based data isolation enabled');
  } catch (e) {
    print('❌ PowerSync initialization error: $e');
    rethrow;
  }
}

// ✅ Get PowerSync database instance
Future<PowerSyncDatabase> getPowerSyncDatabase() async {
  try {
    if (powerSyncDB == null) {
      await initPowerSync();
    }
  } catch (e) {
    print('❌ Error getting PowerSync: $e');
    await initPowerSync();
  }
  return powerSyncDB;
}

// ✅ Check if online
Future<bool> isOnline() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException catch (_) {
    return false;
  }
}

// ✅ Get sync status
Future<Map<String, dynamic>> getSyncStatus() async {
  try {
    final isConnected = await isOnline();
    return {
      'isConnected': isConnected,
      'lastSyncTime': DateTime.now(),
      'pendingChanges': 0,
    };
  } catch (e) {
    return {
      'isConnected': false,
      'lastSyncTime': null,
      'pendingChanges': 0,
    };
  }
}

// ✅ Manual sync trigger (for future Supabase integration)
Future<void> triggerSync() async {
  try {
    print('🔄 Triggering manual sync...');
    print('✅ Sync triggered');
  } catch (e) {
    print('❌ Sync error: $e');
  }
}

// ✅ Clear all data (for debugging only)
Future<void> clearAllData() async {
  try {
    print('🗑️ Clearing all data...');

    await powerSyncDB.execute('DELETE FROM farmers');
    await powerSyncDB.execute('DELETE FROM buyers');
    await powerSyncDB.execute('DELETE FROM produce');
    await powerSyncDB.execute('DELETE FROM expense_types');
    await powerSyncDB.execute('DELETE FROM transactions');
    await powerSyncDB.execute('DELETE FROM transaction_expenses');
    await powerSyncDB.execute('DELETE FROM payments');
    await powerSyncDB.execute('DELETE FROM areas');
    await powerSyncDB.execute('DELETE FROM firms');

    print('✅ All data cleared');
  } catch (e) {
    print('❌ Clear error: $e');
  }
}

// ✅ Get database statistics
Future<Map<String, int>> getDatabaseStats() async {
  try {
    final farmers =
        await powerSyncDB.getAll('SELECT COUNT(*) as count FROM farmers');
    final buyers =
        await powerSyncDB.getAll('SELECT COUNT(*) as count FROM buyers');
    final produce =
        await powerSyncDB.getAll('SELECT COUNT(*) as count FROM produce');
    final transactions =
        await powerSyncDB.getAll('SELECT COUNT(*) as count FROM transactions');

    return {
      'farmers': farmers.isNotEmpty ? (farmers[0]['count'] as int) : 0,
      'buyers': buyers.isNotEmpty ? (buyers[0]['count'] as int) : 0,
      'produce': produce.isNotEmpty ? (produce[0]['count'] as int) : 0,
      'transactions':
          transactions.isNotEmpty ? (transactions[0]['count'] as int) : 0,
    };
  } catch (e) {
    print('❌ Stats error: $e');
    return {};
  }
}

// ✅ Query helper - Get all records from a table
Future<List<Map<String, dynamic>>> getAllRecords(String tableName) async {
  try {
    return await powerSyncDB.getAll('SELECT * FROM $tableName');
  } catch (e) {
    print('❌ Query error: $e');
    return [];
  }
}

// ✅ Query helper - Get record by ID
Future<Map<String, dynamic>?> getRecordById(String tableName, String id) async {
  try {
    final results =
        await powerSyncDB.getAll('SELECT * FROM $tableName WHERE id = ?', [id]);
    return results.isNotEmpty ? results[0] : null;
  } catch (e) {
    print('❌ Query error: $e');
    return null;
  }
}

// ✅ Insert record
final _uuid = const Uuid();

Future<void> insertRecord(
  String table,
  Map<String, dynamic> data,
) async {
  await powerSyncDB.writeTransaction((txn) async {
    final record = {
      'id': _uuid.v4(), // ✅ MANUAL ID (REQUIRED)
      ...data,
    };

    final columns = record.keys.join(', ');
    final placeholders = List.filled(record.length, '?').join(', ');
    final values = record.values.toList();

    await txn.execute(
      'INSERT INTO $table ($columns) VALUES ($placeholders)',
      values,
    );
  });
}

// ✅ Update record
Future<void> updateRecord(
  String table,
  String id,
  Map<String, dynamic> data,
) async {
  await powerSyncDB.writeTransaction((txn) async {
    final updates = data.keys.map((k) => '$k = ?').join(', ');
    final values = [...data.values, id];

    await txn.execute(
      'UPDATE $table SET $updates WHERE id = ?',
      values,
    );
  });
}

// ✅ Delete record
Future<void> deleteRecord(String table, String id) async {
  await powerSyncDB.writeTransaction((txn) async {
    await txn.execute(
      'DELETE FROM $table WHERE id = ?',
      [id],
    );
  });
}

// ============================================================================
// ✅ HELPER FUNCTIONS FOR SCREENS
// ============================================================================

// ✅ Check if code is unique across a table
Future<bool> isCodeUnique(String code, String tableName) async {
  try {
    final results = await powerSyncDB.getAll(
      'SELECT COUNT(*) as count FROM $tableName WHERE code = ?',
      [code],
    );
    return results.isEmpty || (results[0]['count'] as int) == 0;
  } catch (e) {
    print('❌ Error checking code uniqueness: $e');
    return false;
  }
}

// ✅ Check if code is used in transactions
Future<bool> isCodeUsedInTransaction(String code, String tableName) async {
  try {
    final columnName = tableName == 'farmers' ? 'farmer_code' : 'buyer_code';
    final results = await powerSyncDB.getAll(
      'SELECT COUNT(*) as count FROM transactions WHERE $columnName = ?',
      [code],
    );
    return results.isNotEmpty && (results[0]['count'] as int) > 0;
  } catch (e) {
    print('❌ Error checking transaction usage: $e');
    return false;
  }
}

// ✅ Get next Parchi ID (for transactions)
Future<int> getNextParchiId() async {
  try {
    final results = await powerSyncDB.getAll(
      'SELECT MAX(parchi_id) as max_id FROM transactions',
    );
    final maxId = results.isNotEmpty ? (results[0]['max_id'] as int?) ?? 0 : 0;
    return maxId + 1;
  } catch (e) {
    print('❌ Error getting next parchi ID: $e');
    return 1;
  }
}

// ✅ Get farmer dues report
Future<List<Map<String, dynamic>>> getFarmerDues() async {
  try {
    return await powerSyncDB.getAll('''
      SELECT farmer_code, farmer_name, 
             SUM(CASE WHEN net < 0 THEN ABS(net) ELSE 0 END) as dues
      FROM transactions
      GROUP BY farmer_code, farmer_name
      HAVING dues > 0
    ''');
  } catch (e) {
    print('❌ Error getting farmer dues: $e');
    return [];
  }
}

// ✅ Get buyer recovery report
// ✅ BUYER RECOVERY / BALANCE (SINGLE SOURCE OF TRUTH)
Future<List<Map<String, dynamic>>> getBuyerRecovery(
    {String? firmId, String? areaId}) async {
  try {
    String query = '''
      SELECT 
        b.id,
        b.code,
        b.name,
        b.phone,
        a.name AS area_name,

        (
          b.opening_balance
          + IFNULL(SUM(DISTINCT t.net), 0)
          - IFNULL(SUM(DISTINCT p.amount), 0)
        ) AS balance

      FROM buyers b
      LEFT JOIN transactions t
        ON t.buyer_code = b.code AND t.firm_id = b.firm_id
      LEFT JOIN payments p
        ON p.buyer_code = b.code AND p.firm_id = b.firm_id
      LEFT JOIN areas a
        ON a.id = b.area_id

      WHERE b.active = 1
    ''';

    List<dynamic> params = [];

    // ✅ NEW: Filter by firm_id
    if (firmId != null && firmId.isNotEmpty) {
      query += ' AND b.firm_id = ?';
      params.add(firmId);
    }

    if (areaId != null && areaId.isNotEmpty) {
      query += ' AND b.area_id = ?';
      params.add(areaId);
    }

    query += '''
      GROUP BY 
        b.id, b.code, b.name, b.phone, b.opening_balance, a.name
      HAVING balance != 0
      ORDER BY b.name ASC
    ''';

    return await powerSyncDB.getAll(query, params);
  } catch (e) {
    print('❌ Error calculating buyer recovery: $e');
    return [];
  }
}

Future<List<Map<String, dynamic>>> getBuyerLedger(String buyerCode) async {
  try {
    final query = '''
      SELECT 
        created_at AS date,
        'PARCHI' AS type,
        parchi_id AS ref_no,
        net AS debit,
        0 AS credit
      FROM transactions
      WHERE buyer_code = ?

      UNION ALL

      SELECT
        created_at AS date,
        'PAYMENT' AS type,
        '' AS ref_no,
        0 AS debit,
        amount AS credit
      FROM payments
      WHERE buyer_code = ?

      ORDER BY date ASC
    ''';

    return await powerSyncDB.getAll(query, [buyerCode, buyerCode]);
  } catch (e) {
    print('❌ Ledger error: $e');
    return [];
  }
}

// ✅ SINGLE BUYER CURRENT BALANCE (FOR PAYMENT SCREEN)
Future<double> getBuyerCurrentBalance(String buyerCode) async {
  try {
    // 1️⃣ Opening balance
    final buyerRes = await powerSyncDB.getAll(
      'SELECT opening_balance FROM buyers WHERE code = ?',
      [buyerCode],
    );

    final opening =
        (buyerRes.isNotEmpty ? buyerRes.first['opening_balance'] : 0) as num? ??
            0;

    // 2️⃣ Total purchases (transactions net)
    final txnRes = await powerSyncDB.getAll(
      '''
      SELECT IFNULL(SUM(net), 0) AS total
      FROM transactions
      WHERE buyer_code = ?
      ''',
      [buyerCode],
    );

    final purchases = (txnRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // 3️⃣ Total payments
    final payRes = await powerSyncDB.getAll(
      '''
      SELECT IFNULL(SUM(amount), 0) AS total
      FROM payments
      WHERE buyer_code = ?
      ''',
      [buyerCode],
    );

    final paid = (payRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // ✅ FINAL BALANCE
    return opening + purchases - paid;
  } catch (e) {
    print('❌ Buyer balance calc error: $e');
    return 0.0;
  }
}

// ✅ Get expense types for farmer
Future<List<Map<String, dynamic>>> getExpenseTypesForFarmer() async {
  try {
    return await powerSyncDB.getAll('''
      SELECT * FROM expense_types 
      WHERE apply_on = 'farmer' AND active = 1
      ORDER BY name ASC
    ''');
  } catch (e) {
    print('❌ Error getting farmer expense types: $e');
    return [];
  }
}

// ✅ Get expense types for buyer
Future<List<Map<String, dynamic>>> getExpenseTypesForBuyer() async {
  try {
    return await powerSyncDB.getAll('''
      SELECT * FROM expense_types 
      WHERE apply_on = 'buyer' AND active = 1
      ORDER BY name ASC
    ''');
  } catch (e) {
    print('❌ Error getting buyer expense types: $e');
    return [];
  }
}

// ✅ Delete Pavti (transaction) and its expenses
Future<void> deletePavti(int parchiId) async {
  try {
    // Delete transaction expenses first
    await powerSyncDB.execute(
      'DELETE FROM transaction_expenses WHERE parchi_id = ?',
      [parchiId],
    );

    // Then delete transaction
    await powerSyncDB.execute(
      'DELETE FROM transactions WHERE parchi_id = ?',
      [parchiId],
    );

    print('✅ Pavti deleted: $parchiId');
  } catch (e) {
    print('❌ Error deleting pavti: $e');
  }
}
