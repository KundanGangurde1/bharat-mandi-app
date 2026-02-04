import 'dart:io';

import 'package:powersync/powersync.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

late PowerSyncDatabase powerSyncDB;

Future<void> initPowerSync() async {
  final dbDir = await getDatabasesPath();
  final dir = Directory(dbDir);

  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final dbPath = join(dbDir, 'powersync.db');

  final schema = Schema([
    // FARMERS
    Table('farmers', [
      Column.text('code'),
      Column.text('name'),
      Column.text('phone'),
      Column.text('address'),
      Column.real('opening_balance'),
      Column.integer('active'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ]),

    // TRADERS
    Table('traders', [
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

    // PRODUCE
    Table('produce', [
      Column.text('code'),
      Column.text('name'),
      Column.text('variety'),
      Column.text('category'),
      Column.integer('active'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ]),

    // TRANSACTIONS
    Table('transactions', [
      Column.integer('parchi_id'),
      Column.text('farmer_code'),
      Column.text('farmer_name'),
      Column.text('trader_code'),
      Column.text('trader_name'),
      Column.text('produce_code'),
      Column.text('produce_name'),
      Column.real('dag'),
      Column.real('quantity'),
      Column.real('rate'),
      Column.real('gross'),
      Column.real('total_expense'),
      Column.real('net'),
      Column.text('created_at'),
    ]),
  ]);

  powerSyncDB = PowerSyncDatabase(
    schema: schema,
    path: dbPath,
  );

  await powerSyncDB.initialize();
}
