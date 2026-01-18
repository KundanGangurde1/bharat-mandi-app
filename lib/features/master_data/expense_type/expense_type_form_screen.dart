import 'package:flutter/material.dart';
import '../../../core/services/db_service.dart';

class ExpenseTypeFormScreen extends StatefulWidget {
  final int? expenseId;

  const ExpenseTypeFormScreen({super.key, this.expenseId});

  @override
  State<ExpenseTypeFormScreen> createState() => _ExpenseTypeFormScreenState();
}

class _ExpenseTypeFormScreenState extends State<ExpenseTypeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  String applyOn = 'farmer'; // 'farmer' or 'trader'
  String calculationType = 'per_dag'; // 'per_dag', 'percentage', 'fixed'
  final defaultValueCtrl = TextEditingController();
  bool active = true;
  bool showInReport = true;

  bool isLoading = false;
  bool isEditMode = false;
  Map<String, dynamic>? expenseData;

  @override
  void initState() {
    super.initState();
    isEditMode = widget.expenseId != null;

    if (isEditMode) {
      _loadExpenseData();
    } else {
      defaultValueCtrl.text = '0';
    }
  }

  Future<void> _loadExpenseData() async {
    setState(() => isLoading = true);

    try {
      final db = await DBService.database;
      final data = await db.query(
        'expense_types',
        where: 'id = ?',
        whereArgs: [widget.expenseId],
      );

      if (data.isNotEmpty) {
        expenseData = data.first;

        nameCtrl.text = expenseData!['name']?.toString() ?? '';
        applyOn = expenseData!['apply_on']?.toString() ?? 'farmer';
        calculationType = calculationType =
            expenseData!['calculation_type']?.toString() ?? 'per_dag';
        defaultValueCtrl.text =
            expenseData!['default_value']?.toString() ?? '0';
        active = expenseData!['active'] == 1;
        showInReport = expenseData!['show_in_report'] == 1;
      }
    } catch (e) {
      print("Error loading expense type: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveExpenseType() async {
    if (!_formKey.currentState!.validate()) return;

    final name = nameCtrl.text.trim();
    final defaultValue = double.tryParse(defaultValueCtrl.text) ?? 0;

    if (defaultValue < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('व्हॅल्यू 0 पेक्षा जास्त असावी')),
      );
      return;
    }

    if (calculationType == 'percentage' && defaultValue > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('टक्केवारी 100% पेक्षा जास्त असू शकत नाही')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final now = DateTime.now().toIso8601String();
      final expense = {
        'name': name,
        'apply_on': applyOn,
        'calculation_type': calculationType, // येथे calculation_type वापरलं
        'default_value': defaultValue,
        'active': active ? 1 : 0,
        'show_in_report': showInReport ? 1 : 0,
        'updated_at': now,
      };

      final db = await DBService.database;

      if (isEditMode) {
        await db.update(
          'expense_types',
          expense,
          where: 'id = ?',
          whereArgs: [widget.expenseId],
        );
      } else {
        expense['created_at'] = now;
        await db.insert('expense_types', expense);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode ? 'खर्च प्रकार अपडेट झाला' : 'खर्च प्रकार जोडला गेला',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      print("Error saving expense type: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('त्रुटी: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'नाव आवश्यक आहे';
    }
    return null;
  }

  String? _validateValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'व्हॅल्यू आवश्यक आहे';
    }

    final numValue = double.tryParse(value);
    if (numValue == null) {
      return 'योग्य संख्या प्रविष्ट करा';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'खर्च प्रकार एडिट करा' : 'नवीन खर्च प्रकार'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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
                    // Name Field
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'खर्चाचे नाव *',
                        hintText: 'हमाली, तोलाई, कमीशन, वाराई',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.text_fields),
                      ),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 20),

                    // Apply On - Radio Group
                    const Text(
                      'लागू करा *',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('शेतकरी'),
                            value: 'farmer',
                            groupValue: applyOn,
                            onChanged: (value) {
                              if (value != null)
                                setState(() => applyOn = value);
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('व्यापारी'),
                            value: 'trader',
                            groupValue: applyOn,
                            onChanged: (value) {
                              if (value != null)
                                setState(() => applyOn = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Calculation Type (Mode) - Dropdown
                    const Text(
                      'गणना प्रकार *',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: calculationType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'per_dag', child: Text('प्रति डाग')),
                        DropdownMenuItem(
                            value: 'percentage', child: Text('टक्केवारी (%)')),
                        DropdownMenuItem(
                            value: 'fixed', child: Text('फिक्स्ड अमाउंट')),
                      ],
                      onChanged: (value) {
                        if (value != null)
                          setState(() => calculationType = value);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Default Value
                    TextFormField(
                      controller: defaultValueCtrl,
                      decoration: InputDecoration(
                        labelText: calculationType == 'percentage'
                            ? 'डिफॉल्ट टक्केवारी *'
                            : 'डिफॉल्ट व्हॅल्यू *',
                        hintText: calculationType == 'percentage' ? '2' : '10',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.attach_money),
                        suffixText: calculationType == 'percentage' ? '%' : '₹',
                      ),
                      keyboardType: TextInputType.number,
                      validator: _validateValue,
                    ),
                    const SizedBox(height: 20),

                    // Active Toggle
                    SwitchListTile(
                      title: const Text('सक्रिय'),
                      subtitle:
                          const Text('निष्क्रिय केल्यास वापरात येणार नाही'),
                      value: active,
                      onChanged: (value) {
                        setState(() => active = value);
                      },
                    ),

                    // Show in Report Toggle
                    SwitchListTile(
                      title: const Text('रिपोर्टमध्ये दाखवा'),
                      subtitle:
                          const Text('बंद केल्यास रिपोर्टमध्ये दिसणार नाही'),
                      value: showInReport,
                      onChanged: (value) {
                        setState(() => showInReport = value);
                      },
                    ),

                    const SizedBox(height: 30),

                    // Info Card
                    Card(
                      color: Colors.blue[50],
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'महत्वाचे माहिती:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text('• शेतकरी खर्च: हमाली, तोलाई, वाराई'),
                            Text('• व्यापारी खर्च: कमीशन, अ‍ॅडव्हान्स'),
                            Text('• प्रति डाग: डाग × मूल्य'),
                            Text('• टक्केवारी: एकूण रक्कम × %'),
                            Text('• फिक्स्ड: पावती प्रति फिक्स्ड अमाउंट'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _saveExpenseType,
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
    nameCtrl.dispose();
    defaultValueCtrl.dispose();
    super.dispose();
  }
}
