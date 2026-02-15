import 'package:flutter/material.dart';
import '../../../core/services/powersync_service.dart';
import '../../../core/services/firm_data_service.dart'; // ✅ NEW

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

  bool isLoading = false;
  bool isEditMode = false;
  bool isCodeUsed = false;
  Map<String, dynamic>? produceData;

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
      // ✅ NEW: Load produce data for active firm
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

        // ✅ NEW: Check if code is used in transactions for active firm
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

  Future<void> _saveProduce() async {
    if (!_formKey.currentState!.validate()) return;

    final code = codeCtrl.text.trim().toUpperCase();

    // Check if code is unique (if new or code changed)
    if (!isEditMode || code != produceData?['code']) {
      try {
        // ✅ NEW: Check code uniqueness for active firm
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

      final Map<String, dynamic> produce = {
        'code': code,
        'name': nameCtrl.text.trim(),
        'variety': varietyCtrl.text.trim(),
        'category': categoryCtrl.text.trim(),
        'updated_at': now,
      };

      if (isEditMode) {
        // PowerSync: Update produce
        await updateRecord('produce', widget.produceId!, produce);
        print('✅ Produce updated: $widget.produceId');
      } else {
        // ✅ NEW: Insert new produce with firm_id
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
      print('⚠️ Check if active firm is set');
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

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _saveProduce,
                        icon: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          isEditMode ? 'अपडेट करा' : 'जोडा',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
    super.dispose();
  }
}
