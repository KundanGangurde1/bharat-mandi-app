import 'package:bharat_mandi/core/services/firm_data_service.dart';
import 'package:bharat_mandi/core/services/powersync_service.dart';

class InitializationService {
  /// ✅ Initialize default data on app startup
  static Future<void> initializeDefaultData() async {
    try {
      final firmId = await FirmDataService.getActiveFirmId();

      if (firmId == null) {
        print('⚠️ No active firm set. Skipping initialization.');
        return;
      }

      // Check if default "कमिशन" expense already exists
      final existingCommission = await powerSyncDB.getAll(
        'SELECT id FROM expense_types WHERE firm_id = ? AND name = ?',
        [firmId, 'कमिशन'],
      );

      if (existingCommission.isEmpty) {
        // Create default "कमिशन" expense using insertRecord (which auto-generates id)
        final now = DateTime.now().toIso8601String();

        final defaultCommission = {
          'firm_id': firmId,
          'name': 'कमिशन',
          'apply_on': 'buyer',
          'calculation_type': 'percentage',
          'default_value': 0.0,
          'commission': 0.0,
          'active': 1,
          'show_in_report': 1,
          'created_at': now,
          'updated_at': now,
        };

        // ✅ Use insertRecord which auto-generates id
        await insertRecord('expense_types', defaultCommission);

        print('✅ Default कमिशन expense created for firm: $firmId');
      } else {
        print('ℹ️ Default कमिशन expense already exists for firm: $firmId');
      }
    } catch (e) {
      print('❌ Error initializing default data: $e');
    }
  }
}
