import '../services/powersync_service.dart';
import '../services/firm_data_service.dart';

/// ✅ Dashboard helper to fetch today's summary data
class DashboardHelper {
  /// Get today's summary data for dashboard
  ///
  /// Returns:
  /// - parchiCount: Number of transaction entries created today (एकुण पावती)
  /// - creditSales: Total credit sales (आजची थकबाकी)
  /// - cashSales: Total cash sales (आजची रोखविक्री)
  /// - totalSales: Total sales amount (आजचा व्यापार)
  /// - paymentCount: Number of payment entries created today (एकुण जमा पावती)
  /// - paymentAmount: Total payment amount (आजची वसूली)
  static Future<Map<String, dynamic>> getTodaysSummary() async {
    try {
      final firmId = await FirmDataService.getActiveFirmId();
      if (firmId == null) {
        throw Exception('No active firm found');
      }

      // Get today's date range
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final startStr = startOfDay.toIso8601String();
      final endStr = endOfDay.toIso8601String();

      print('📊 Dashboard Helper - Fetching data for firm: $firmId');
      print('📅 Date range: $startStr to $endStr');

      // Query 1: Count PARCHI entries today (एकुण पावती)
      // Count distinct parchi_id (unique parchi entries) created today
      final parchiCountResult = await powerSyncDB.getAll(
        '''SELECT COUNT(DISTINCT parchi_id) as count FROM transactions 
           WHERE firm_id = ? AND created_at >= ? AND created_at < ?''',
        [firmId, startStr, endStr],
      );
      final parchiCount = parchiCountResult.isNotEmpty
          ? parchiCountResult[0]['count'] as int
          : 0;
      print('✅ Parchi Count (एकुण पावती): $parchiCount');

      // Query 2: Credit sales today (आजची थकबाकी)
      // Sum of transactions where buyer_code != 'R'
      final creditSalesResult = await powerSyncDB.getAll(
        '''SELECT IFNULL(SUM(CAST(net AS REAL)), 0) as total FROM transactions 
           WHERE firm_id = ? AND buyer_code != 'R' AND created_at >= ? AND created_at < ?''',
        [firmId, startStr, endStr],
      );
      final creditSales = (creditSalesResult.isNotEmpty
                  ? creditSalesResult[0]['total'] as num?
                  : 0)
              ?.toDouble() ??
          0.0;
      print('✅ Credit Sales (आजची थकबाकी): ₹$creditSales');

      // Query 3: Cash sales today (आजची रोखविक्री)
      // Sum of transactions where buyer_code = 'R'
      final cashSalesResult = await powerSyncDB.getAll(
        '''SELECT IFNULL(SUM(CAST(net AS REAL)), 0) as total FROM transactions 
           WHERE firm_id = ? AND buyer_code = 'R' AND created_at >= ? AND created_at < ?''',
        [firmId, startStr, endStr],
      );
      final cashSales =
          (cashSalesResult.isNotEmpty ? cashSalesResult[0]['total'] as num? : 0)
                  ?.toDouble() ??
              0.0;
      print('✅ Cash Sales (आजची रोखविक्री): ₹$cashSales');

      // Query 4: Total sales (आजचा व्यापार)
      final totalSales = creditSales + cashSales;
      print('✅ Total Sales (आजचा व्यापार): ₹$totalSales');

      // Query 5: Count payment entries today (एकुण जमा पावती)
      // Count distinct payment records created today
      final paymentCountResult = await powerSyncDB.getAll(
        '''SELECT COUNT(DISTINCT id) as count FROM payments 
           WHERE firm_id = ? AND created_at >= ? AND created_at < ?''',
        [firmId, startStr, endStr],
      );
      final paymentCount = paymentCountResult.isNotEmpty
          ? paymentCountResult[0]['count'] as int
          : 0;
      print('✅ Payment Count (एकुण जमा पावती): $paymentCount');

      // Query 6: Total payment amount (आजची वसूली)
      // Sum of payment amounts created today
      final paymentAmountResult = await powerSyncDB.getAll(
        '''SELECT IFNULL(SUM(CAST(amount AS REAL)), 0) as total FROM payments 
           WHERE firm_id = ? AND created_at >= ? AND created_at < ?''',
        [firmId, startStr, endStr],
      );
      final paymentAmount = (paymentAmountResult.isNotEmpty
                  ? paymentAmountResult[0]['total'] as num?
                  : 0)
              ?.toDouble() ??
          0.0;
      print('✅ Payment Amount (आजची वसूली): ₹$paymentAmount');

      print(
          '📊 Dashboard Summary: Parchi=$parchiCount, Credit=₹$creditSales, Cash=₹$cashSales, Total=₹$totalSales, PaymentCount=$paymentCount, PaymentAmount=₹$paymentAmount');

      return {
        'parchiCount': parchiCount,
        'creditSales': creditSales,
        'cashSales': cashSales,
        'totalSales': totalSales,
        'paymentCount': paymentCount,
        'paymentAmount': paymentAmount,
      };
    } catch (e) {
      print('❌ Error getting today\'s summary: $e');
      return {
        'parchiCount': 0,
        'creditSales': 0.0,
        'cashSales': 0.0,
        'totalSales': 0.0,
        'paymentCount': 0,
        'paymentAmount': 0.0,
      };
    }
  }

  /// Format currency for display
  static String formatCurrency(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }

  /// Format currency with full amount
  static String formatCurrencyFull(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }
}
