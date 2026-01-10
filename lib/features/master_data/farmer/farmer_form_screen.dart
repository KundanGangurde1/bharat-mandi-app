import 'package:flutter/material.dart';
import '../../../core/services/db_service.dart';

class FarmerFormScreen extends StatefulWidget {
  final int? farmerId;

  const FarmerFormScreen({super.key, this.farmerId});

  @override
  State<FarmerFormScreen> createState() => _FarmerFormScreenState();
}

class _FarmerFormScreenState extends State<FarmerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final codeCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final balanceCtrl = TextEditingController();

  bool isLoading = false;
  bool isEditMode = false;
  bool isCodeUsed = false; // Store if code is used in transactions
  Map<String, dynamic>? farmerData;

  @override
  void initState() {
    super.initState();
    isEditMode = widget.farmerId != null;

    if (isEditMode) {
      _loadFarmerData();
    } else {
      balanceCtrl.text = '0';
    }
  }

  Future<void> _loadFarmerData() async {
    setState(() => isLoading = true);

    try {
      final db = await DBService.database;
      final data = await db.query(
        'farmers',
        where: 'id = ?',
        whereArgs: [widget.farmerId],
      );

      if (data.isNotEmpty) {
        farmerData = data.first;

        codeCtrl.text = farmerData!['code']?.toString() ?? '';
        nameCtrl.text = farmerData!['name']?.toString() ?? '';
        phoneCtrl.text = farmerData!['phone']?.toString() ?? '';
        addressCtrl.text = farmerData!['address']?.toString() ?? '';
        balanceCtrl.text = farmerData!['opening_balance']?.toString() ?? '0';

        // Check if code is used in transactions
        final isUsed = await DBService.isCodeUsedInTransaction(
            farmerData!['code']?.toString() ?? '', 'farmers');

        setState(() {
          isCodeUsed = isUsed;
        });
      }
    } catch (e) {
      print("Error loading farmer: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveFarmer() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate code uniqueness (except for edit mode with same code)
    final code = codeCtrl.text.trim().toUpperCase();

    if (!isEditMode || code != farmerData?['code']) {
      final isUnique = await DBService.isCodeUnique(code);
      if (!isUnique) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('हा कोड आधीच वापरात आहे'),
          ),
        );
        return;
      }
    }

    // Check for reserved code
    if (code == '100') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('100 कोड रिझर्व्हड आहे'),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final db = await DBService.database;
      final now = DateTime.now().toIso8601String();

      final farmer = {
        'code': code,
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'opening_balance': double.tryParse(balanceCtrl.text) ?? 0,
        'updated_at': now,
      };

      if (isEditMode) {
        await db.update(
          'farmers',
          farmer,
          where: 'id = ?',
          whereArgs: [widget.farmerId],
        );
      } else {
        farmer['created_at'] = now;
        await db.insert('farmers', farmer);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode ? 'शेतकरी अपडेट झाला' : 'शेतकरी जोडला गेला',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      print("Error saving farmer: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('त्रुटी: $e'),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  String? _validateCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'कोड आवश्यक आहे';
    }

    final code = value.trim().toUpperCase();

    // Check for invalid characters
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(code)) {
      return 'फक्त अक्षरे आणि अंक वापरा';
    }

    // Check for reserved code
    if (code == '100') {
      return '100 कोड रिझर्व्हड आहे';
    }

    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'नाव आवश्यक आहे';
    }
    return null;
  }

  String? _validateBalance(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'योग्य रक्कम प्रविष्ट करा';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode ? 'शेतकरी एडिट करा' : 'नवीन शेतकरी',
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Code Field
                    TextFormField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'शेतकरी कोड *',
                        hintText: 'KM, AJJU, etc.',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.code),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: _validateCode,
                      readOnly:
                          isEditMode && isCodeUsed, // FIXED: No await here
                    ),
                    const SizedBox(height: 16),

                    // Name Field
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'शेतकरी नाव *',
                        hintText: 'पूर्ण नाव',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 16),

                    // Phone Field
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'फोन नंबर',
                        hintText: '10 अंकी नंबर',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                    ),
                    const SizedBox(height: 16),

                    // Address Field
                    TextFormField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'पत्ता',
                        hintText: 'गाव, तालुका, जिल्हा',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Opening Balance Field
                    TextFormField(
                      controller: balanceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ओपनिंग बॅलन्स',
                        hintText: '0',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_wallet),
                        suffixText: '₹',
                      ),
                      keyboardType: TextInputType.number,
                      validator: _validateBalance,
                    ),

                    const SizedBox(height: 24),

                    // Info Text
                    Card(
                      color: Colors.blue[50],
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'महत्वाचे माहिती:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text('• कोड 100 रिझर्व्हड आहे (नवीन शेतकरीसाठी)'),
                            Text('• कोड कायमस्वरूपी असतो'),
                            Text('• कोड डुप्लिकेट असू शकत नाही'),
                            Text('• कोड अंकीय किंवा अक्षरी असू शकतो'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _saveFarmer,
                        icon: const Icon(Icons.save),
                        label: Text(
                          isLoading ? 'सेव होत आहे...' : 'सेव करा',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    codeCtrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    balanceCtrl.dispose();
    super.dispose();
  }
}
