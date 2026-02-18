import '../services/powersync_service.dart';
import '../services/firm_data_service.dart';

/// ✅ Dashboard helper to fetch today's summary data
class DashboardHelper {
  /// Get today's summary data for dashboard
  ///
  /// Returns:
  /// - paymentCount: Number of payments entered today
  /// - creditSales: Total credit sales (उधार विक्री)
  /// - cashSales: Total cash sales (रोखा विक्री)
  /// - totalTransactions: Total sales amount (credit + cash)
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

      // Query 1: Count payments entered today (एकुण पावती)
      final paymentCountResult = await powerSyncDB.getAll(
        '''SELECT COUNT(*) as count FROM payments 
           WHERE firm_id = ? AND created_at >= ? AND created_at < ?''',
        [firmId, startStr, endStr],
      );
      final paymentCount = paymentCountResult.isNotEmpty
          ? paymentCountResult[0]['count'] as int
          : 0;

      // Query 2: Credit sales today (उधार विक्री)
      final creditSalesResult = await powerSyncDB.getAll(
        '''SELECT IFNULL(SUM(net), 0) as total FROM transactions 
           WHERE firm_id = ? AND buyer_code != 'R' AND created_at >= ? AND created_at < ?''',
        [firmId, startStr, endStr],
      );
      final creditSales = (creditSalesResult.isNotEmpty
                  ? creditSalesResult[0]['total'] as num?
                  : 0)
              ?.toDouble() ??
          0.0;

      // Query 3: Cash sales today (रोखा विक्री)
      final cashSalesResult = await powerSyncDB.getAll(
        '''SELECT IFNULL(SUM(net), 0) as total FROM transactions 
           WHERE firm_id = ? AND buyer_code = 'R' AND created_at >= ? AND created_at < ?''',
        [firmId, startStr, endStr],
      );
      final cashSales =
          (cashSalesResult.isNotEmpty ? cashSalesResult[0]['total'] as num? : 0)
                  ?.toDouble() ??
              0.0;

      // Query 4: Total payment amount today (आजची वसूली)
      final paymentAmountResult = await powerSyncDB.getAll(
        '''SELECT IFNULL(SUM(amount), 0) as total FROM payments 
           WHERE firm_id = ? AND created_at >= ? AND created_at < ?''',
        [firmId, startStr, endStr],
      );
      final paymentAmount = (paymentAmountResult.isNotEmpty
                  ? paymentAmountResult[0]['total'] as num?
                  : 0)
              ?.toDouble() ??
          0.0;

      // Total transactions = credit + cash
      final totalTransactions = creditSales + cashSales;

      return {
        'paymentCount': paymentCount,
        'creditSales': creditSales,
        'cashSales': cashSales,
        'totalTransactions': totalTransactions,
        'paymentAmount': paymentAmount,
      };
    } catch (e) {
      print('❌ Error getting today\'s summary: $e');
      return {
        'paymentCount': 0,
        'creditSales': 0.0,
        'cashSales': 0.0,
        'totalTransactions': 0.0,
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
