import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/services/db_service.dart';
import '../../core/expense_controller.dart';
import '../transaction/pavti_list_screen.dart';

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
  final double unitSize;
  final TextEditingController controller = TextEditingController();

  ExpenseItem({
    required this.id,
    required this.name,
    required this.calculationType,
    required this.applyOn,
    required this.defaultValue,
    this.unitSize = 1.0,
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
            unitSize: (row['unit_size'] as num?)?.toDouble() ?? 1.0,
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
    // double totalWeight = rows.fold(0, (s, r) => s + r.weight);
    double totalAmt = totalAmount;

    for (var exp in expenseItems) {
      // फक्त farmer खर्च net मधून वजा कर
      if (exp.applyOn != 'farmer') continue;

      final entered = double.tryParse(exp.controller.text) ?? exp.defaultValue;
      if (entered <= 0) continue;

      double calculated = 0.0;
      switch (exp.calculationType) {
        case 'per_dag':
          calculated = totalDag * entered; // डाग × मूल्य
          break;
        case 'percentage':
          calculated = totalAmt * (entered / 100);
          break;
        case 'fixed':
          calculated = entered; // फिक्स्ड अमाउंट (प्रति पावती)
          break;
        default:
          calculated = 0.0;
      }
      sum += calculated;
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

      int? pavtiId;

      await db.transaction((txn) async {
        final firstRow = rows.first;
        pavtiId = await txn.insert('transactions', {
          'farmer_code': farmerCodeCtrl.text.trim().toUpperCase(),
          'farmer_name': farmerNameCtrl.text,
          'trader_code': firstRow.traderCode,
          'trader_name': firstRow.traderName,
          'produce_code': firstRow.produceCode,
          'produce_name': firstRow.produceName,
          'dag': firstRow.dag,
          'quantity': firstRow.weight,
          'rate': firstRow.rate,
          'gross': firstRow.total,
          'total_expense': totalExpense,
          'net': netTotal,
          'created_at': selectedDate.toIso8601String(),
        });

        for (final row in rows.skip(1)) {
          await txn.insert('transactions', {
            'parchi_id': pavtiId,
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
              await txn.insert('transaction_expenses', {
                'parchi_id': pavtiId,
                'expense_type_id': exp.id,
                'amount': amount,
                'created_at': DateTime.now().toIso8601String(),
              });
            }
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('पावती सेव झाली! पावती नंबर: $pavtiId')),
      );

      _resetForm();
    } catch (e) {
      print("Save error: $e");
      _showSnackBar("पावती सेव करण्यात त्रुटी: $e");
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
        title: const Text('नवीन पावती'), // नवीन नाम
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
                  // Farmer + Date in one line (compact)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8), // स्पेस कमी
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: farmerCodeCtrl,
                              focusNode: farmerCodeFocus,
                              decoration: const InputDecoration(
                                labelText: 'शेतकरी कोड',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: lookupFarmer,
                              onSubmitted: (_) => _handleFarmerCodeEnter(),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: farmerNameCtrl,
                              enabled: farmerNameEditable,
                              decoration: const InputDecoration(
                                labelText: 'शेतकरी नाव',
                                border: OutlineInputBorder(),
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                          Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Entry Table (ऑटो स्क्रॉल)
                  if (rows.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8), // स्पेस कमी
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('वर्तमान पावती',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green)),
                            const SizedBox(height: 8),
                            SizedBox(
                              height:
                                  200, // 6-7 एंट्रीसाठी हाइट – जास्त झालं तर स्क्रॉल
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
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
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Produce + Trader in one line (compact)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: produceCodeCtrl,
                              focusNode: produceCodeFocus,
                              decoration: const InputDecoration(
                                labelText: 'माल कोड',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: lookupProduce,
                              onSubmitted: (_) => _handleProduceCodeEnter(),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                          const SizedBox(width: 8),
                          Switch(
                            value: produceLocked,
                            onChanged: (value) =>
                                setState(() => produceLocked = value),
                            activeColor: Colors.green,
                          ),
                          const Text('लॉक'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: traderCodeCtrl,
                              focusNode: traderCodeFocus,
                              decoration: const InputDecoration(
                                labelText: 'व्यापारी कोड',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: lookupTrader,
                              onSubmitted: (_) => _handleTraderCodeEnter(),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Dag + Weight + Bhav in one line + Add (compact)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: dagCtrl,
                              focusNode: dagFocus,
                              decoration: const InputDecoration(
                                labelText: 'डाग',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onSubmitted: (_) => _handleDagEnter(),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: weightCtrl,
                              focusNode: weightFocus,
                              decoration: const InputDecoration(
                                labelText: 'वजन / नग',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onSubmitted: (_) => _handleWeightEnter(),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: rateCtrl,
                              focusNode: rateFocus,
                              decoration: const InputDecoration(
                                labelText: 'भाव',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onSubmitted: (_) => _handleRateEnter(),
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Expenses Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8), // स्पेस कमी केली
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => setState(
                                () => expenseExpanded = !expenseExpanded),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'खर्च तपशील',
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
                                      onChanged: (value) => setState(
                                          () => expenseExpanded = value),
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (expenseExpanded) ...[
                            const SizedBox(height: 12),
                            if (expenseItems.isEmpty)
                              const Center(
                                  child:
                                      Text('कोणतेही खर्च प्रकार उपलब्ध नाहीत')),
                            ...expenseItems
                                .where((exp) => exp.applyOn == 'farmer')
                                .map((exp) {
                              final enteredValue =
                                  double.tryParse(exp.controller.text) ??
                                      exp.defaultValue;
                              double calculatedAmount = 0.0;

                              double totalDag =
                                  rows.fold(0, (s, r) => s + r.dag);
                              double totalWeight =
                                  rows.fold(0, (s, r) => s + r.weight);
                              double totalAmt = totalAmount;

                              double unitSize =
                                  exp.unitSize > 0 ? exp.unitSize : 1.0;

                              switch (exp.calculationType) {
                                case 'per_unit':
                                  calculatedAmount =
                                      (totalWeight / unitSize) * enteredValue;
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
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        '${exp.name} (${exp.calculationType == 'per_unit' ? 'प्रति युनिट' : exp.calculationType == 'per_bag' ? 'प्रति डाग' : 'टक्केवारी'})',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
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
                                            color: Color.fromARGB(
                                                255, 46, 125, 50)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 12),
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
                    label: const Text('नवी पावती'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveTransaction,
                    icon: const Icon(Icons.save),
                    label: const Text('पावती सेव करा',
                        style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // पुढील पावती – नवी रीसेट करून तयार कर
                      _resetForm();
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('पुढील'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // मागील पावती – पावती यादी उघड
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PavtiListScreen()),
                      );
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('मागील'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
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
