import 'package:bharat_mandi/core/services/firm_data_service.dart';
import 'package:bharat_mandi/core/services/powersync_service.dart';

class InitializationService {
  static const List<Map<String, dynamic>> _defaultExpenseTypes = [
    {
      'name': 'कमिशन',
      'apply_on': 'buyer',
      'calculation_type': 'percentage',
      'default_value': 0.0,
      'commission': 0.0,
    },
    {
      'name': 'हमाली',
      'apply_on': 'farmer',
      'calculation_type': 'pavti_nusar',
      'default_value': 0.0,
      'commission': 0.0,
    },
    {
      'name': 'वाराई',
      'apply_on': 'farmer',
      'calculation_type': 'pavti_nusar',
      'default_value': 0.0,
      'commission': 0.0,
    },
    {
      'name': 'आडत',
      'apply_on': 'farmer',
      'calculation_type': 'pavti_nusar',
      'default_value': 0.0,
      'commission': 0.0,
    },
    {
      'name': 'इतर खर्च',
      'apply_on': 'farmer',
      'calculation_type': 'pavti_nusar',
      'default_value': 0.0,
      'commission': 0.0,
    },
    {
      'name': 'मो . भाडे',
      'apply_on': 'farmer',
      'calculation_type': 'pavti_nusar',
      'default_value': 0.0,
      'commission': 0.0,
    },
    {
      'name': 'इनाम',
      'apply_on': 'farmer',
      'calculation_type': 'pavti_nusar',
      'default_value': 0.0,
      'commission': 0.0,
    },
  ];

  static String _normalizeName(String? name) {
    return (name ?? '').replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }

  /// ✅ Initialize default data on app startup
  static Future<void> initializeDefaultData() async {
    try {
      final firmId = await FirmDataService.getActiveFirmId();

      if (firmId == null) {
        print('⚠️ No active firm set. Skipping initialization.');
        return;
      }

      final now = DateTime.now().toIso8601String();
      final existingRows = await powerSyncDB.getAll(
        'SELECT id, name FROM expense_types WHERE firm_id = ?',
        [firmId],
      );

      final existingByName = <String, String>{};
      for (final row in existingRows) {
        final name = row['name']?.toString();
        final id = row['id']?.toString();
        if (name != null && id != null) {
          existingByName[_normalizeName(name)] = id;
        }
      }
      for (final expense in _defaultExpenseTypes) {
        final normalizedName = _normalizeName(expense['name'] as String);

        if (existingByName.containsKey(normalizedName)) {
          print('ℹ️ Default expense already exists: ${expense['name']}');
          continue;
        }

        final record = {
          ...expense,
          'active': 1,
          'show_in_report': 1,
          'created_at': now,
          'updated_at': now,
        };

        await insertRecord('expense_types', record);
        print(
            '✅ Default expense created: ${expense['name']} for firm: $firmId');
      }
    } catch (e) {
      print('❌ Error initializing default data: $e');
    }
  }
}
