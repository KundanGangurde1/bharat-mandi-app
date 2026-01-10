import 'package:flutter/material.dart';
import '../../core/services/db_service.dart';
import '../../core/utils/app_localizations.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final db = await DBService.database;
    final data = await db.query('transactions', orderBy: 'id DESC');
    setState(() => transactions = data);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text("Report")),
      body: transactions.isEmpty
          ? const Center(child: Text("No data"))
          : ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (_, i) {
                final tx = transactions[i];
                return ListTile(
                  title: Text("₹ ${tx['net']}"),
                  subtitle: Text(tx['created_at']),
                );
              },
            ),
    );
  }
}
