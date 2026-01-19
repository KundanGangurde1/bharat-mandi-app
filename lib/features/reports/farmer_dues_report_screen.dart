import 'package:flutter/material.dart';
import '../../core/services/db_service.dart';

class FarmerDuesReportScreen extends StatefulWidget {
  const FarmerDuesReportScreen({super.key});

  @override
  State<FarmerDuesReportScreen> createState() => _FarmerDuesReportScreenState();
}

class _FarmerDuesReportScreenState extends State<FarmerDuesReportScreen> {
  List<Map<String, dynamic>> farmers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFarmerDues();
  }

  Future<void> _loadFarmerDues() async {
    try {
      final data = await DBService.getFarmerDues();
      setState(() {
        farmers = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading farmer dues: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('शेतकरी थकबाकी यादी')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : farmers.isEmpty
              ? const Center(child: Text('कोणतीही थकबाकी नाही'))
              : ListView.builder(
                  itemCount: farmers.length,
                  itemBuilder: (context, index) {
                    final farmer = farmers[index];
                    final dues = farmer['dues'] as double? ?? 0.0;

                    return ListTile(
                      title: Text(farmer['name'].toString()),
                      subtitle: Text('फोन: ${farmer['phone'] ?? 'N/A'}'),
                      trailing: Text(
                        '₹${dues.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: dues > 0 ? Colors.red : Colors.green,
                        ),
                      ),
                      onTap: () {
                        // पुढे डिटेल्स स्क्रीन बनवू (transactions list)
                      },
                    );
                  },
                ),
    );
  }
}
