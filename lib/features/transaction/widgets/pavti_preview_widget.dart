import 'package:flutter/material.dart';

class PavtiPreviewWidget extends StatelessWidget {
  final Map<String, dynamic>? firm;
  final String parchiId;
  final String farmerName;
  final String farmerCode;
  final String date;
  final List<Map<String, dynamic>> rows;
  final double totalAmount;
  final double totalExpense;
  final double netAmount;

  const PavtiPreviewWidget({
    super.key,
    required this.firm,
    required this.parchiId,
    required this.farmerName,
    required this.farmerCode,
    required this.date,
    required this.rows,
    required this.totalAmount,
    required this.totalExpense,
    required this.netAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Firm Header
            Center(
              child: Column(
                children: [
                  Text(
                    firm?['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(firm?['owner_name'] ?? ''),
                  Text('मोबाइल: ${firm?['phone'] ?? ''}'),
                ],
              ),
            ),

            const Divider(thickness: 1),

            Text('पावती नं: $parchiId'),
            Text('तारीख: $date'),
            Text('शेतकरी: $farmerName ($farmerCode)'),

            const Divider(thickness: 1),

            const Text(
              'व्यापारी | माल | वजन | भाव | रक्कम',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            ...rows.map((r) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(r['buyer_name'] ?? '')),
                    Expanded(child: Text(r['produce_name'] ?? '')),
                    Expanded(child: Text(r['quantity'].toString())),
                    Expanded(child: Text(r['rate'].toString())),
                    Expanded(
                      child: Text(
                        '₹${r['gross'].toString()}',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Divider(thickness: 1),

            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('एकूण रक्कम: ₹$totalAmount'),
                  Text('खर्च: ₹$totalExpense'),
                  Text(
                    'शुद्ध रक्कम: ₹$netAmount',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
