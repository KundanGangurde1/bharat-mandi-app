import '../services/firm_data_service.dart';
import '../services/powersync_service.dart';

/// ✅ Centralized validation helper to eliminate code duplication
/// Used by: farmer_form_screen, buyer_form_screen, produce_form_screen
class ValidationHelper {
  /// Check if a code is unique for the active firm
  /// 
  /// Parameters:
  /// - code: The code to check
  /// - tableName: The table to check in (farmers, buyers, produces)
  /// - excludeId: Optional ID to exclude (for edit mode)
  /// 
  /// Returns: true if code is unique, false if already exists
  static Future<bool> isCodeUnique(
    String code,
    String tableName, {
    String? excludeId,
  }) async {
    try {
      final firmId = await FirmDataService.getActiveFirmId();
      if (firmId == null) {
        throw Exception('No active firm found');
      }

      // Build query with optional exclude clause
      String query =
          'SELECT COUNT(*) as count FROM $tableName WHERE firm_id = ? AND code = ?';
      List<dynamic> params = [firmId, code];

      if (excludeId != null && excludeId.isNotEmpty) {
        query += ' AND id != ?';
        params.add(excludeId);
      }

      final result = await powerSyncDB.getAll(query, params);

      // Code is unique if count is 0
      return result.isEmpty || (result[0]['count'] as int) == 0;
    } catch (e) {
      print('❌ Error checking code uniqueness: $e');
      rethrow;
    }
  }

  /// Check if a code is used in transactions
  /// 
  /// Parameters:
  /// - code: The code to check
  /// - tableName: The table name (farmers, buyers)
  /// - codeColumnName: The column name to check (farmer_code, buyer_code)
  /// 
  /// Returns: true if code is used, false if not used
  static Future<bool> isCodeUsedInTransactions(
    String code,
    String tableName,
    String codeColumnName,
  ) async {
    try {
      final firmId = await FirmDataService.getActiveFirmId();
      if (firmId == null) {
        throw Exception('No active firm found');
      }

      final query =
          'SELECT COUNT(*) as count FROM transactions WHERE firm_id = ? AND $codeColumnName = ?';
      final result = await powerSyncDB.getAll(query, [firmId, code]);

      // Code is used if count > 0
      return result.isNotEmpty && (result[0]['count'] as int) > 0;
    } catch (e) {
      print('❌ Error checking if code is used: $e');
      rethrow;
    }
  }

  /// Validate that a code is not reserved
  /// 
  /// Reserved codes:
  /// - Farmers: '100'
  /// - Buyers: 'R' (for Rokda/Cash)
  /// 
  /// Returns: null if valid, error message if reserved
  static String? validateReservedCode(String code, String tableName) {
    final upperCode = code.trim().toUpperCase();

    if (tableName == 'farmers' && upperCode == '100') {
      return '100 कोड रिझर्व्हड आहे';
    }

    if (tableName == 'buyers' && upperCode == 'R') {
      return 'R कोड रिझर्व्हड आहे (Rokda साठी)';
    }

    return null;
  }

  /// Validate code format (alphanumeric only)
  /// 
  /// Returns: null if valid, error message if invalid
  static String? validateCodeFormat(String code) {
    if (code.trim().isEmpty) {
      return 'कोड आवश्यक आहे';
    }

    final upperCode = code.trim().toUpperCase();

    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(upperCode)) {
      return 'फक्त अक्षरे आणि अंक वापरा';
    }

    return null;
  }

  /// Validate name field
  /// 
  /// Returns: null if valid, error message if invalid
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'नाव आवश्यक आहे';
    }
    return null;
  }

  /// Validate numeric balance field
  /// 
  /// Returns: null if valid, error message if invalid
  static String? validateBalance(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Balance is optional
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'योग्य रक्कम प्रविष्ट करा';
    }

    return null;
  }

  /// Validate phone number (optional, but if provided should be numeric)
  /// 
  /// Returns: null if valid, error message if invalid
  static String? validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return null; // Phone is optional
    }

    if (!RegExp(r'^[0-9\-\+\s]+$').hasMatch(phone)) {
      return 'योग्य फोन नंबर प्रविष्ट करा';
    }

    return null;
  }

  /// Get active firm ID with error handling
  /// 
  /// Returns: firmId if available, throws exception if not
  static Future<String> getActiveFirmIdOrThrow() async {
    final firmId = await FirmDataService.getActiveFirmId();
    if (firmId == null) {
      throw Exception('कोणताही सक्रिय फर्म नाही');
    }
    return firmId;
  }
}
