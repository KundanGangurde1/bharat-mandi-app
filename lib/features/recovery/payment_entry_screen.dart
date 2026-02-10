import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/powersync_service.dart';
import 'payment_model.dart';
import 'payment_detail_screen.dart';

class PaymentEntryScreen extends StatefulWidget {
  const PaymentEntryScreen({super.key});

  @override
  State<PaymentEntryScreen> createState() => _PaymentEntryScreenState();
}

class _PaymentEntryScreenState extends State<PaymentEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final buyerCodeCtrl = TextEditingController();
  final amountCtrl = TextEditingController();

  // Focus nodes for proper Enter flow
  late FocusNode buyerCodeFocus;
  late FocusNode amountFocus;

  String selectedPaymentMode = 'cash';
  String buyerName = '';
  String buyerCode = '';
  double openingBalance = 0.0;
  double remainingBalance = 0.0;
  bool isLoading = false;
  String? errorMessage;

  // Navigation state
  List<Payment> allPayments = [];
  int currentPaymentIndex = -1;
  Payment? currentPayment;

  final List<String> paymentModes = ['cash', 'bank', 'upi', 'cheque'];

  @override
  void initState() {
    super.initState();
    // Initialize focus nodes
    buyerCodeFocus = FocusNode();
    amountFocus = FocusNode();

    buyerCodeCtrl.addListener(_onBuyerCodeChanged);
    amountCtrl.addListener(_calculateRemainingBalance);
    _loadAllPayments();
  }

  @override
  void dispose() {
    buyerCodeCtrl.dispose();
    amountCtrl.dispose();
    buyerCodeFocus.dispose();
    amountFocus.dispose();
    super.dispose();
  }

  /// Load all payments for navigation
  Future<void> _loadAllPayments() async {
    try {
      final results = await powerSyncDB.getAll(
        'SELECT * FROM payments ORDER BY created_at DESC',
        [],
      );

      setState(() {
        allPayments = results.map((r) => Payment.fromMap(r)).toList();
      });
    } catch (e) {
      print('❌ Error loading payments: $e');
    }
  }

  /// Navigate to previous payment
  void _previousPayment() {
    if (currentPaymentIndex > 0) {
      setState(() {
        currentPaymentIndex--;
        currentPayment = allPayments[currentPaymentIndex];
        _loadPaymentToForm(currentPayment!);
      });
    }
  }

  /// Navigate to next payment
  void _nextPayment() {
    if (currentPaymentIndex < allPayments.length - 1) {
      setState(() {
        currentPaymentIndex++;
        currentPayment = allPayments[currentPaymentIndex];
        _loadPaymentToForm(currentPayment!);
      });
    }
  }

  /// Load payment data into form
  void _loadPaymentToForm(Payment payment) {
    buyerCodeCtrl.text = payment.buyer_code;
    amountCtrl.text = payment.amount.toString();
    selectedPaymentMode = payment.payment_mode;
    buyerName = payment.buyer_name;
    buyerCode = payment.buyer_code;
    _onBuyerCodeChanged();
  }

  /// Edit current payment
  void _editPayment() {
    if (currentPayment == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentDetailScreen(
          paymentId: currentPayment!.id ?? '',
          buyerCode: currentPayment!.buyer_code,
        ),
      ),
    ).then((_) {
      _loadAllPayments();
      setState(() {
        currentPayment = null;
        currentPaymentIndex = -1;
        buyerCodeCtrl.clear();
        amountCtrl.clear();
      });
    });
  }

  /// Delete current payment
  Future<void> _deletePayment() async {
    if (currentPayment == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('जमा हटवायचा?'),
        content: const Text('क्या आप यह जमा हटाना चाहते हैं?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('नाही'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('हो'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await deleteRecord('payments', currentPayment!.id ?? '');
      _showSnackBar('✅ जमा हटवला गेला', isSuccess: true);
      _loadAllPayments();
      setState(() {
        currentPayment = null;
        currentPaymentIndex = -1;
        buyerCodeCtrl.clear();
        amountCtrl.clear();
      });
    } catch (e) {
      _showSnackBar('त्रुटी: $e', isSuccess: false);
    }
  }

  /// Fetch buyer details when code is entered
  Future<void> _onBuyerCodeChanged() async {
    if (buyerCodeCtrl.text.isEmpty) {
      setState(() {
        buyerName = '';
        buyerCode = '';
        openingBalance = 0.0;
        remainingBalance = 0.0;
      });
      return;
    }

    try {
      final code = buyerCodeCtrl.text.trim().toUpperCase();

      // PowerSync: Query buyers table
      final results = await powerSyncDB.getAll(
        'SELECT * FROM buyers WHERE code = ? AND active = 1',
        [code],
      );

      if (results.isNotEmpty) {
        final buyer = results.first;
        final fetchedCode = buyer['code'] as String? ?? '';
        final name = buyer['name'] as String? ?? '';
        final balance = (buyer['opening_balance'] as num?)?.toDouble() ?? 0.0;

        // Calculate total payments for this buyer
        final paymentResults = await powerSyncDB.getAll(
          'SELECT SUM(amount) as total FROM payments WHERE buyer_code = ?',
          [fetchedCode],
        );

        double totalPayments = 0.0;
        if (paymentResults.isNotEmpty &&
            paymentResults.first['total'] != null) {
          totalPayments = (paymentResults.first['total'] as num).toDouble();
        }

        setState(() {
          buyerCode = fetchedCode;
          buyerName = name;
          openingBalance = balance;
          remainingBalance = balance - totalPayments;
          errorMessage = null;
        });
      } else {
        setState(() {
          buyerCode = '';
          buyerName = '';
          openingBalance = 0.0;
          remainingBalance = 0.0;
          errorMessage = 'खरीददार नहीं मिला';
        });
      }
    } catch (e) {
      print('❌ Error fetching buyer: $e');
      setState(() {
        errorMessage = 'त्रुटी: $e';
      });
    }
  }

  /// Calculate remaining balance in real-time
  void _calculateRemainingBalance() {
    if (amountCtrl.text.isEmpty) {
      setState(() {
        remainingBalance = openingBalance;
      });
      return;
    }

    try {
      final amount = double.parse(amountCtrl.text);
      setState(() {
        remainingBalance = openingBalance - amount;
        // Ensure remaining balance never goes negative
        if (remainingBalance < 0) {
          remainingBalance = 0.0;
        }
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'अवैध रक्कम';
      });
    }
  }

  /// Save payment to database and update buyer balance
  Future<void> _savePayment() async {
    if (buyerCodeCtrl.text.isEmpty) {
      _showSnackBar('कृपया खरीददार कोड दर्ज करें');
      return;
    }

    if (amountCtrl.text.isEmpty) {
      _showSnackBar('कृपया जमा रक्कम दर्ज करें');
      return;
    }

    if (buyerName.isEmpty) {
      _showSnackBar('खरीददार नहीं मिला');
      return;
    }

    setState(() => isLoading = true);

    try {
      final amount = double.parse(amountCtrl.text);

      if (amount <= 0) {
        throw Exception('रक्कम 0 से अधिक होनी चाहिए');
      }

      final now = DateTime.now().toIso8601String();

      // Step 1: Insert payment record
      final paymentData = {
        'buyer_code': buyerCode,
        'buyer_name': buyerName,
        'amount': amount,
        'payment_mode': selectedPaymentMode,
        'notes': '',
        'created_at': now,
        'updated_at': now,
      };

      await insertRecord('payments', paymentData);

      // Step 2: Update buyer's opening_balance using SQL query
      final newBalance = openingBalance - amount;
      await powerSyncDB.execute(
        'UPDATE buyers SET opening_balance = ?, updated_at = ? WHERE code = ?',
        [newBalance, now, buyerCode],
      );

      if (mounted) {
        _showSnackBar(
          '✅ जमा सफलतापूर्वक दर्ज किया गया: ₹${amount.toStringAsFixed(2)}',
          isSuccess: true,
        );

        // Clear form for next entry
        buyerCodeCtrl.clear();
        amountCtrl.clear();
        setState(() {
          selectedPaymentMode = 'cash';
          buyerName = '';
          buyerCode = '';
          openingBalance = 0.0;
          remainingBalance = 0.0;
          currentPayment = null;
          currentPaymentIndex = -1;
        });

        // Reload payments for navigation
        _loadAllPayments();

        // Focus back to buyer code field for next entry
        buyerCodeFocus.requestFocus();
      }
    } catch (e) {
      print('❌ Error saving payment: $e');
      if (mounted) {
        _showSnackBar('त्रुटी: $e', isSuccess: false);
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('जमा एन्ट्री'),
        elevation: 0,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Buyer Code Input
              TextFormField(
                controller: buyerCodeCtrl,
                focusNode: buyerCodeFocus,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'खरीददार कोड',
                  hintText: 'उदा: B001',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorText: errorMessage,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'खरीददार कोड आवश्यक है';
                  }
                  return null;
                },
                onFieldSubmitted: (_) {
                  // Move to amount field on Enter
                  FocusScope.of(context).requestFocus(amountFocus);
                },
              ),
              const SizedBox(height: 16),

              // Buyer Details Card
              if (buyerName.isNotEmpty)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'खरीददार: $buyerName',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'उधारी: ₹${openingBalance.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Payment Amount Input
              TextFormField(
                controller: amountCtrl,
                focusNode: amountFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'जमा रक्कम',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'जमा रक्कम आवश्यक है';
                  }
                  if (double.tryParse(value) == null) {
                    return 'वैध रक्कम दर्ज करें';
                  }
                  return null;
                },
                onFieldSubmitted: (_) {
                  // On Enter, submit the form
                  if (_formKey.currentState!.validate()) {
                    _savePayment();
                  }
                },
              ),
              const SizedBox(height: 16),

              // Remaining Balance (Read-only)
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'बाकी',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                controller: TextEditingController(
                  text: remainingBalance.toStringAsFixed(2),
                ),
              ),
              const SizedBox(height: 16),

              // Payment Mode Toggle
              Text(
                'भुगतान विधि',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: paymentModes.map((mode) {
                  final labels = {
                    'cash': 'नकद',
                    'bank': 'बैंक',
                    'upi': 'UPI',
                    'cheque': 'चेक',
                  };
                  return ChoiceChip(
                    label: Text(labels[mode] ?? mode),
                    selected: selectedPaymentMode == mode,
                    onSelected: (selected) {
                      setState(() {
                        selectedPaymentMode = mode;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Navigation Buttons (Previous/Next)
              if (allPayments.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed:
                          currentPaymentIndex > 0 ? _previousPayment : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('← मागिल'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (currentPayment != null)
                      Text(
                        '${currentPaymentIndex + 1}/${allPayments.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ElevatedButton.icon(
                      onPressed: currentPaymentIndex < allPayments.length - 1
                          ? _nextPayment
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('पुढील →'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _savePayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('जमा करा'),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons (Edit/Share/Delete) - Only show if payment is loaded
              if (currentPayment != null)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _editPayment,
                        icon: const Icon(Icons.edit),
                        label: const Text('संपादित करा'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showSnackBar('PDF तैयार किया जा रहा है...');
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('शेयर करा'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              if (currentPayment != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _deletePayment,
                    icon: const Icon(Icons.delete),
                    label: const Text('हटवा'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Info Text
              Center(
                child: Text(
                  'Enter दबाकर अगले field मध्ये जा\nAmount नंतर Enter ने Save होईल',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
