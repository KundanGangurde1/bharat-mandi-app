import '../services/powersync_service.dart';
import '../services/firm_data_service.dart';

/// ✅ Initialization Service
/// Handles automatic setup of default data on app startup
class InitializationService {
  /// Initialize default data for the active firm
  static Future<void> initializeDefaultData() async {
    try {
      final firmId = await FirmDataService.getActiveFirmId();
      if (firmId == null || firmId.isEmpty) {
        print('⚠️ No active firm set');
        return;
      }

      print('🔄 Initializing default data for firm: $firmId');

      // Create default commission expense if not exists
      await _createDefaultCommissionExpense(firmId);

      print('✅ Default data initialization complete');
    } catch (e) {
      print('❌ Error during initialization: $e');
    }
  }

  /// Create default commission expense type if it doesn't exist
  static Future<void> _createDefaultCommissionExpense(String firmId) async {
    try {
      // Check if default commission expense already exists
      final existing = await powerSyncDB.getAll(
        'SELECT id FROM expense_types WHERE firm_id = ? AND is_default = 1 LIMIT 1',
        [firmId],
      );

      if (existing.isNotEmpty) {
        print('✅ Default commission expense already exists');
        return;
      }

      // Create default commission expense
      final now = DateTime.now().toIso8601String();
      final defaultExpense = {
        'id': 'exp_default_${firmId}_${DateTime.now().millisecondsSinceEpoch}',
        'firm_id': firmId,
        'name': 'कमिशन',
        'apply_on': 'buyer',
        'calculation_type': 'percentage',
        'default_value': 7.0,
        'active': 1,
        'show_in_report': 1,
        'is_commission': 1,
        'is_default': 1,
        'created_at': now,
        'updated_at': now,
      };

      // Insert into database
      await insertRecord('expense_types', defaultExpense);
      print('✅ Default commission expense created: कमिशन (7%)');
    } catch (e) {
      print('❌ Error creating default commission expense: $e');
      // Don't throw - let app continue even if this fails
    }
  }
}
