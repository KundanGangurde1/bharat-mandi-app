import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/db_service.dart';

class TransactionRow {
  String traderCode;
  String traderName;
  String produceCode;
  String produceName;
  double weight;
  double rate;
  double total;

  TransactionRow({
    required this.traderCode,
    required this.traderName,
    required this.produceCode,
    required this.produceName,
    required this.weight,
    required this.rate,
  }) : total = weight * rate;
}

class NewTransactionScreen extends StatefulWidget {
  const NewTransactionScreen({super.key});

  @override
  State<NewTransactionScreen> createState() => _NewTransactionScreenState();
}

class _NewTransactionScreenState extends State<NewTransactionScreen> {
  // ================= CONTROLLERS =================
  final farmerCodeCtrl = TextEditingController();
  final farmerNameCtrl = TextEditingController();
  final produceCodeCtrl = TextEditingController();
  final produceNameCtrl = TextEditingController();
  final traderCodeCtrl = TextEditingController();
  final traderNameCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final rateCtrl = TextEditingController();

  // Expense controllers
  final hamaliCtrl = TextEditingController();
  final tolaiCtrl = TextEditingController();
  final advanceCtrl = TextEditingController();
  final otherCtrl = TextEditingController();

  // ================= FOCUS NODES (Keyboard Flow) =================
  final farmerCodeFocus = FocusNode();
  final produceCodeFocus = FocusNode();
  final traderCodeFocus = FocusNode();
  final weightFocus = FocusNode();
  final rateFocus = FocusNode();

  // ================= STATE VARIABLES =================
  DateTime selectedDate = DateTime.now();
  bool farmerNameEditable = false;
  bool produceLocked = false;
  bool expenseExpanded = false;

  List<TransactionRow> rows = [];
  final ScrollController _tableScrollController = ScrollController();

  // ================= LIFECYCLE =================
  @override
  void initState() {
    super.initState();

    // Setup keyboard flow
    _setupKeyboardFlow();
  }

  void _setupKeyboardFlow() {
    farmerCodeFocus.addListener(() {
      if (farmerCodeFocus.hasFocus) {
        farmerCodeCtrl.selection = TextSelection(
          baseOffset: 0,
          extentOffset: farmerCodeCtrl.text.length,
        );
      }
    });

    produceCodeFocus.addListener(() {
      if (produceCodeFocus.hasFocus) {
        produceCodeCtrl.selection = TextSelection(
          baseOffset: 0,
          extentOffset: produceCodeCtrl.text.length,
        );
      }
    });

    traderCodeFocus.addListener(() {
      if (traderCodeFocus.hasFocus) {
        traderCodeCtrl.selection = TextSelection(
          baseOffset: 0,
          extentOffset: traderCodeCtrl.text.length,
        );
      }
    });

    weightFocus.addListener(() {
      if (weightFocus.hasFocus) {
        weightCtrl.selection = TextSelection(
          baseOffset: 0,
          extentOffset: weightCtrl.text.length,
        );
      }
    });

    rateFocus.addListener(() {
      if (rateFocus.hasFocus) {
        rateCtrl.selection = TextSelection(
          baseOffset: 0,
          extentOffset: rateCtrl.text.length,
        );
      }
    });
  }

  // ================= LOOKUP METHODS =================
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
      final data = await db.query(
        'farmers',
        where: 'code = ? AND active = 1',
        whereArgs: [code],
      );

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
      final data = await db.query(
        'produce',
        where: 'code = ? AND active = 1',
        whereArgs: [code],
      );

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
      final data = await db.query(
        'traders',
        where: 'code = ? AND active = 1',
        whereArgs: [code],
      );

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

  // ================= CALCULATION METHODS =================
  double get totalAmount {
    return rows.fold(0, (sum, row) => sum + row.total);
  }

  double get totalExpense {
    if (!expenseExpanded) return 0;

    double hamali = double.tryParse(hamaliCtrl.text) ?? 0;
    double tolai = double.tryParse(tolaiCtrl.text) ?? 0;
    double advance = double.tryParse(advanceCtrl.text) ?? 0;
    double other = double.tryParse(otherCtrl.text) ?? 0;

    return hamali + tolai + advance + other;
  }

  double get netTotal {
    return totalAmount - totalExpense;
  }

  // ================= KEYBOARD FLOW METHODS =================
  void _handleFarmerCodeEnter() {
    if (farmerCodeCtrl.text.isNotEmpty) {
      FocusScope.of(context).requestFocus(produceCodeFocus);
    }
  }

  void _handleProduceCodeEnter() {
    if (produceCodeCtrl.text.isNotEmpty) {
      FocusScope.of(context).requestFocus(traderCodeFocus);
    }
  }

  void _handleTraderCodeEnter() {
    if (traderCodeCtrl.text.isNotEmpty) {
      FocusScope.of(context).requestFocus(weightFocus);
    }
  }

  void _handleWeightEnter() {
    if (weightCtrl.text.isNotEmpty) {
      FocusScope.of(context).requestFocus(rateFocus);
    }
  }

  void _handleRateEnter() {
    if (rateCtrl.text.isNotEmpty) {
      _addRow();
    }
  }

  // ================= ADD ROW =================
  void _addRow() {
    // Validate trader
    if (traderCodeCtrl.text.isEmpty || traderNameCtrl.text.isEmpty) {
      _showSnackBar("व्यापारी कोड आवश्यक आहे");
      traderCodeFocus.requestFocus();
      return;
    }

    // Validate produce
    if (produceCodeCtrl.text.isEmpty || produceNameCtrl.text.isEmpty) {
      _showSnackBar("माल कोड आवश्यक आहे");
      produceCodeFocus.requestFocus();
      return;
    }

    // Validate weight and rate
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

    // Add to rows
    setState(() {
      rows.add(TransactionRow(
        traderCode: traderCodeCtrl.text.trim().toUpperCase(),
        traderName: traderNameCtrl.text,
        produceCode: produceCodeCtrl.text.trim().toUpperCase(),
        produceName: produceNameCtrl.text,
        weight: weight,
        rate: rate,
      ));

      // Clear trader fields for next entry
      traderCodeCtrl.clear();
      traderNameCtrl.clear();
      weightCtrl.clear();
      rateCtrl.clear();

      // Clear produce only if not locked
      if (!produceLocked) {
        produceCodeCtrl.clear();
        produceNameCtrl.clear();
      }
    });

    // Auto scroll table to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tableScrollController.hasClients) {
        _tableScrollController.animateTo(
          _tableScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Move focus according to keyboard flow
    if (produceLocked) {
      // Flow: Trader Code → Weight → Rate → Trader Code
      traderCodeFocus.requestFocus();
    } else {
      // Flow: Produce Code → Trader Code → Weight → Rate → Produce Code
      produceCodeFocus.requestFocus();
    }

    _showSnackBar("एंट्री जोडली गेली");
  }

  // ================= SAVE TRANSACTION =================
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
          'quantity': row.weight,
          'rate': row.rate,
          'gross': row.total,
          'hamali': double.tryParse(hamaliCtrl.text) ?? 0,
          'tolai': double.tryParse(tolaiCtrl.text) ?? 0,
          'advance': double.tryParse(advanceCtrl.text) ?? 0,
          'other_expense': double.tryParse(otherCtrl.text) ?? 0,
          'total_expense': totalExpense,
          'net': netTotal,
          'created_at': selectedDate.toIso8601String(),
        });
      }

      _showSnackBar("पर्ची सेव झाली! एकूण एंट्री: ${rows.length}",
          isError: false);

      // Reset form
      _resetForm();
    } catch (e) {
      print("Save error: $e");
      _showSnackBar("सेम त्रुटी: $e");
    }
  }

  // ================= RESET FORM =================
  void _resetForm() {
    setState(() {
      rows.clear();
      farmerCodeCtrl.clear();
      farmerNameCtrl.clear();
      produceCodeCtrl.clear();
      produceNameCtrl.clear();
      traderCodeCtrl.clear();
      traderNameCtrl.clear();
      weightCtrl.clear();
      rateCtrl.clear();
      hamaliCtrl.clear();
      tolaiCtrl.clear();
      advanceCtrl.clear();
      otherCtrl.clear();
      produceLocked = false;
      farmerNameEditable = false;
      expenseExpanded = false;
    });

    // Reset focus to farmer code
    farmerCodeFocus.requestFocus();
  }

  // ================= HELPER METHODS =================
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ================= BUILD METHOD =================
  @override
  Widget build(BuildContext context) {
    // Calculate table height based on rows (max 3 rows visible)
    double tableHeight =
        rows.isEmpty ? 0 : (rows.length > 3 ? 100 : rows.length * 32.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('नवीन पर्ची'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ============ HEADER AND DATE ============
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.green[50],
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.calendar_today, size: 20),
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
                const SizedBox(width: 8),
                Text(
                  'तारीख: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.info, size: 20),
                  onPressed: () {
                    _showSnackBar(
                        "फ्लो: शेतकरी → माल → व्यापारी → वजन → भाव → जोडा");
                  },
                ),
              ],
            ),
          ),

          // ============ COMPACT INPUT SECTION ============
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // Farmer Input Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 2),
                              child: Text(
                                'शेतकरी कोड',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            TextField(
                              controller: farmerCodeCtrl,
                              focusNode: farmerCodeFocus,
                              decoration: InputDecoration(
                                hintText: 'KM/100',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 14),
                              onChanged: lookupFarmer,
                              onSubmitted: (_) => _handleFarmerCodeEnter(),
                              textInputAction: TextInputAction.next,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 2),
                              child: Text(
                                'शेतकरी नाव',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            TextField(
                              controller: farmerNameCtrl,
                              enabled: farmerNameEditable,
                              decoration: InputDecoration(
                                hintText:
                                    farmerNameEditable ? 'नाव टाइप करा' : 'ऑटो',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 14),
                              textInputAction: TextInputAction.next,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 60,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 2),
                              child: Text(
                                'लॉक',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            Switch(
                              value: produceLocked,
                              onChanged: (value) {
                                setState(() => produceLocked = value);
                              },
                              activeColor: Colors.green,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Produce and Trader Input Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 2),
                              child: Text(
                                'माल कोड',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            TextField(
                              controller: produceCodeCtrl,
                              focusNode: produceCodeFocus,
                              decoration: InputDecoration(
                                hintText: 'AL',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 14),
                              onChanged: lookupProduce,
                              onSubmitted: (_) => _handleProduceCodeEnter(),
                              textInputAction: TextInputAction.next,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 2),
                              child: Text(
                                'माल नाव',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            TextField(
                              controller: produceNameCtrl,
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: 'ऑटो',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 2),
                              child: Text(
                                'व्यापारी कोड',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            TextField(
                              controller: traderCodeCtrl,
                              focusNode: traderCodeFocus,
                              decoration: InputDecoration(
                                hintText: 'ST/R',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 14),
                              onChanged: lookupTrader,
                              onSubmitted: (_) => _handleTraderCodeEnter(),
                              textInputAction: TextInputAction.next,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 2),
                              child: Text(
                                'व्यापारी नाव',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            TextField(
                              controller: traderNameCtrl,
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: 'ऑटो',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Weight, Rate and Add Button Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 2),
                              child: Text(
                                'वजन',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            TextField(
                              controller: weightCtrl,
                              focusNode: weightFocus,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'किलो',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 14),
                              onSubmitted: (_) => _handleWeightEnter(),
                              textInputAction: TextInputAction.next,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 2),
                              child: Text(
                                'भाव',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            TextField(
                              controller: rateCtrl,
                              focusNode: rateFocus,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '₹/किलो',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 14),
                              onSubmitted: (_) => _handleRateEnter(),
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 70,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 2),
                              child: Text(
                                'क्रिया',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _addRow,
                              child: const Text('जोडा',
                                  style: TextStyle(fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                minimumSize: const Size(0, 0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ============ CURRENT TRANSACTIONS TABLE (LIMITED HEIGHT) ============
          if (rows.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              height: tableHeight + 40, // Adding height for header
              child: Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'वर्तमान पर्ची',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'एकूण: ${rows.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        controller: _tableScrollController,
                        child: SingleChildScrollView(
                          controller: _tableScrollController,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 16,
                              horizontalMargin: 8,
                              dataRowHeight: 28,
                              headingRowHeight: 32,
                              columns: const [
                                DataColumn(
                                  label: SizedBox(
                                    width: 60,
                                    child: Text('व्यापारी',
                                        style: TextStyle(fontSize: 14)),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 50,
                                    child: Text('माल',
                                        style: TextStyle(fontSize: 14)),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 50,
                                    child: Text('वजन',
                                        style: TextStyle(fontSize: 14)),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 50,
                                    child: Text('भाव',
                                        style: TextStyle(fontSize: 14)),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 60,
                                    child: Text('रक्कम',
                                        style: TextStyle(fontSize: 14)),
                                  ),
                                ),
                              ],
                              rows: rows.map((row) {
                                return DataRow(
                                  cells: [
                                    DataCell(SizedBox(
                                      width: 60,
                                      child: Text(
                                        row.traderName,
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )),
                                    DataCell(SizedBox(
                                      width: 50,
                                      child: Text(
                                        row.produceName,
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )),
                                    DataCell(Text(
                                      row.weight.toStringAsFixed(2),
                                      style: const TextStyle(fontSize: 14),
                                    )),
                                    DataCell(Text(
                                      '₹${row.rate.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 14),
                                    )),
                                    DataCell(Text(
                                      '₹${row.total.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    )),
                                  ],
                                );
                              }).toList(),
                            ),
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

          // ============ EXPENSES SECTION ============
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'खर्च विवरण',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Row(
                        children: [
                          Text(expenseExpanded ? 'ON' : 'OFF',
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Switch(
                            value: expenseExpanded,
                            onChanged: (value) {
                              setState(() => expenseExpanded = value);
                            },
                            activeColor: Colors.green,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (expenseExpanded) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 2),
                                child: Text(
                                  'हमाली',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              TextField(
                                controller: hamaliCtrl,
                                decoration: InputDecoration(
                                  hintText: '₹',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 12),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 2),
                                child: Text(
                                  'तोलाई',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              TextField(
                                controller: tolaiCtrl,
                                decoration: InputDecoration(
                                  hintText: '₹',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 12),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 2),
                                child: Text(
                                  'अ‍ॅडव्हान्स',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              TextField(
                                controller: advanceCtrl,
                                decoration: InputDecoration(
                                  hintText: '₹',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 14),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 2),
                                child: Text(
                                  'इतर खर्च',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              TextField(
                                controller: otherCtrl,
                                decoration: InputDecoration(
                                  hintText: '₹',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 14),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ============ TOTALS SECTION ============
          Card(
            margin: const EdgeInsets.all(8),
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'एकूण रक्कम:',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          '₹${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'एकूण खर्च:',
                          style: TextStyle(
                            fontSize: 14,
                            color: expenseExpanded ? Colors.black : Colors.grey,
                          ),
                        ),
                        Text(
                          '₹${totalExpense.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: expenseExpanded ? Colors.red : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'शुद्ध रक्कम:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${netTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // ============ BOTTOM ACTION BUTTONS ============
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: const Border(
                top: BorderSide(color: Colors.grey, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _resetForm,
                    icon: const Icon(Icons.refresh, size: 16),
                    label:
                        const Text('नवी पर्ची', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _saveTransaction,
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text(
                      'पर्ची सेव करा',
                      style: TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
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

  // ================= DISPOSE =================
  @override
  void dispose() {
    // Dispose controllers
    farmerCodeCtrl.dispose();
    farmerNameCtrl.dispose();
    produceCodeCtrl.dispose();
    produceNameCtrl.dispose();
    traderCodeCtrl.dispose();
    traderNameCtrl.dispose();
    weightCtrl.dispose();
    rateCtrl.dispose();
    hamaliCtrl.dispose();
    tolaiCtrl.dispose();
    advanceCtrl.dispose();
    otherCtrl.dispose();

    // Dispose focus nodes
    farmerCodeFocus.dispose();
    produceCodeFocus.dispose();
    traderCodeFocus.dispose();
    weightFocus.dispose();
    rateFocus.dispose();

    // Dispose scroll controller
    _tableScrollController.dispose();

    super.dispose();
  }
}
