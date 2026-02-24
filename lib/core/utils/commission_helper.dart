import '../services/powersync_service.dart';

class CommissionHelper {
  /// ✅ METHOD 1: Apply commission from PRODUCE table (TAP A - PER_PRODUCE)
  /// Used when produce.commission_type = 'PER_PRODUCE'
  static Future<double> applyProduceCommission({
    required String produceCode,
    required double itemAmount,
    required String applyOn, // 'farmer' or 'buyer'
    required String firmId,
  }) async {
    try {
      // Get produce details
      final produceData = await powerSyncDB.getAll(
        'SELECT commission_type, commission_value, commission_apply_on FROM produce WHERE firm_id = ? AND code = ?',
        [firmId, produceCode],
      );

      if (produceData.isEmpty) {
        print('⚠️ Produce not found: $produceCode');
        return 0;
      }

      final produce = produceData.first;
      final commissionType = produce['commission_type'] ?? 'DEFAULT';

      // Only process if PER_PRODUCE
      if (commissionType != 'PER_PRODUCE') {
        print('ℹ️ Produce $produceCode is not PER_PRODUCE type');
        return 0;
      }

      // Check if applies to this applyOn
      final commissionApplyOn = produce['commission_apply_on'];
      if (commissionApplyOn != applyOn) {
        print('ℹ️ Commission not applicable for $applyOn on $produceCode');
        return 0;
      }

      // Get commission value
      final commissionValue = (produce['commission_value'] as num?)?.toDouble();
      if (commissionValue == null || commissionValue <= 0) {
        print('⚠️ Commission value not set for $produceCode');
        return 0;
      }

      final commissionAmount = (itemAmount * commissionValue) / 100;
      print(
          '🔴 TAP A: Produce Commission applied: $produceCode ($commissionValue%) on $applyOn = ₹$commissionAmount');

      return commissionAmount;
    } catch (e) {
      print('❌ Error applying produce commission: $e');
      return 0;
    }
  }

  /// ✅ METHOD 2: Apply commission from EXPENSE_TYPES table (TAP B - DEFAULT)
  /// Used when produce.commission_type = 'DEFAULT'
  /// Only applies "कमिशन" expense commission
  static Future<double> applyExpenseTypeCommission({
    required double itemAmount,
    required String applyOn, // 'farmer' or 'buyer'
    required String firmId,
  }) async {
    try {
      // Get "कमिशन" expense from expense_types
      final commissionExpense = await powerSyncDB.getAll(
        'SELECT commission, default_value, calculation_type, apply_on FROM expense_types WHERE firm_id = ? AND name = ? AND active = 1',
        [firmId, 'कमिशन'],
      );

      if (commissionExpense.isEmpty) {
        print('ℹ️ कमिशन expense not found for firm: $firmId');
        return 0;
      }

      final row = commissionExpense.first;
      final applyOnType = (row['apply_on']?.toString() ?? '').trim();
      if (applyOnType.isNotEmpty && applyOnType != applyOn) {
        return 0;
      }

      double commission = (row['commission'] as num?)?.toDouble() ?? 0;

      // Fallback: many setups store % in default_value for कमिशन.
      if (commission <= 0) {
        final calcType = (row['calculation_type']?.toString() ?? '').trim();
        final defaultValue = (row['default_value'] as num?)?.toDouble() ?? 0;
        if (calcType == 'percentage' && defaultValue > 0) {
          commission = defaultValue;
          print('ℹ️ Using कमिशन default_value as %: $commission');
        }
      }

      if (commission <= 0) {
        print('ℹ️ कमिशन expense has no commission value set');
        return 0;
      }

      final commissionAmount = (itemAmount * commission) / 100;
      print(
          '🟢 TAP B: Expense Type Commission (कमिशन) applied: ($commission%) on $applyOn = ₹$commissionAmount');

      return commissionAmount;
    } catch (e) {
      print('❌ Error applying expense type commission: $e');
      return 0;
    }
  }

  /// Check if a produce has per-produce commission
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

  /// Get commission details for a produce
  static Future<Map<String, dynamic>?> getCommissionDetails({
    required String produceCode,
    required String firmId,
  }) async {
    try {
      final data = await powerSyncDB.getAll(
        '''SELECT 
          commission_type, 
          commission_value, 
          commission_apply_on
        FROM produce 
        WHERE firm_id = ? AND code = ?''',
        [firmId, produceCode],
      );

      if (data.isEmpty) return null;

      return data.first;
    } catch (e) {
      print('❌ Error getting commission details: $e');
      return null;
    }
  }
}
