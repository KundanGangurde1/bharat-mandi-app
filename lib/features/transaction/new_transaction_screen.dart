import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/powersync_service.dart';
import '../../core/services/firm_data_service.dart'; // ✅ NEW
import '../../core/utils/commission_helper.dart'; // ✅ NEW: Commission helper
import '../transaction/pavti_list_screen.dart';

class TransactionRow {
  String buyerCode;
  String buyerName;
  String produceCode;
  String produceName;
  double dag;
  double weight;
  double rate;
  double total;

  TransactionRow({
    required this.buyerCode,
    required this.buyerName,
    required this.produceCode,
    required this.produceName,
    required this.dag,
    required this.weight,
    required this.rate,
  }) : total = weight * rate;
}

class ExpenseItem {
  final String id;
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
  final String? parchiId;
  final bool isEdit;

  const NewTransactionScreen({
    super.key,
    this.parchiId,
    this.isEdit = false,
  });

  @override
  State<NewTransactionScreen> createState() => _NewTransactionScreenState();
}

class _NewTransactionScreenState extends State<NewTransactionScreen> {
  int? editingIndex;

  // Controllers
  final farmerCodeCtrl = TextEditingController();
  final farmerNameCtrl = TextEditingController();
  final produceCodeCtrl = TextEditingController();
  final produceNameCtrl = TextEditingController();
  final buyerCodeCtrl = TextEditingController();
  final buyerNameCtrl = TextEditingController();
  final dagCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final rateCtrl = TextEditingController();

  // Focus Nodes
  final farmerCodeFocus = FocusNode();
  final produceCodeFocus = FocusNode();
  final buyerCodeFocus = FocusNode();
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

    if (widget.isEdit && widget.parchiId != null) {
      _loadExistingPavti();
    }
  }

  Future<void> _loadExpenseTypes() async {
    try {
      // ✅ NEW: Load active expense types for active firm
      final firmId = await FirmDataService.getActiveFirmId();
      final data = await powerSyncDB.getAll(
        'SELECT * FROM expense_types WHERE firm_id = ? AND active = 1 ORDER BY name ASC',
        [firmId],
      );

      setState(() {
        expenseItems = data.map((row) {
          return ExpenseItem(
            id: row['id'] as String,
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

      print('✅ Loaded ${expenseItems.length} expense types');
    } catch (e) {
      print("❌ Expense types load error: $e");
      _showSnackBar("खर्च प्रकार लोड करण्यात त्रुटी: $e");
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

    buyerCodeFocus.addListener(() {
      if (buyerCodeFocus.hasFocus) {
        buyerCodeCtrl.selection = TextSelection(
            baseOffset: 0, extentOffset: buyerCodeCtrl.text.length);
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

  String _getCalculationTypeDisplay(String type) {
    switch (type) {
      case 'per_unit':
        return 'प्रति युनिट';
      case 'per_dag':
        return 'प्रति डाग';
      case 'percentage':
        return 'टक्केवारी';
      case 'fixed':
        return 'फिक्स्ड';
      case 'pavti_nusar':
        return 'पावती नुसार';
      default:
        return type;
    }
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
      // ✅ NEW: Lookup farmer by code for active firm
      final firmId = await FirmDataService.getActiveFirmId();
      final data = await powerSyncDB.getAll(
        'SELECT * FROM farmers WHERE firm_id = ? AND code = ? AND active = 1',
        [firmId, code],
      );

      setState(() {
        if (data.isEmpty) {
          farmerNameCtrl.text = "";
          farmerNameEditable = false;
        } else {
          farmerNameCtrl.text = data.first['name'].toString();
          farmerNameEditable = false;
        }
      });
    } catch (e) {
      print("❌ Farmer lookup error: $e");
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
      // ✅ NEW: Lookup produce by code for active firm
      final firmId = await FirmDataService.getActiveFirmId();
      final data = await powerSyncDB.getAll(
        'SELECT * FROM produce WHERE firm_id = ? AND code = ? AND active = 1',
        [firmId, code],
      );

      setState(() {
        if (data.isEmpty) {
          produceNameCtrl.text = "";
        } else {
          produceNameCtrl.text = data.first['name'].toString();
        }
      });
    } catch (e) {
      print("❌ Produce lookup error: $e");
    }
  }

  Future<void> lookupBuyer(String code) async {
    code = code.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        buyerNameCtrl.text = "";
      });
      return;
    }
    if (code == "R") {
      setState(() {
        buyerNameCtrl.text = "रोकडा (Cash)";
      });
      return;
    }
    try {
      // ✅ NEW: Lookup buyer by code for active firm
      final firmId = await FirmDataService.getActiveFirmId();
      final data = await powerSyncDB.getAll(
        'SELECT * FROM buyers WHERE firm_id = ? AND code = ? AND active = 1',
        [firmId, code],
      );

      setState(() {
        if (data.isEmpty) {
          buyerNameCtrl.text = "";
        } else {
          buyerNameCtrl.text = data.first['name'].toString();
        }
      });
    } catch (e) {
      print("❌ Buyer lookup error: $e");
    }
  }

  // Calculations
  double get totalAmount => rows.fold(0, (sum, row) => sum + row.total);

  double get totalExpense {
    if (!expenseExpanded || expenseItems.isEmpty) return 0;

    double sum = 0;
    double totalDag = rows.fold(0, (s, r) => s + r.dag);
    double totalAmt = totalAmount;

    for (var exp in expenseItems) {
      // फक्त farmer खर्च net मधून वजा कर
      if (exp.applyOn != 'farmer') continue;

      final entered = double.tryParse(exp.controller.text) ?? exp.defaultValue;
      if (entered <= 0) continue;

      double calculated = 0.0;
      switch (exp.calculationType) {
        case 'per_dag':
          calculated = totalDag * entered;
          break;
        case 'percentage':
          calculated = totalAmt * (entered / 100);
          break;
        case 'fixed':
        case 'pavti_nusar':
          calculated = entered;
          break;
        default:
          calculated = 0.0;
      }
      sum += calculated;
    }
    return sum;
  }

  double get netTotal => totalAmount - totalExpense;

  // ================= BUYER CALCULATION HELPERS =================

  double buyerGross(String buyerCode) {
    return rows
        .where((r) => r.buyerCode == buyerCode)
        .fold(0.0, (sum, r) => sum + r.total);
  }

  double buyerTotalDag(String buyerCode) {
    return rows
        .where((r) => r.buyerCode == buyerCode)
        .fold(0.0, (sum, r) => sum + r.dag);
  }

  double buyerTotalWeight(String buyerCode) {
    return rows
        .where((r) => r.buyerCode == buyerCode)
        .fold(0.0, (sum, r) => sum + r.weight);
  }

  double buyerExpense(String buyerCode) {
    if (!expenseExpanded) return 0;

    final gross = buyerGross(buyerCode);
    final totalDag = buyerTotalDag(buyerCode);
    final totalWeight = buyerTotalWeight(buyerCode);

    double sum = 0;

    for (var exp in expenseItems.where((e) => e.applyOn == 'buyer')) {
      final entered = double.tryParse(exp.controller.text) ?? exp.defaultValue;
      if (entered <= 0) continue;

      switch (exp.calculationType) {
        case 'percentage':
          sum += gross * (entered / 100);
          break;

        case 'per_dag':
          sum += totalDag * entered;
          break;

        case 'per_unit':
          sum += totalWeight * entered;
          break;

        case 'fixed':
        case 'pavti_nusar':
          sum += entered;
          break;
      }
    }

    return sum;
  }

  // ================= BUYER / FARMER SPLIT =================

  double get totalFarmerExpense {
    if (!expenseExpanded || expenseItems.isEmpty) return 0;

    double sum = 0;
    double totalDag = rows.fold(0, (s, r) => s + r.dag);
    double totalAmt = totalAmount;

    for (var exp in expenseItems.where((e) => e.applyOn == 'farmer')) {
      final entered = double.tryParse(exp.controller.text) ?? exp.defaultValue;
      if (entered <= 0) continue;

      switch (exp.calculationType) {
        case 'per_dag':
          sum += totalDag * entered;
          break;
        case 'percentage':
          sum += totalAmt * (entered / 100);
          break;
        case 'fixed':
        case 'pavti_nusar':
          sum += entered;
          break;
      }
    }
    return sum;
  }

  double get totalBuyerExpense {
    if (!expenseExpanded || expenseItems.isEmpty) return 0;

    double sum = 0;
    double totalDag = rows.fold(0, (s, r) => s + r.dag);
    double totalAmt = totalAmount;

    for (var exp in expenseItems.where((e) => e.applyOn == 'buyer')) {
      final entered = double.tryParse(exp.controller.text) ?? exp.defaultValue;
      if (entered <= 0) continue;

      switch (exp.calculationType) {
        case 'per_dag':
          sum += totalDag * entered;
          break;
        case 'percentage':
          sum += totalAmt * (entered / 100);
          break;
        case 'fixed':
        case 'pavti_nusar':
          sum += entered;
          break;
      }
    }
    return sum;
  }

  double get farmerNet => totalAmount - totalFarmerExpense;
  double get buyerNet => totalAmount + totalBuyerExpense;

  // Keyboard Flow
  void _handleFarmerCodeEnter() {
    if (farmerCodeCtrl.text.isNotEmpty)
      FocusScope.of(context).requestFocus(produceCodeFocus);
  }

  void _handleProduceCodeEnter() {
    if (produceCodeCtrl.text.isNotEmpty)
      FocusScope.of(context).requestFocus(buyerCodeFocus);
  }

  void _handleBuyerCodeEnter() {
    if (buyerCodeCtrl.text.isNotEmpty)
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
    if (buyerCodeCtrl.text.isEmpty || buyerNameCtrl.text.isEmpty) {
      _showSnackBar("व्यापारी कोड आवश्यक आहे");
      buyerCodeFocus.requestFocus();
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
      if (editingIndex != null) {
        rows[editingIndex!] = TransactionRow(
          buyerCode: buyerCodeCtrl.text.trim().toUpperCase(),
          buyerName: buyerNameCtrl.text,
          produceCode: produceCodeCtrl.text.trim().toUpperCase(),
          produceName: produceNameCtrl.text,
          dag: dag,
          weight: weight,
          rate: rate,
        );
        editingIndex = null;
      } else {
        rows.add(TransactionRow(
          buyerCode: buyerCodeCtrl.text.trim().toUpperCase(),
          buyerName: buyerNameCtrl.text,
          produceCode: produceCodeCtrl.text.trim().toUpperCase(),
          produceName: produceNameCtrl.text,
          dag: dag,
          weight: weight,
          rate: rate,
        ));
      }

      buyerCodeCtrl.clear();
      buyerNameCtrl.clear();
      dagCtrl.clear();
      weightCtrl.clear();
      rateCtrl.clear();

      if (!produceLocked) {
        produceCodeCtrl.clear();
        produceNameCtrl.clear();
      }
    });

    produceLocked
        ? buyerCodeFocus.requestFocus()
        : produceCodeFocus.requestFocus();
    _showSnackBar("एंट्री जोडली गेली", isError: false);
  }

  void _editRow(int index) {
    final row = rows[index];

    setState(() {
      editingIndex = index;

      buyerCodeCtrl.text = row.buyerCode;
      buyerNameCtrl.text = row.buyerName;
      produceCodeCtrl.text = row.produceCode;
      produceNameCtrl.text = row.produceName;
      dagCtrl.text = row.dag.toString();
      weightCtrl.text = row.weight.toString();
      rateCtrl.text = row.rate.toString();
    });
  }

  Future<bool> _validateFarmerBeforeSave() async {
    final farmerCode = farmerCodeCtrl.text.trim().toUpperCase();
    final farmerName = farmerNameCtrl.text.trim();

    if (farmerCode.isEmpty) {
      _showSnackBar('शेतकरी कोड आवश्यक आहे');
      return false;
    }

    if (farmerCode == '100') {
      if (farmerName.isEmpty) {
        _showSnackBar('100 कोडसाठी शेतकरी नाव टाका');
        return false;
      }
      return true;
    }

    final firmId = await FirmDataService.getActiveFirmId();
    final data = await powerSyncDB.getAll(
      'SELECT name FROM farmers WHERE firm_id = ? AND code = ? AND active = 1 LIMIT 1',
      [firmId, farmerCode],
    );

    if (data.isEmpty) {
      _showSnackBar(
          '100 कोड वापरून नवीन नाव टाका किंवा विद्यमान शेतकरी कोड टाका');
      return false;
    }

    setState(() {
      farmerNameCtrl.text = data.first['name']?.toString() ?? '';
      farmerNameEditable = false;
    });
    return true;
  }

  // Save Transaction
  Future<void> _saveTransaction() async {
    final farmerOk = await _validateFarmerBeforeSave();
    if (!farmerOk) return;

    if (rows.isEmpty) {
      _showSnackBar("किमान एक एंट्री आवश्यक आहे");
      return;
    }

    try {
      String parchiId;

      // ================= EDIT MODE =================
      if (widget.isEdit && widget.parchiId != null) {
        parchiId = widget.parchiId!;

        // 🔥 Delete old transactions for active firm
        final firmId2 = await FirmDataService.getActiveFirmId();
        await powerSyncDB.execute(
          'DELETE FROM transactions WHERE firm_id = ? AND parchi_id = ?',
          [firmId2, parchiId],
        );

        await powerSyncDB.execute(
          'DELETE FROM transaction_expenses WHERE firm_id = ? AND parchi_id = ?',
          [firmId2, parchiId],
        );

        print("✏️ Editing Existing Pavti: $parchiId");
      } else {
        // ================= NEW MODE =================
        // ✅ NEW: Get last parchi_id for active firm
        final firmId = await FirmDataService.getActiveFirmId();
        final lastParchi = await powerSyncDB.getAll(
          'SELECT MAX(CAST(parchi_id AS INTEGER)) as max_id FROM transactions WHERE firm_id = ?',
          [firmId],
        );

        int newBillNo = 1;
        if (lastParchi.isNotEmpty && lastParchi.first['max_id'] != null) {
          newBillNo = (lastParchi.first['max_id'] as int) + 1;
        }

        parchiId = newBillNo.toString();

        print("🆕 New Bill Number: $parchiId");
      }

      final now = DateTime.now().toIso8601String();

      // ================= INSERT ROWS =================
      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];

        double buyerExpense = 0;
        double farmerExpense = 0;

        double buyerDag = row.dag;
        double buyerQty = row.weight;
        double buyerGross = row.total;

        final firmId = await FirmDataService.getActiveFirmId();

        // ✅ STEP 1: Check produce commission type (TAP A or TAP B)
        final commissionDetails = await CommissionHelper.getCommissionDetails(
          produceCode: row.produceCode,
          firmId: firmId ?? '',
        );

        final commissionType =
            commissionDetails?['commission_type'] ?? 'DEFAULT';

        // ✅ STEP 2: Apply commission based on type (ONLY for "कमिशन")
        if (commissionType == 'PER_PRODUCE') {
          // ===== TAP A ACTIVE: PRODUCE-SPECIFIC COMMISSION =====
          print(
              '🔴 TAP A ACTIVE: Using produce-specific commission for ${row.produceCode}');

          final buyerCommission = await CommissionHelper.applyProduceCommission(
            produceCode: row.produceCode,
            itemAmount: buyerGross,
            applyOn: 'buyer',
            firmId: firmId ?? '',
          );
          buyerExpense += buyerCommission;

          final farmerCommission =
              await CommissionHelper.applyProduceCommission(
            produceCode: row.produceCode,
            itemAmount: buyerGross,
            applyOn: 'farmer',
            firmId: firmId ?? '',
          );
          farmerExpense += farmerCommission;
        } else {
          // ===== TAP B ACTIVE: EXPENSE TYPE COMMISSION (कमिशन) =====
          print(
              '🟢 TAP B ACTIVE: Using expense type commission for ${row.produceCode}');

          // Apply "कमिशन" expense commission to buyer
          final buyerCommission =
              await CommissionHelper.applyExpenseTypeCommission(
            itemAmount: buyerGross,
            applyOn: 'buyer',
            firmId: firmId ?? '',
          );
          buyerExpense += buyerCommission;

          // Apply "कमिशन" expense commission to farmer (if any)
          final farmerCommission =
              await CommissionHelper.applyExpenseTypeCommission(
            itemAmount: buyerGross,
            applyOn: 'farmer',
            firmId: firmId ?? '',
          );
          farmerExpense += farmerCommission;
        }

        // ✅ STEP 3: Apply ALL OTHER EXPENSES (non-commission)
        // These apply regardless of TAP A or TAP B
        print('📋 Applying other expenses...');

        for (var exp in expenseItems) {
          // Skip "कमिशन" expense (already handled above)
          if (exp.name.trim() == 'कमिशन') {
            print(
                '⏭️ Skipping कमिशन expense (already applied via commission logic)');
            continue;
          }

          final entered =
              double.tryParse(exp.controller.text) ?? exp.defaultValue;
          if (entered <= 0) continue;

          double calc = 0;

          switch (exp.calculationType) {
            case 'per_dag':
              calc = buyerDag * entered;
              break;
            case 'per_unit':
              calc = buyerQty * entered;
              break;
            case 'fixed':
            case 'pavti_nusar':
              calc = entered;
              break;
            case 'percentage':
              calc = buyerGross * (entered / 100);
              break;
          }

          if (exp.applyOn == 'buyer') {
            buyerExpense += calc;
          } else if (exp.applyOn == 'farmer') {
            farmerExpense += calc;
          }
        }

        final buyerNet = buyerGross + buyerExpense;

        // ✅ STEP 4: Insert transaction with both buyer and farmer expenses
        final transactionData = {
          'parchi_id': parchiId,
          'farmer_code': farmerCodeCtrl.text.trim().toUpperCase(),
          'farmer_name': farmerNameCtrl.text,
          'buyer_code': row.buyerCode,
          'buyer_name': row.buyerName,
          'produce_code': row.produceCode,
          'produce_name': row.produceName,
          'dag': row.dag,
          'quantity': row.weight,
          'rate': row.rate,
          'gross': buyerGross,
          'total_expense': buyerExpense,
          'net': buyerNet,
          'farmer_expense': farmerExpense, // ✅ NEW: Farmer expense
          'created_at': selectedDate.toIso8601String(),
          'updated_at': now,
        };

        await FirmDataService.insertRecordWithFirmId(
            'transactions', transactionData);
        print(
            '✅ Transaction row saved: buyer_expense=$buyerExpense, farmer_expense=$farmerExpense');
      }

      // ================= INSERT EXPENSES =================
      if (expenseExpanded && expenseItems.isNotEmpty) {
        for (var exp in expenseItems) {
          final amount =
              double.tryParse(exp.controller.text) ?? exp.defaultValue;
          if (amount > 0) {
            // ✅ NEW: Insert with firm_id
            final expenseData = {
              'parchi_id': parchiId,
              'expense_type_id': exp.id,
              'amount': amount,
              'created_at': now,
              'updated_at': now,
            };
            await FirmDataService.insertRecordWithFirmId(
                'transaction_expenses', expenseData);
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('पावती नं. $parchiId यशस्वीरित्या सेव्ह झाली!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // 🔥 Return to list after save
    } catch (e) {
      print('❌ Save error: $e');
      print('⚠️ Check if active firm is set');
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
      buyerCodeCtrl.clear();
      buyerNameCtrl.clear();
      dagCtrl.clear();
      weightCtrl.clear();
      rateCtrl.clear();
      produceLocked = false;
      farmerNameEditable = false;
      expenseExpanded = false;
      selectedDate = DateTime.now();
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
        title: Text(widget.isEdit ? 'पावती एडिट' : 'नवीन पावती'),
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
                      padding: const EdgeInsets.all(8),
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

                  // Entry Table
                  if (rows.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
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
                              height: 200,
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
                                      DataColumn(label: Text('क्रिया')),
                                    ],
                                    rows: rows.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final row = entry.value;

                                      return DataRow(
                                        cells: [
                                          DataCell(Text(row.buyerName)),
                                          DataCell(Text(row.produceName)),
                                          DataCell(
                                              Text(row.dag.toStringAsFixed(0))),
                                          DataCell(Text(row.weight.toString())),
                                          DataCell(Text(
                                              '₹${row.rate.toStringAsFixed(2)}')),
                                          DataCell(Text(
                                              '₹${row.total.toStringAsFixed(2)}')),
                                          DataCell(Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit,
                                                    size: 18,
                                                    color: Colors.blue),
                                                onPressed: () =>
                                                    _editRow(index),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    size: 18,
                                                    color: Colors.red),
                                                onPressed: () {
                                                  setState(() {
                                                    rows.removeAt(index);
                                                  });
                                                },
                                              ),
                                            ],
                                          )),
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

                  // Produce + buyer in one line (compact)
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
                            activeThumbColor: Colors.green,
                          ),
                          const Text('लॉक'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: buyerCodeCtrl,
                              focusNode: buyerCodeFocus,
                              decoration: const InputDecoration(
                                labelText: 'व्यापारी कोड',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: lookupBuyer,
                              onSubmitted: (_) => _handleBuyerCodeEnter(),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: buyerNameCtrl,
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                            ),
                            child: const Text('जोडा'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Expenses Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
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
                                      activeThumbColor: Colors.green,
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
                                case 'per_dag':
                                  calculatedAmount = totalDag * enteredValue;
                                  break;
                                case 'percentage':
                                  calculatedAmount =
                                      totalAmt * (enteredValue / 100);
                                  break;
                                case 'fixed':
                                case 'pavti_nusar':
                                  calculatedAmount = enteredValue;
                                  break;
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        '${exp.name} (${_getCalculationTypeDisplay(exp.calculationType)})',
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
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 8),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 8),
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '₹${calculatedAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PavtiListScreen()),
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

  Future<void> _loadExistingPavti() async {
    try {
      final data = await powerSyncDB.getAll(
        'SELECT * FROM transactions WHERE parchi_id = ? ORDER BY id ASC',
        [widget.parchiId],
      );

      if (data.isEmpty) return;

      final first = data.first;

      setState(() {
        farmerCodeCtrl.text = first['farmer_code'] ?? '';
        farmerNameCtrl.text = first['farmer_name'] ?? '';
        selectedDate = DateTime.parse(first['created_at']);

        rows = data.map((row) {
          return TransactionRow(
            buyerCode: row['buyer_code'],
            buyerName: row['buyer_name'],
            produceCode: row['produce_code'],
            produceName: row['produce_name'],
            dag: (row['dag'] as num).toDouble(),
            weight: (row['quantity'] as num).toDouble(),
            rate: (row['rate'] as num).toDouble(),
          );
        }).toList();
      });
    } catch (e) {
      print("❌ Edit load error: $e");
    }
  }

  @override
  void dispose() {
    farmerCodeCtrl.dispose();
    farmerNameCtrl.dispose();
    produceCodeCtrl.dispose();
    produceNameCtrl.dispose();
    buyerCodeCtrl.dispose();
    buyerNameCtrl.dispose();
    dagCtrl.dispose();
    weightCtrl.dispose();
    rateCtrl.dispose();

    farmerCodeFocus.dispose();
    produceCodeFocus.dispose();
    buyerCodeFocus.dispose();
    dagFocus.dispose();
    weightFocus.dispose();
    rateFocus.dispose();

    for (var exp in expenseItems) {
      exp.controller.dispose();
    }

    super.dispose();
  }
}
