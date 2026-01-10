import 'package:flutter/material.dart';
import '../../../core/services/db_service.dart';

class ProduceFormScreen extends StatefulWidget {
  final int? produceId;

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
      final db = await DBService.database;
      final data = await db.query(
        'produce',
        where: 'id = ?',
        whereArgs: [widget.produceId],
      );

      if (data.isNotEmpty) {
        produceData = data.first;

        codeCtrl.text = produceData!['code']?.toString() ?? '';
        nameCtrl.text = produceData!['name']?.toString() ?? '';
        varietyCtrl.text = produceData!['variety']?.toString() ?? '';
        categoryCtrl.text = produceData!['category']?.toString() ?? '';

        // Check if code is used in transactions
        final isUsed = await DBService.isCodeUsedInTransaction(
            produceData!['code']?.toString() ?? '', 'produce');

        setState(() {
          isCodeUsed = isUsed;
        });
      }
    } catch (e) {
      print("Error loading produce: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveProduce() async {
    if (!_formKey.currentState!.validate()) return;

    final code = codeCtrl.text.trim().toUpperCase();

    if (!isEditMode || code != produceData?['code']) {
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

    setState(() => isLoading = true);

    try {
      final db = await DBService.database;
      final now = DateTime.now().toIso8601String();

      final produce = {
        'code': code,
        'name': nameCtrl.text.trim(),
        'variety': varietyCtrl.text.trim(),
        'category': categoryCtrl.text.trim(),
        'updated_at': now,
      };

      if (isEditMode) {
        await db.update(
          'produce',
          produce,
          where: 'id = ?',
          whereArgs: [widget.produceId],
        );
      } else {
        produce['created_at'] = now;
        await db.insert('produce', produce);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode ? 'माल अपडेट झाला' : 'माल जोडला गेला',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      print("Error saving produce: $e");
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
          isEditMode ? 'माल एडिट करा' : 'नवीन माल',
        ),
        centerTitle: true,
        backgroundColor: Colors.purple[700],
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
                      color: Colors.purple[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.shopping_basket,
                              size: 40,
                              color: Colors.purple[700],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                isEditMode
                                    ? 'मालाची माहिती अपडेट करा'
                                    : 'नवीन माल नोंदवा',
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
                        labelText: 'माल कोड *',
                        hintText: 'AL, PO, etc.',
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
                        labelText: 'मालाचे नाव *',
                        hintText: 'आलू, कांदा, टोमॅटो',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.text_fields),
                      ),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 16),

                    // Variety Field
                    TextFormField(
                      controller: varietyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'वैरायटी',
                        hintText: 'चिप्सोना, कुफरी, etc.',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Field
                    TextFormField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'श्रेणी',
                        hintText: 'सब्जी, फळ, अनाज',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Info Card
                    Card(
                      color: Colors.purple[50],
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
                            Text('• कोड कायमस्वरूपी असतो'),
                            Text('• कोड डुप्लिकेट असू शकत नाही'),
                            Text('• वैरायटी: विशिष्ट प्रकार (चिप्सोना, कुफरी)'),
                            Text('• श्रेणी: मुख्य प्रकार (सब्जी, फळ, अनाज)'),
                            Text('• उदा: AL - आलू, PO - पोयसे'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _saveProduce,
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
    varietyCtrl.dispose();
    categoryCtrl.dispose();
    super.dispose();
  }
}
