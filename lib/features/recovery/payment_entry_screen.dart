import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/powersync_service.dart';
import 'payment_model.dart';

class PaymentEntryScreen extends StatefulWidget {
  const PaymentEntryScreen({super.key});

  @override
  State<PaymentEntryScreen> createState() => _PaymentEntryScreenState();
}

class _PaymentEntryScreenState extends State<PaymentEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final buyerCodeCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  // Focus nodes for proper Enter flow
  late FocusNode buyerCodeFocus;
  late FocusNode amountFocus;
  late FocusNode notesFocus;

  String selectedPaymentMode = 'cash';
  String buyerName = '';
  String buyerCode = '';
  double openingBalance = 0.0;
  double remainingBalance = 0.0;
  bool isLoading = false;
  String? errorMessage;

  final List<String> paymentModes = ['cash', 'bank', 'upi', 'cheque'];

  @override
  void initState() {
    super.initState();
    // Initialize focus nodes
    buyerCodeFocus = FocusNode();
    amountFocus = FocusNode();
    notesFocus = FocusNode();

    buyerCodeCtrl.addListener(_onBuyerCodeChanged);
    amountCtrl.addListener(_calculateRemainingBalance);
  }

  @override
  void dispose() {
    buyerCodeCtrl.dispose();
    amountCtrl.dispose();
    notesCtrl.dispose();
    buyerCodeFocus.dispose();
    amountFocus.dispose();
    notesFocus.dispose();
    super.dispose();
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
        errorMessage = 'Invalid amount';
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
      _showSnackBar('कृपया जमा राशि दर्ज करें');
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
        throw Exception('Amount must be greater than 0');
      }

      final now = DateTime.now().toIso8601String();

      // Step 1: Insert payment record
      final paymentData = {
        'buyer_code': buyerCode,
        'buyer_name': buyerName,
        'amount': amount,
        'payment_mode': selectedPaymentMode,
        'notes': notesCtrl.text.trim(),
        'created_at': now,
        'updated_at': now,
      };

      await insertRecord('payments', paymentData);

      // Step 2: Update buyer's opening_balance (reduce by payment amount)
      final newBalance = openingBalance - amount;
      await updateRecord('buyers', buyerCode, {
        'opening_balance': newBalance,
        'updated_at': now,
      });

      if (mounted) {
        _showSnackBar(
          '✅ जमा सफलतापूर्वक दर्ज किया गया: ₹${amount.toStringAsFixed(2)}',
          isSuccess: true,
        );

        // Clear form for next entry
        buyerCodeCtrl.clear();
        amountCtrl.clear();
        notesCtrl.clear();
        setState(() {
          selectedPaymentMode = 'cash';
          buyerName = '';
          buyerCode = '';
          openingBalance = 0.0;
          remainingBalance = 0.0;
        });

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
                  labelText: 'जमा राशि',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'जमा राशि आवश्यक है';
                  }
                  if (double.tryParse(value) == null) {
                    return 'वैध राशि दर्ज करें';
                  }
                  return null;
                },
                onFieldSubmitted: (_) {
                  // Move to notes field on Enter
                  FocusScope.of(context).requestFocus(notesFocus);
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
              const SizedBox(height: 16),

              // Notes Field
              TextFormField(
                controller: notesCtrl,
                focusNode: notesFocus,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'टिप्पणी',
                  hintText: 'कोई अतिरिक्त जानकारी...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _savePayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('जमा करें'),
                ),
              ),
              const SizedBox(height: 16),

              // Info Text
              Center(
                child: Text(
                  'Enter दबाकर अगले field में जाएं\nSave के बाद नया entry के लिए ready होगा',
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
