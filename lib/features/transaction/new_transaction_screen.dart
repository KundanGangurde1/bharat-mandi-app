import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/db_service.dart';

class TransactionRow {
  String traderCode;
  String traderName;
  String produceCode;
  String produceName;
  double dag;
  double weight;
  double rate;
  double total;

  TransactionRow({
    required this.traderCode,
    required this.traderName,
    required this.produceCode,
    required this.produceName,
    required this.dag,
    required this.weight,
    required this.rate,
  }) : total = weight * rate;
}

class ExpenseItem {
  final int id;
  final String name;
  final String calculationType;
  final String applyOn;
  final double defaultValue;
  final TextEditingController controller = TextEditingController();

  ExpenseItem({
    required this.id,
    required this.name,
    required this.calculationType,
    required this.applyOn,
    required this.defaultValue,
  });
}

class NewTransactionScreen extends StatefulWidget {
  const NewTransactionScreen({super.key});

  @override
  State<NewTransactionScreen> createState() => _NewTransactionScreenState();
}

class _NewTransactionScreenState extends State<NewTransactionScreen> {
  // Controllers
  final farmerCodeCtrl = TextEditingController();
  final farmerNameCtrl = TextEditingController();
  final produceCodeCtrl = TextEditingController();
  final produceNameCtrl = TextEditingController();
  final traderCodeCtrl = TextEditingController();
  final traderNameCtrl = TextEditingController();
  final dagCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final rateCtrl = TextEditingController();

  // Focus Nodes
  final farmerCodeFocus = FocusNode();
  final produceCodeFocus = FocusNode();
  final traderCodeFocus = FocusNode();
  final dagFocus = FocusNode();
  final weightFocus = FocusNode();
  final rateFocus = FocusNode();

  // State
  DateTime selectedDate = DateTime.now();
  bool farmerNameEditable = false;
  bool produceLocked = false;
  bool expenseExpanded = false;

  List<TransactionRow> rows = [];
  List<ExpenseItem> expenseItems = [];

  @override
  void initState() {
    super.initState();
    _setupKeyboardFlow();
    _loadExpenseTypes();
  }

  Future<void> _loadExpenseTypes() async {
    try {
      final db = await DBService.database;
      final data = await db.query(
        'expense_types',
        where: 'active = 1',
        orderBy: 'name ASC',
      );

      setState(() {
        expenseItems = data.map((row) {
          return ExpenseItem(
            id: row['id'] as int,
            name: row['name'] as String,
            calculationType: row['calculation_type'] as String? ?? 'per_unit',
            applyOn: row['apply_on'] as String? ?? 'farmer',
            defaultValue: (row['default_value'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();

        for (var item in expenseItems) {
          item.controller.text = item.defaultValue.toStringAsFixed(2);
        }
      });
    } catch (e) {
      print("Expense types load error: $e");
    }
  }

  void _setupKeyboardFlow() {
    farmerCodeFocus.addListener(() {
      if (farmerCodeFocus.hasFocus) {
        farmerCodeCtrl.selection = TextSelection(
            baseOffset: 0, extentOffset: farmerCodeCtrl.text.length);
      }
    });

    produceCodeFocus.addListener(() {
      if (produceCodeFocus.hasFocus) {
        produceCodeCtrl.selection = TextSelection(
            baseOffset: 0, extentOffset: produceCodeCtrl.text.length);
      }
    });

    traderCodeFocus.addListener(() {
      if (traderCodeFocus.hasFocus) {
        traderCodeCtrl.selection = TextSelection(
            baseOffset: 0, extentOffset: traderCodeCtrl.text.length);
      }
    });

    dagFocus.addListener(() {
      if (dagFocus.hasFocus) {
        dagCtrl.selection =
            TextSelection(baseOffset: 0, extentOffset: dagCtrl.text.length);
      }
    });

    weightFocus.addListener(() {
      if (weightFocus.hasFocus) {
        weightCtrl.selection =
            TextSelection(baseOffset: 0, extentOffset: weightCtrl.text.length);
      }
    });

    rateFocus.addListener(() {
      if (rateFocus.hasFocus) {
        rateCtrl.selection =
            TextSelection(baseOffset: 0, extentOffset: rateCtrl.text.length);
      }
    });
  }

  // Lookup methods
  Future<void> lookupFarmer(String code) async {
    code = code.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        farmerNameCtrl.text = "";
        farmerNameEditable = false;
      });
      return;
    }
    if (code == "100") {
      setState(() {
        farmerNameCtrl.text = "";
        farmerNameEditable = true;
      });
      return;
    }
    try {
      final db = await DBService.database;
      final data = await db.query('farmers',
          where: 'code = ? AND active = 1', whereArgs: [code]);
      setState(() {
        if (data.isEmpty) {
          farmerNameCtrl.text = "";
          farmerNameEditable = true;
        } else {
          farmerNameCtrl.text = data.first['name'].toString();
          farmerNameEditable = false;
        }
      });
    } catch (e) {
      print("Farmer lookup error: $e");
    }
  }

  Future<void> lookupProduce(String code) async {
    code = code.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        produceNameCtrl.text = "";
      });
      return;
    }
    try {
      final db = await DBService.database;
      final data = await db.query('produce',
          where: 'code = ? AND active = 1', whereArgs: [code]);
      setState(() {
        if (data.isEmpty) {
          produceNameCtrl.text = "";
        } else {
          produceNameCtrl.text = data.first['name'].toString();
        }
      });
    } catch (e) {
      print("Produce lookup error: $e");
    }
  }

  Future<void> lookupTrader(String code) async {
    code = code.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        traderNameCtrl.text = "";
      });
      return;
    }
    if (code == "R") {
      setState(() {
        traderNameCtrl.text = "Rokda";
      });
      return;
    }
    try {
      final db = await DBService.database;
      final data = await db.query('traders',
          where: 'code = ? AND active = 1', whereArgs: [code]);
      setState(() {
        if (data.isEmpty) {
          traderNameCtrl.text = "";
        } else {
          traderNameCtrl.text = data.first['name'].toString();
        }
      });
    } catch (e) {
      print("Trader lookup error: $e");
    }
  }

  // Calculations
  double get totalAmount => rows.fold(0, (sum, row) => sum + row.total);

  double get totalExpense {
    if (!expenseExpanded || expenseItems.isEmpty) return 0;

    double sum = 0;
    double totalDag = rows.fold(0, (s, r) => s + r.dag);
    double totalWeight = rows.fold(0, (s, r) => s + r.weight);
    double totalAmt = totalAmount;

    for (var exp in expenseItems) {
      final entered = double.tryParse(exp.controller.text) ?? exp.defaultValue;
      if (entered <= 0) continue;

      double calculated = 0.0;
      switch (exp.calculationType) {
        case 'per_unit':
          calculated = totalWeight * entered;
          break;
        case 'per_bag':
          calculated = totalDag * entered;
          break;
        case 'percentage':
          calculated = totalAmt * (entered / 100);
          break;
      }

      // फक्त farmer apply_on असलेले खर्च net मधून वजा कर
      if (exp.applyOn == 'farmer') {
        sum += calculated;
      }
      // trader apply_on असलेले खर्च फक्त recovery मध्ये जोडले जातील (save वेळी)
    }

    return sum;
  }

  double get netTotal => totalAmount - totalExpense;

  // Keyboard Flow
  void _handleFarmerCodeEnter() {
    if (farmerCodeCtrl.text.isNotEmpty)
      FocusScope.of(context).requestFocus(produceCodeFocus);
  }

  void _handleProduceCodeEnter() {
    if (produceCodeCtrl.text.isNotEmpty)
      FocusScope.of(context).requestFocus(traderCodeFocus);
  }

  void _handleTraderCodeEnter() {
    if (traderCodeCtrl.text.isNotEmpty)
      FocusScope.of(context).requestFocus(dagFocus);
  }

  void _handleDagEnter() {
    if (dagCtrl.text.isNotEmpty)
      FocusScope.of(context).requestFocus(weightFocus);
  }

  void _handleWeightEnter() {
    if (weightCtrl.text.isNotEmpty)
      FocusScope.of(context).requestFocus(rateFocus);
  }

  void _handleRateEnter() {
    if (rateCtrl.text.isNotEmpty) _addRow();
  }

  // Add Row
  void _addRow() {
    if (traderCodeCtrl.text.isEmpty || traderNameCtrl.text.isEmpty) {
      _showSnackBar("व्यापारी कोड आवश्यक आहे");
      traderCodeFocus.requestFocus();
      return;
    }

    if (produceCodeCtrl.text.isEmpty || produceNameCtrl.text.isEmpty) {
      _showSnackBar("माल कोड आवश्यक आहे");
      produceCodeFocus.requestFocus();
      return;
    }

    final dag = double.tryParse(dagCtrl.text);
    if (dag == null || dag <= 0) {
      _showSnackBar("योग्य डाग प्रविष्ट करा");
      dagFocus.requestFocus();
      return;
    }

    final weight = double.tryParse(weightCtrl.text);
    final rate = double.tryParse(rateCtrl.text);

    if (weight == null || weight <= 0) {
      _showSnackBar("योग्य वजन प्रविष्ट करा");
      weightFocus.requestFocus();
      return;
    }

    if (rate == null || rate <= 0) {
      _showSnackBar("योग्य भाव प्रविष्ट करा");
      rateFocus.requestFocus();
      return;
    }

    setState(() {
      rows.add(TransactionRow(
        traderCode: traderCodeCtrl.text.trim().toUpperCase(),
        traderName: traderNameCtrl.text,
        produceCode: produceCodeCtrl.text.trim().toUpperCase(),
        produceName: produceNameCtrl.text,
        dag: dag,
        weight: weight,
        rate: rate,
      ));

      traderCodeCtrl.clear();
      traderNameCtrl.clear();
      dagCtrl.clear();
      weightCtrl.clear();
      rateCtrl.clear();

      if (!produceLocked) {
        produceCodeCtrl.clear();
        produceNameCtrl.clear();
      }
    });

    produceLocked
        ? traderCodeFocus.requestFocus()
        : produceCodeFocus.requestFocus();
    _showSnackBar("एंट्री जोडली गेली");
  }

  // Save Transaction
  Future<void> _saveTransaction() async {
    if (rows.isEmpty) {
      _showSnackBar("किमान एक एंट्री आवश्यक आहे");
      return;
    }

    try {
      final db = await DBService.database;
      final parchiId = DateTime.now().millisecondsSinceEpoch.toString();

      for (final row in rows) {
        await db.insert('transactions', {
          'parchi_id': parchiId,
          'farmer_code': farmerCodeCtrl.text.trim().toUpperCase(),
          'farmer_name': farmerNameCtrl.text,
          'trader_code': row.traderCode,
          'trader_name': row.traderName,
          'produce_code': row.produceCode,
          'produce_name': row.produceName,
          'dag': row.dag,
          'quantity': row.weight,
          'rate': row.rate,
          'gross': row.total,
          'total_expense': totalExpense,
          'net': netTotal,
          'created_at': selectedDate.toIso8601String(),
        });
      }

      if (expenseExpanded && expenseItems.isNotEmpty) {
        for (var exp in expenseItems) {
          final amount =
              double.tryParse(exp.controller.text) ?? exp.defaultValue;
          if (amount > 0) {
            await db.insert('transaction_expenses', {
              'parchi_id': parchiId,
              'expense_type_id': exp.id,
              'amount': amount,
              'created_at': DateTime.now().toIso8601String(),
            });

            // trader खर्च ऑटो जोड
            if (exp.applyOn == 'trader' && rows.isNotEmpty) {
              final traderCode = rows.first.traderCode;
              await db.rawUpdate(
                'UPDATE traders SET opening_balance = opening_balance + ? WHERE code = ?',
                [amount, traderCode],
              );
            }
          }
        }
      }
      _showSnackBar("पर्ची सेव झाली! एकूण एंट्री: ${rows.length}",
          isError: false);
      _resetForm();
    } catch (e) {
      print("Save error: $e");
      _showSnackBar("सेम त्रुटी: $e");
    }
  }

  // Reset Form
  void _resetForm() {
    setState(() {
      rows.clear();
      farmerCodeCtrl.clear();
      farmerNameCtrl.clear();
      produceCodeCtrl.clear();
      produceNameCtrl.clear();
      traderCodeCtrl.clear();
      traderNameCtrl.clear();
      dagCtrl.clear();
      weightCtrl.clear();
      rateCtrl.clear();
      produceLocked = false;
      farmerNameEditable = false;
      expenseExpanded = false;
    });

    farmerCodeFocus.requestFocus();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('नवीन पर्ची'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long,
                              size: 40, color: Colors.green),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'नवीन पर्ची तयार करा',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'तारीख: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => selectedDate = picked);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Farmer Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'शेतकरी माहिती',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: farmerCodeCtrl,
                                  focusNode: farmerCodeFocus,
                                  decoration: const InputDecoration(
                                    labelText: 'शेतकरी कोड',
                                    hintText: 'KM या 100',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: lookupFarmer,
                                  onSubmitted: (_) => _handleFarmerCodeEnter(),
                                  textInputAction: TextInputAction.next,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: farmerNameCtrl,
                                  enabled: farmerNameEditable,
                                  decoration: const InputDecoration(
                                    labelText: 'शेतकरी नाव',
                                    hintText: 'पूर्ण नाव',
                                    border: OutlineInputBorder(),
                                  ),
                                  textInputAction: TextInputAction.next,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Current Transactions Table
                  if (rows.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'वर्तमान पर्ची',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('व्यापारी')),
                                  DataColumn(label: Text('माल')),
                                  DataColumn(label: Text('डाग')),
                                  DataColumn(label: Text('वजन')),
                                  DataColumn(label: Text('भाव')),
                                  DataColumn(label: Text('रक्कम')),
                                ],
                                rows: rows.map((row) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(row.traderName)),
                                      DataCell(Text(row.produceName)),
                                      DataCell(
                                          Text(row.dag.toStringAsFixed(0))),
                                      DataCell(Text(row.weight.toString())),
                                      DataCell(Text(
                                          '₹${row.rate.toStringAsFixed(2)}')),
                                      DataCell(Text(
                                          '₹${row.total.toStringAsFixed(2)}')),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Produce Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'माल माहिती',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                              Row(
                                children: [
                                  const Text('लॉक'),
                                  Switch(
                                    value: produceLocked,
                                    onChanged: (value) {
                                      setState(() => produceLocked = value);
                                    },
                                    activeColor: Colors.green,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: produceCodeCtrl,
                                  focusNode: produceCodeFocus,
                                  decoration: const InputDecoration(
                                    labelText: 'माल कोड',
                                    hintText: 'AL',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: lookupProduce,
                                  onSubmitted: (_) => _handleProduceCodeEnter(),
                                  textInputAction: TextInputAction.next,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: produceNameCtrl,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'माल नाव',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Trader Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'व्यापारी माहिती',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: traderCodeCtrl,
                                  focusNode: traderCodeFocus,
                                  decoration: const InputDecoration(
                                    labelText: 'व्यापारी कोड',
                                    hintText: 'ST या R',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: lookupTrader,
                                  onSubmitted: (_) => _handleTraderCodeEnter(),
                                  textInputAction: TextInputAction.next,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: traderNameCtrl,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'व्यापारी नाव',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // डाग इनपुट फील्ड
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'डाग',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: dagCtrl,
                            focusNode: dagFocus,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'डाग संख्या',
                              hintText: 'उदा. 5, 10',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _handleDagEnter(),
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quantity & Rate
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'मोजमाप',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: weightCtrl,
                                  focusNode: weightFocus,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'वजन / नग',
                                    hintText: 'किलो किंवा नग',
                                    border: OutlineInputBorder(),
                                  ),
                                  onSubmitted: (_) => _handleWeightEnter(),
                                  textInputAction: TextInputAction.next,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: rateCtrl,
                                  focusNode: rateFocus,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'भाव',
                                    hintText: 'दर प्रति युनिट',
                                    border: OutlineInputBorder(),
                                  ),
                                  onSubmitted: (_) => _handleRateEnter(),
                                  textInputAction: TextInputAction.done,
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _addRow,
                                child: const Text('जोडा'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 15),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Expenses Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                expenseExpanded = !expenseExpanded;
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'खर्च विवरण',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green),
                                ),
                                Row(
                                  children: [
                                    Text(expenseExpanded ? 'ON' : 'OFF'),
                                    const SizedBox(width: 8),
                                    Switch(
                                      value: expenseExpanded,
                                      onChanged: (value) {
                                        setState(() => expenseExpanded = value);
                                      },
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (expenseExpanded) ...[
                            const SizedBox(height: 16),
                            if (expenseItems.isEmpty)
                              const Center(
                                  child:
                                      Text('कोणतेही खर्च प्रकार उपलब्ध नाहीत')),
                            ...expenseItems.map((exp) {
                              final enteredValue =
                                  double.tryParse(exp.controller.text) ??
                                      exp.defaultValue;
                              double calculatedAmount = 0.0;

                              double totalDag =
                                  rows.fold(0, (s, r) => s + r.dag);
                              double totalWeight =
                                  rows.fold(0, (s, r) => s + r.weight);
                              double totalAmt = totalAmount;

                              double bagSize = 50.0;

                              switch (exp.calculationType) {
                                case 'per_unit':
                                  calculatedAmount = totalWeight * enteredValue;
                                  break;
                                case 'per_bag':
                                  calculatedAmount = totalDag * enteredValue;
                                  break;
                                case 'percentage':
                                  calculatedAmount =
                                      totalAmt * (enteredValue / 100);
                                  break;
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        '${exp.name} (${exp.calculationType == 'per_unit' ? 'प्रति युनिट' : exp.calculationType == 'per_bag' ? 'प्रति डाग' : 'टक्केवारी'}) ${exp.applyOn == 'trader' ? '(व्यापारी खर्च)' : ''}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: exp.applyOn == 'trader'
                                              ? Color(0xFFFF7043)
                                              : Colors
                                                  .black, // trader साठी वेगळा कलर optional
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: exp.controller,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          hintText: 'मूल्य',
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.green[200]!),
                                      ),
                                      child: Text(
                                        '₹${calculatedAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Color.fromARGB(255, 41, 128, 46),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'एकूण खर्च:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Text(
                                  '₹${totalExpense.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.red),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Totals Card
                  Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('एकूण एंट्री:'),
                              Text(rows.length.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('एकूण रक्कम:'),
                              Text('₹${totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('एकूण खर्च:'),
                              Text('₹${totalExpense.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red)),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('शुद्ध रक्कम:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text('₹${netTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // Bottom Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border:
                  const Border(top: BorderSide(color: Colors.grey, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _resetForm,
                    icon: const Icon(Icons.refresh),
                    label: const Text('नवी पर्ची'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _saveTransaction,
                    icon: const Icon(Icons.save),
                    label: const Text('पर्ची सेव करा',
                        style: TextStyle(fontSize: 16)),
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    farmerCodeCtrl.dispose();
    farmerNameCtrl.dispose();
    produceCodeCtrl.dispose();
    produceNameCtrl.dispose();
    traderCodeCtrl.dispose();
    traderNameCtrl.dispose();
    dagCtrl.dispose();
    weightCtrl.dispose();
    rateCtrl.dispose();

    farmerCodeFocus.dispose();
    produceCodeFocus.dispose();
    traderCodeFocus.dispose();
    dagFocus.dispose();
    weightFocus.dispose();
    rateFocus.dispose();

    for (var exp in expenseItems) {
      exp.controller.dispose();
    }

    super.dispose();
  }
}
