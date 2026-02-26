import 'powersync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MigrationService {
  static final supabase = Supabase.instance.client;

  static Future<void> migrateLocalToCloud() async {
    final tables = [
      'firms',
      'farmers',
      'buyers',
      'produce',
      'expense_types',
      'transactions',
      'transaction_expenses',
      'payments',
      'areas',
    ];

    for (final table in tables) {
      final localData = await getAllRecords(table);

      for (final row in localData) {
        await supabase.from(table).upsert(row); // SAFE (no duplicates)
      }

      print('✅ Migrated: $table');
    }

    print('🔥 Migration complete');
  }
}
