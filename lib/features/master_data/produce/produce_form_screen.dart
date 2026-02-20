import 'package:flutter/material.dart';
import '../../../core/services/powersync_service.dart';
import '../../../core/services/firm_data_service.dart';

class ProduceFormScreen extends StatefulWidget {
  final String? produceId;

  const ProduceFormScreen({super.key, this.produceId});

  @override
  State<ProduceFormScreen> createState() => _ProduceFormScreenState();
}

class _ProduceFormScreenState extends State<ProduceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final codeCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final varietyCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  final commissionValueCtrl =
      TextEditingController(); // ✅ NEW: Commission percentage

  bool isLoading = false;
  bool isEditMode = false;
  bool isCodeUsed = false;
  Map<String, dynamic>? produceData;

  // ✅ NEW: Commission fields
  String commissionType = 'DEFAULT'; // DEFAULT or PER_PRODUCE
  String? selectedApplyOn = 'farmer'; // farmer or buyer

  @override
  void initState() {
    super.initState();
    isEditMode = widget.produceId != null;

    if (isEditMode) {
      _loadProduceData();
    }
  }

  Future<void> _loadProduceData() async {
    setState(() => isLoading = true);

    try {
      final firmId = await FirmDataService.getActiveFirmId();
      final data = await powerSyncDB.getAll(
        'SELECT * FROM produce WHERE firm_id = ? AND id = ?',
        [firmId, widget.produceId],
      );

      if (data.isNotEmpty) {
        produceData = data.first;

        codeCtrl.text = produceData!['code']?.toString() ?? '';
        nameCtrl.text = produceData!['name']?.toString() ?? '';
        varietyCtrl.text = produceData!['variety']?.toString() ?? '';
        categoryCtrl.text = produceData!['category']?.toString() ?? '';

        // ✅ NEW: Load commission fields
        commissionType = produceData!['commission_type'] ?? 'DEFAULT';
        selectedApplyOn = produceData!['commission_apply_on'] ?? 'farmer';
        commissionValueCtrl.text =
            (produceData!['commission_value'] as num?)?.toString() ?? '';

        final firmId2 = await FirmDataService.getActiveFirmId();
        final transactions = await powerSyncDB.getAll(
          'SELECT COUNT(*) as count FROM transactions WHERE firm_id = ? AND produce_code = ?',
          [firmId2, produceData!['code']?.toString() ?? ''],
        );

        final count = (transactions.isNotEmpty
                ? (transactions.first['count'] as int?)
                : 0) ??
            0;
        isCodeUsed = count > 0;

        setState(() {});
      }
    } catch (e) {
      print('❌ Error loading produce: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटी: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveProduce() async {
    if (!_formKey.currentState!.validate()) return;

    final code = codeCtrl.text.trim().toUpperCase();

    if (!isEditMode || code != produceData?['code']) {
      try {
        final firmId3 = await FirmDataService.getActiveFirmId();
        if (firmId3 == null) {
          throw Exception('No active firm found');
        }
        final existing = await powerSyncDB.getAll(
          'SELECT COUNT(*) as count FROM produce WHERE firm_id = ? AND code = ? AND id != ?',
          [firmId3, code, widget.produceId ?? ''],
        );

        final count =
            (existing.isNotEmpty ? (existing.first['count'] as int?) : 0) ?? 0;

        if (count > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('हा कोड आधीच वापरात आहे'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } catch (e) {
        print("❌ Error checking code uniqueness: $e");
      }
    }

    setState(() => isLoading = true);

    try {
      final now = DateTime.now().toIso8601String();

      // ✅ NEW: Set default commission_type if not set
      if (commissionType.isEmpty) {
        commissionType = 'DEFAULT';
      }

      final Map<String, dynamic> produce = {
        'code': code,
        'name': nameCtrl.text.trim(),
        'variety': varietyCtrl.text.trim(),
        'category': categoryCtrl.text.trim(),
        'updated_at': now,
        // ✅ NEW: Commission fields
        'commission_type': commissionType,
        'commission_value': commissionType == 'PER_PRODUCE'
            ? double.tryParse(commissionValueCtrl.text)
            : null,
        'commission_apply_on':
            commissionType == 'PER_PRODUCE' ? selectedApplyOn : null,
      };

      if (isEditMode) {
        await updateRecord('produce', widget.produceId!, produce);
        print('✅ Produce updated: $widget.produceId');
      } else {
        produce['created_at'] = now;
        produce['active'] = 1;
        await FirmDataService.insertRecordWithFirmId('produce', produce);
        print('✅ Produce created with firm_id');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode ? 'माल अपडेट झाला' : 'माल जोडला गेला',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      print('❌ Error saving produce: $e');
      if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'माल संपादित करा' : 'नवीन माल'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading && isEditMode
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Code Field
                    TextFormField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'माल कोड',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.code),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'माल कोड आवश्यक आहे';
                        }
                        return null;
                      },
                      readOnly: isCodeUsed,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Name Field
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'माल नाव',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.agriculture),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'माल नाव आवश्यक आहे';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Variety Field
                    TextFormField(
                      controller: varietyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'किस्म',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Category Field
                    TextFormField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'वर्ग',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 24),

                    // ✅ NEW: Commission Type Toggle
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.orange.withOpacity(0.05),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'कमिशन प्रकार *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => commissionType = 'DEFAULT');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: commissionType == 'DEFAULT'
                                            ? Colors.green
                                            : Colors.grey,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: commissionType == 'DEFAULT'
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.transparent,
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: commissionType == 'DEFAULT'
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'डिफॉल्ट',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(
                                        () => commissionType = 'PER_PRODUCE');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: commissionType == 'PER_PRODUCE'
                                            ? Colors.blue
                                            : Colors.grey,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: commissionType == 'PER_PRODUCE'
                                          ? Colors.blue.withOpacity(0.1)
                                          : Colors.transparent,
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.tune,
                                          color: commissionType == 'PER_PRODUCE'
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'मालाप्रमाणे',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ✅ NEW: Commission Value Field (only for PER_PRODUCE)
                          if (commissionType == 'PER_PRODUCE') ...[
                            TextFormField(
                              controller: commissionValueCtrl,
                              decoration: const InputDecoration(
                                labelText: 'कमिशन टक्केवारी (%)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.percent),
                                hintText: 'उदा. 5 किंवा 2.5',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (value) {
                                if (commissionType == 'PER_PRODUCE' &&
                                    (value == null || value.isEmpty)) {
                                  return 'कृपया कमिशन टक्केवारी टाका';
                                }
                                if (value != null &&
                                    value.isNotEmpty &&
                                    double.tryParse(value) == null) {
                                  return 'कृपया योग्य नंबर टाका';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // ✅ NEW: Apply On Toggle (only for PER_PRODUCE)
                            const Text(
                              'लागू करा *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('शेतकरी'),
                                    value: 'farmer',
                                    groupValue: selectedApplyOn,
                                    onChanged: (value) {
                                      setState(() => selectedApplyOn = value);
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('खरीददार'),
                                    value: 'buyer',
                                    groupValue: selectedApplyOn,
                                    onChanged: (value) {
                                      setState(() => selectedApplyOn = value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveProduce,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                isEditMode ? 'अपडेट करा' : 'जोडा',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
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
    varietyCtrl.dispose();
    categoryCtrl.dispose();
    commissionValueCtrl.dispose();
    super.dispose();
  }
}
