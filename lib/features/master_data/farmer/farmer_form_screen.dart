import 'package:flutter/material.dart';
import '../../../core/services/powersync_service.dart';
import '../../../core/services/firm_data_service.dart'; // ✅ NEW

class FarmerFormScreen extends StatefulWidget {
  final String? farmerId;

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
  bool isCodeUsed = false;
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
      // ✅ NEW: Get farmer by ID for active firm
      final firmId = await FirmDataService.getActiveFirmId();
      if (firmId == null) {
        throw Exception('No active firm found');
      }

      final data = await powerSyncDB.getAll(
        'SELECT * FROM farmers WHERE firm_id = ? AND id = ?',
        [firmId, widget.farmerId],
      );

      if (data.isNotEmpty) {
        farmerData = data.first;

        codeCtrl.text = farmerData!['code']?.toString() ?? '';
        nameCtrl.text = farmerData!['name']?.toString() ?? '';
        phoneCtrl.text = farmerData!['phone']?.toString() ?? '';
        addressCtrl.text = farmerData!['address']?.toString() ?? '';
        balanceCtrl.text = farmerData!['opening_balance']?.toString() ?? '0';

        // ✅ FIXED: Reuse firmId instead of fetching again
        final isUsedResult = await powerSyncDB.getAll(
          'SELECT COUNT(*) as count FROM transactions WHERE firm_id = ? AND farmer_code = ?',
          [firmId, farmerData!['code']?.toString() ?? ''],
        );

        final isUsed =
            isUsedResult.isNotEmpty && (isUsedResult[0]['count'] as int) > 0;

        setState(() {
          isCodeUsed = isUsed;
        });
      }
    } catch (e) {
      print('❌ Error loading farmer: $e');
      print('⚠️ Check if active firm is set');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटी: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveFarmer() async {
    if (!_formKey.currentState!.validate()) return;

    final code = codeCtrl.text.trim().toUpperCase();

    // Validate code uniqueness (except for edit mode with same code)
    if (!isEditMode || code != farmerData?['code']) {
      try {
        // ✅ FIXED: Get firm_id once at the start
        final firmId = await FirmDataService.getActiveFirmId();
        if (firmId == null) {
          throw Exception('No active firm found');
        }
        final uniqueResult = await powerSyncDB.getAll(
          'SELECT COUNT(*) as count FROM farmers WHERE firm_id = ? AND code = ?',
          [firmId, code],
        );

        final isUnique =
            uniqueResult.isEmpty || (uniqueResult[0]['count'] as int) == 0;

        if (!isUnique) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('हा कोड आधीच वापरात आहे')),
            );
          }
          return;
        }
      } catch (e) {
        print('❌ Error checking code uniqueness: $e');
        print('⚠️ Check if active firm is set');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('कोड तपासणीमध्ये त्रुटी: $e')),
          );
        }
        return;
      }
    }

    // Check for reserved code
    if (code == '100') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('100 कोड रिझर्व्हड आहे')),
        );
      }
      return;
    }

    setState(() => isLoading = true);

    try {
      final now = DateTime.now().toIso8601String();

      final farmer = {
        'code': code,
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'opening_balance': double.tryParse(balanceCtrl.text) ?? 0,
        'active': 1,
        'updated_at': now,
      };

      if (isEditMode) {
        // PowerSync: Update farmer
        farmer['updated_at'] = now;
        await updateRecord('farmers', widget.farmerId!, farmer);

        print('✅ Farmer updated successfully');
      } else {
        // ✅ NEW: Insert new farmer with firm_id
        farmer['created_at'] = now;
        farmer['active'] = 1;
        await FirmDataService.insertRecordWithFirmId('farmers', farmer);

        print('✅ Farmer created successfully with firm_id');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode ? 'शेतकरी अपडेट झाला' : 'शेतकरी जोडला गेला',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Error saving farmer: $e');
      print('⚠️ Check if active firm is set');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटी: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  String? _validateCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'कोड आवश्यक आहे';
    }

    final code = value.trim().toUpperCase();

    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(code)) {
      return 'फक्त अक्षरे आणि अंक वापरा';
    }

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
      return null;
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
                      readOnly: isEditMode && isCodeUsed,
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
