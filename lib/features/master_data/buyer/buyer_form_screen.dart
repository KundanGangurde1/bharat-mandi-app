import 'package:flutter/material.dart';
import '../../../core/services/powersync_service.dart';

class BuyerFormScreen extends StatefulWidget {
  final String? buyerId;

  const BuyerFormScreen({super.key, this.buyerId});

  @override
  State<BuyerFormScreen> createState() => _BuyerFormScreenState();
}

class _BuyerFormScreenState extends State<BuyerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedAreaId;

  final codeCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final firmCtrl = TextEditingController();
  final areaCtrl = TextEditingController();
  final balanceCtrl = TextEditingController();

  bool isLoading = false;
  bool isEditMode = false;
  bool isCodeUsed = false;
  Map<String, dynamic>? buyerData;

  @override
  void initState() {
    super.initState();
    isEditMode = widget.buyerId != null;

    if (isEditMode) {
      _loadBuyerData();
    } else {
      balanceCtrl.text = '0';
    }
  }

  Future<void> _loadBuyerData() async {
    setState(() => isLoading = true);

    try {
      // PowerSync: Load buyer data
      final data = await powerSyncDB.getAll(
        'SELECT * FROM buyers WHERE id = ?',
        [widget.buyerId],
      );

      if (data.isNotEmpty) {
        buyerData = data.first;

        codeCtrl.text = buyerData!['code']?.toString() ?? '';
        nameCtrl.text = buyerData!['name']?.toString() ?? '';
        phoneCtrl.text = buyerData!['phone']?.toString() ?? '';
        firmCtrl.text = buyerData!['firm_name']?.toString() ?? '';
        areaCtrl.text = buyerData!['area']?.toString() ?? '';
        balanceCtrl.text = buyerData!['opening_balance']?.toString() ?? '0';

        // PowerSync: Check if code is used in transactions
        final isUsed = await isCodeUsedInTransaction(
            buyerData!['code']?.toString() ?? '', 'buyers');

        setState(() {
          isCodeUsed = isUsed;
        });
      }
    } catch (e) {
      print("❌ Error loading buyer: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटी: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveBuyer() async {
    if (!_formKey.currentState!.validate()) return;

    final code = codeCtrl.text.trim().toUpperCase();

    // Validate R code
    if (code == 'R') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('R कोड रिझर्व्हड आहे (Rokda साठी)'),
        ),
      );
      return;
    }

    if (!isEditMode || code != buyerData?['code']) {
      // PowerSync: Check code uniqueness
      final isUnique = await isCodeUnique(code, 'buyers');
      if (!isUnique) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('हा कोड आधीच वापरात आहे'),
          ),
        );
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      final now = DateTime.now().toIso8601String();

      final buyer = {
        'code': code,
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'firm_name': firmCtrl.text.trim(),
        'area_id': selectedAreaId,
        'area': areaCtrl.text.trim(),
        'opening_balance': double.tryParse(balanceCtrl.text) ?? 0,
        'updated_at': now,
      };

      if (isEditMode) {
        // PowerSync: Update buyer
        await updateRecord('buyers', widget.buyerId!, buyer);
      } else {
        buyer['created_at'] = now;
        // PowerSync: Insert buyer
        await insertRecord('buyers', buyer);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode ? 'व्यापारी अपडेट झाला' : 'व्यापारी जोडला गेला',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      print("❌ Error saving buyer: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('त्रुटी: $e'),
          backgroundColor: Colors.red,
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

    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(code)) {
      return 'फक्त अक्षरे आणि अंक वापरा';
    }

    if (code == 'R') {
      return 'R कोड रिझर्व्हड आहे';
    }

    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'नाव आवश्यक आहे';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode ? 'व्यापारी एडिट करा' : 'नवीन व्यापारी',
        ),
        centerTitle: true,
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 4,
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
                    // Header
                    Card(
                      color: Colors.orange[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.business,
                              size: 40,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                isEditMode
                                    ? 'व्यापारीची माहिती अपडेट करा'
                                    : 'नवीन व्यापारी नोंदवा',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Code Field
                    TextFormField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'व्यापारी कोड *',
                        hintText: 'ST, RK, etc.',
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
                        labelText: 'व्यापारी नाव *',
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

                    // Firm Name
                    TextFormField(
                      controller: firmCtrl,
                      decoration: const InputDecoration(
                        labelText: 'फर्मचे नाव',
                        hintText: 'व्यवसायाचे नाव',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business_center),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Area Dropdown
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: powerSyncDB.getAll(
                        'SELECT * FROM areas WHERE active = 1 ORDER BY name ASC',
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Text(
                              'एरिया लोड होताना त्रुटी: ${snapshot.error}');
                        }

                        final areas = snapshot.data ?? [];

                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'एरिया',
                            hintText: 'एरिया निवडा',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedAreaId,
                          items: areas.map((area) {
                            return DropdownMenuItem<String>(
                              value: area['id'].toString(),
                              child: Text(area['name'].toString()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedAreaId = value;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'एरिया निवडा' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Area
                    TextFormField(
                      controller: areaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'क्षेत्र',
                        hintText: 'गाव, तालुका',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Opening Balance
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
                    ),

                    const SizedBox(height: 24),

                    // Info Card
                    Card(
                      color: Colors.orange[50],
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
                            Text('• कोड R रिझर्व्हड आहे (Rokda साठी)'),
                            Text('• कोड कायमस्वरूपी असतो'),
                            Text('• कोड डुप्लिकेट असू शकत नाही'),
                            Text('• R कोडवर नाव Rokda दिसेल'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _saveBuyer,
                        icon: const Icon(Icons.save),
                        label: Text(
                          isLoading ? 'सेव होत आहे...' : 'सेव करा',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
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
    firmCtrl.dispose();
    areaCtrl.dispose();
    balanceCtrl.dispose();
    super.dispose();
  }
}
