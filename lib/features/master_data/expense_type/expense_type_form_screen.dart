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
  String applyOn = 'farmer';
  String mode = 'fixed';
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
        mode = expenseData!['mode']?.toString() ?? 'fixed';
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

    if (mode == 'percentage' && defaultValue > 100) {
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
        'mode': mode,
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
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      print("Error saving expense type: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('त्रुटी: ${e.toString()}'),
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
                        hintText: 'हमाली, तोलाई, वाराई, कमीशन',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.text_fields),
                      ),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 20),

                    // Apply On - UPDATED WITH RadioGroup
                    const Text(
                      'लागू करा *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // RadioGroup for Apply On
                    RadioGroup(
                      selected: applyOn,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => applyOn = value);
                        }
                      },
                      options: const [
                        RadioOption(value: 'farmer', label: 'किसान'),
                        RadioOption(value: 'trader', label: 'व्यापारी'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Mode
                    const Text(
                      'मोड *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: mode, // CHANGED from value to initialValue
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'fixed',
                          child: Text('₹ (Fixed Amount)'),
                        ),
                        DropdownMenuItem(
                          value: 'percentage',
                          child: Text('% (Percentage)'),
                        ),
                        DropdownMenuItem(
                          value: 'per_piece',
                          child: Text('प्रति नग (Per Piece)'),
                        ),
                        DropdownMenuItem(
                          value: 'per_bag',
                          child: Text('प्रति डाग (Per Bag)'),
                        ),
                        DropdownMenuItem(
                          value: 'per_weight',
                          child: Text('प्रति वजन (Per Weight)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => mode = value);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Default Value
                    TextFormField(
                      controller: defaultValueCtrl,
                      decoration: InputDecoration(
                        labelText: mode == 'percentage'
                            ? 'डिफॉल्ट टक्केवारी *'
                            : 'डिफॉल्ट व्हॅल्यू *',
                        hintText: mode == 'percentage' ? '2' : '10',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.attach_money),
                        suffixText: mode == 'percentage' ? '%' : '₹',
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
                            Text('• किसान खर्च: हमाली, तोलाई, वाराई'),
                            Text('• व्यापारी खर्च: कमीशन, अ‍ॅडव्हान्स'),
                            Text('• रिपोर्टमध्ये न दाखवणे: कमीशन'),
                            Text('• Fixed: ₹10, ₹50 (Fixed Amount)'),
                            Text('• Percentage: 2%, 5% (Total च्या)'),
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

// Custom RadioGroup Widget (to avoid deprecation)
class RadioGroup extends StatelessWidget {
  final String selected;
  final ValueChanged<String?> onChanged;
  final List<RadioOption> options;

  const RadioGroup({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        return RadioListTile(
          title: Text(option.label),
          value: option.value,
          groupValue: selected,
          onChanged: onChanged,
        );
      }).toList(),
    );
  }
}

class RadioOption {
  final String value;
  final String label;

  const RadioOption({required this.value, required this.label});
}
