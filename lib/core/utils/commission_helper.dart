import '../services/powersync_service.dart';

/// ✅ SIMPLIFIED Commission Helper - Two-Tap System
/// TAP A: Produce-Specific Commission (PER_PRODUCE)
/// TAP B: Default Commission from Expense Type (DEFAULT)

class CommissionHelper {
  /// ✅ Get commission for a produce row
  ///
  /// This function determines which commission to apply:
  /// - TAP A: If produce has commission_type = 'PER_PRODUCE', use produce commission
  /// - TAP B: If produce has commission_type = 'DEFAULT', use expense type "कमिशन"
  static Future<double> getCommissionForProduce({
    required String produceCode,
    required double itemAmount,
    required String applyOn, // 'farmer' or 'buyer'
    required String firmId,
  }) async {
    try {
      // Get produce commission details
      final produceData = await powerSyncDB.getAll(
        '''SELECT commission_type, commission_value, commission_apply_on 
           FROM produce 
           WHERE firm_id = ? AND code = ?''',
        [firmId, produceCode],
      );

      if (produceData.isEmpty) {
        print('⚠️ Produce not found: $produceCode');
        return 0;
      }

      final produce = produceData.first;
      final commissionType = produce['commission_type'] ?? 'DEFAULT';

      // ===== TAP A: PRODUCE-SPECIFIC COMMISSION =====
      if (commissionType == 'PER_PRODUCE') {
        final commissionApplyOn = produce['commission_apply_on'];

        // Check if this commission applies to the requested entity
        if (commissionApplyOn != applyOn) {
          return 0;
        }

        final commissionValue =
            (produce['commission_value'] as num?)?.toDouble();
        if (commissionValue == null || commissionValue <= 0) {
          print('⚠️ Commission value not set for $produceCode');
          return 0;
        }

        final commissionAmount = (itemAmount * commissionValue) / 100;
        print(
            '🔴 TAP A: Produce Commission ($produceCode): $commissionValue% on $applyOn = ₹$commissionAmount');

        return commissionAmount;
      }

      // ===== TAP B: DEFAULT COMMISSION FROM EXPENSE TYPE =====
      else if (commissionType == 'DEFAULT') {
        return await _getDefaultCommission(
          itemAmount: itemAmount,
          applyOn: applyOn,
          firmId: firmId,
        );
      }

      return 0;
    } catch (e) {
      print('❌ Error getting commission: $e');
      return 0;
    }
  }

  /// ✅ Get default commission from "कमिशन" expense type
  /// This is used when produce.commission_type = 'DEFAULT'
  static Future<double> _getDefaultCommission({
    required double itemAmount,
    required String applyOn,
    required String firmId,
  }) async {
    try {
      // Get "कमिशन" expense from expense_types
      final commissionExpense = await powerSyncDB.getAll(
        '''SELECT commission, default_value, calculation_type, apply_on 
           FROM expense_types 
           WHERE firm_id = ? AND name = ? AND active = 1''',
        [firmId, 'कमिशन'],
      );

      if (commissionExpense.isEmpty) {
        print('ℹ️ कमिशन expense not found for firm: $firmId');
        return 0;
      }

      final row = commissionExpense.first;
      final applyOnType = (row['apply_on']?.toString() ?? '').trim();

      // Check if commission applies to this entity
      if (applyOnType.isNotEmpty && applyOnType != applyOn) {
        return 0;
      }

      // Get commission percentage
      double commission = (row['commission'] as num?)?.toDouble() ?? 0;

      // Fallback: if commission is 0, try default_value
      if (commission <= 0) {
        final calcType = (row['calculation_type']?.toString() ?? '').trim();
        final defaultValue = (row['default_value'] as num?)?.toDouble() ?? 0;

        if (calcType == 'percentage' && defaultValue > 0) {
          commission = defaultValue;
          print('ℹ️ Using कमिशन default_value: $commission%');
        }
      }

      if (commission <= 0) {
        print('ℹ️ कमिशन expense has no commission value set');
        return 0;
      }

      final commissionAmount = (itemAmount * commission) / 100;
      print(
          '🟢 TAP B: Default Commission (कमिशन): $commission% on $applyOn = ₹$commissionAmount');

      return commissionAmount;
    } catch (e) {
      print('❌ Error getting default commission: $e');
      return 0;
    }
  }

  /// ✅ Check if produce has per-produce commission
  static Future<bool> hasPerProduceCommission({
    required String produceCode,
    required String firmId,
  }) async {
    try {
      final data = await powerSyncDB.getAll(
        'SELECT commission_type FROM produce WHERE firm_id = ? AND code = ?',
        [firmId, produceCode],
      );

      if (data.isEmpty) return false;
      return data.first['commission_type'] == 'PER_PRODUCE';
    } catch (e) {
      print('❌ Error checking per-produce commission: $e');
      return false;
    }
  }

  /// ✅ Get commission type for a produce
  static Future<String> getCommissionType({
    required String produceCode,
    required String firmId,
  }) async {
    try {
      final data = await powerSyncDB.getAll(
        'SELECT commission_type FROM produce WHERE firm_id = ? AND code = ?',
        [firmId, produceCode],
      );

      if (data.isEmpty) return 'DEFAULT';
      return data.first['commission_type'] ?? 'DEFAULT';
    } catch (e) {
      print('❌ Error getting commission type: $e');
      return 'DEFAULT';
    }
  }
}
