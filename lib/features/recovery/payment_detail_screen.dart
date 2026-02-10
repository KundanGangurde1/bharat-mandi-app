import 'package:flutter/material.dart';
import '../../../core/services/powersync_service.dart';
import 'payment_model.dart';
import 'payment_pdf_generator.dart';

class PaymentDetailScreen extends StatefulWidget {
  final String paymentId;
  final String buyerCode;

  const PaymentDetailScreen({
    super.key,
    required this.paymentId,
    required this.buyerCode,
  });

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  Payment? _payment;
  bool _isLoading = true;
  int _currentIndex = 0;
  List<Payment> _allPayments = [];

  @override
  void initState() {
    super.initState();
    _loadPayment();
  }

  /// Load payment details
  Future<void> _loadPayment() async {
    try {
      setState(() => _isLoading = true);

      // ✅ Get payment by ID using correct method
      final result = await getRecordById('payments', widget.paymentId);

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ जमा नहीं मिला')),
        );
        Navigator.pop(context);
        return;
      }

      final payment = Payment.fromMap(result);

      // ✅ Get all payments for this buyer for navigation
      final results = await powerSyncDB.getAll(
        'SELECT * FROM payments WHERE buyer_code = ? ORDER BY created_at DESC',
        [widget.buyerCode],
      );

      final allPayments = results.map((r) => Payment.fromMap(r)).toList();
      final currentIndex =
          allPayments.indexWhere((p) => p.id == widget.paymentId);

      setState(() {
        _payment = payment;
        _allPayments = allPayments;
        _currentIndex = currentIndex >= 0 ? currentIndex : 0;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  /// Navigate to previous payment
  void _previousPayment() {
    if (_currentIndex > 0) {
      final previousPayment = _allPayments[_currentIndex - 1];
      setState(() {
        _payment = previousPayment;
        _currentIndex--;
      });
    }
  }

  /// Navigate to next payment
  void _nextPayment() {
    if (_currentIndex < _allPayments.length - 1) {
      final nextPayment = _allPayments[_currentIndex + 1];
      setState(() {
        _payment = nextPayment;
        _currentIndex++;
      });
    }
  }

  /// Delete payment
  Future<void> _deletePayment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('जमा हटाएँ?'),
        content: const Text('क्या आप यह जमा हटाना चाहते हैं?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('नहीं'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('हाँ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      // ✅ Delete payment using correct method
      await deleteRecord('payments', _payment!.id ?? '');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ जमा हटाया गया')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('❌ Error deleting payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  /// Share payment as PDF
  Future<void> _sharePayment() async {
    if (_payment == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📄 PDF तैयार किया जा रहा है...')),
      );

      final pdfFile = await PaymentPdfGenerator.generatePaymentPDF(_payment!);

      if (pdfFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ PDF तैयार: ${pdfFile.path}')),
        );
        // You can add share functionality here using share_plus package
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ PDF बनाने में त्रुटि')),
        );
      }
    } catch (e) {
      print('❌ Error sharing payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  /// Edit payment
  void _editPayment() {
    if (_payment == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentEditScreen(payment: _payment!),
      ),
    ).then((updated) {
      if (updated == true) {
        _loadPayment();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('जमा विवरण'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_payment == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('जमा विवरण'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('❌ जमा नहीं मिला'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('जमा विवरण'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Details Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'खरीददार:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(_payment!.buyer_name),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'कोड:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(_payment!.buyer_code),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'राशि:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _payment!.getFormattedAmount(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'भुगतान विधि:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(_payment!.getPaymentModeDisplay()),
                        ],
                      ),
                      if (_payment!.reference_no != null &&
                          _payment!.reference_no!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'संदर्भ:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(_payment!.reference_no!),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'तारीख:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(_payment!.getFormattedDate()),
                        ],
                      ),
                      if (_payment!.notes != null &&
                          _payment!.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'टिप्पणी:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(_payment!.notes!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _currentIndex > 0 ? _previousPayment : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('मागिल'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  Text(
                    '${_currentIndex + 1}/${_allPayments.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _currentIndex < _allPayments.length - 1
                        ? _nextPayment
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('पुढील'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons
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
                      onPressed: _sharePayment,
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
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _deletePayment,
                  icon: const Icon(Icons.delete),
                  label: const Text('हटाएँ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Payment Edit Screen
class PaymentEditScreen extends StatefulWidget {
  final Payment payment;

  const PaymentEditScreen({super.key, required this.payment});

  @override
  State<PaymentEditScreen> createState() => _PaymentEditScreenState();
}

class _PaymentEditScreenState extends State<PaymentEditScreen> {
  late TextEditingController _amountController;
  late TextEditingController _referenceController;
  late TextEditingController _notesController;
  late String _selectedPaymentMode;
  bool _isLoading = false;

  final List<String> _paymentModes = ['cash', 'bank', 'upi', 'cheque'];

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.payment.amount.toString());
    _referenceController =
        TextEditingController(text: widget.payment.reference_no ?? '');
    _notesController = TextEditingController(text: widget.payment.notes ?? '');
    _selectedPaymentMode = widget.payment.payment_mode;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Save changes
  Future<void> _saveChanges() async {
    final amountText = _amountController.text.trim();

    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ राशि भरी नहीं')),
      );
      return;
    }

    try {
      final amount = double.parse(amountText);

      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ राशि 0 से बड़ी होनी चाहिए')),
        );
        return;
      }

      setState(() => _isLoading = true);

      final updatedPayment = widget.payment.copyWith(
        amount: amount,
        payment_mode: _selectedPaymentMode,
        reference_no: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        updated_at: DateTime.now().toIso8601String(),
      );

      // ✅ Update payment using correct method
      await updateRecord(
          'payments', widget.payment.id ?? '', updatedPayment.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ जमा अपडेट किया गया')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      print('❌ Error updating payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('जमा संपादित करा'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount
              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'राशि',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // Payment Mode
              const Text(
                'भुगतान विधि:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _paymentModes.map((mode) {
                  return ChoiceChip(
                    label: Text(mode == 'cash'
                        ? 'नकद'
                        : mode == 'bank'
                            ? 'बैंक'
                            : mode == 'upi'
                                ? 'UPI'
                                : 'चेक'),
                    selected: _selectedPaymentMode == mode,
                    onSelected: (selected) {
                      setState(() {
                        _selectedPaymentMode = mode;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Reference Number
              if (_selectedPaymentMode != 'cash')
                TextField(
                  controller: _referenceController,
                  decoration: InputDecoration(
                    labelText: 'संदर्भ संख्या',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.receipt),
                  ),
                ),
              if (_selectedPaymentMode != 'cash') const SizedBox(height: 16),

              // Notes
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'टिप्पणी',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('अपडेट करा'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
