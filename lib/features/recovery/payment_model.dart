// Payment Model - Represents a payment record in the system
class Payment {
  final String? id; // PowerSync auto-generated ID
  final String buyer_code;
  final String buyer_name;
  final double amount;
  final String payment_mode; // cash, bank, upi, cheque
  final String? reference_no; // For bank/cheque/upi references
  final String? notes;
  final String created_at;
  final String updated_at;

  // Optional fields for display (not stored in DB)
  final double? opening_balance; // For display in entry screen
  final double? remaining_balance; // For display in entry screen

  Payment({
    this.id,
    required this.buyer_code,
    required this.buyer_name,
    required this.amount,
    required this.payment_mode,
    this.reference_no,
    this.notes,
    required this.created_at,
    required this.updated_at,
    this.opening_balance,
    this.remaining_balance,
  });

  /// Convert Payment object to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'buyer_code': buyer_code,
      'buyer_name': buyer_name,
      'amount': amount,
      'payment_mode': payment_mode,
      'reference_no': reference_no,
      'notes': notes,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }

  /// Create Payment object from database Map
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      buyer_code: map['buyer_code'] ?? '',
      buyer_name: map['buyer_name'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      payment_mode: map['payment_mode'] ?? 'cash',
      reference_no: map['reference_no'],
      notes: map['notes'],
      created_at: map['created_at'] ?? '',
      updated_at: map['updated_at'] ?? '',
    );
  }

  /// Create a copy of Payment with some fields replaced
  Payment copyWith({
    String? id,
    String? buyer_code,
    String? buyer_name,
    double? amount,
    String? payment_mode,
    String? reference_no,
    String? notes,
    String? created_at,
    String? updated_at,
    double? opening_balance,
    double? remaining_balance,
  }) {
    return Payment(
      id: id ?? this.id,
      buyer_code: buyer_code ?? this.buyer_code,
      buyer_name: buyer_name ?? this.buyer_name,
      amount: amount ?? this.amount,
      payment_mode: payment_mode ?? this.payment_mode,
      reference_no: reference_no ?? this.reference_no,
      notes: notes ?? this.notes,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
      opening_balance: opening_balance ?? this.opening_balance,
      remaining_balance: remaining_balance ?? this.remaining_balance,
    );
  }

  /// Validate payment data
  bool isValid() {
    if (buyer_code.isEmpty) return false;
    if (buyer_name.isEmpty) return false;
    if (amount <= 0) return false;
    if (payment_mode.isEmpty) return false;
    return true;
  }

  /// Get formatted amount for display
  String getFormattedAmount() {
    return '₹${amount.toStringAsFixed(2)}';
  }

  /// Get formatted opening balance for display
  String getFormattedOpeningBalance() {
    if (opening_balance == null) return '₹0.00';
    return '₹${opening_balance!.toStringAsFixed(2)}';
  }

  /// Get formatted remaining balance for display
  String getFormattedRemainingBalance() {
    if (remaining_balance == null) return '₹0.00';
    return '₹${remaining_balance!.toStringAsFixed(2)}';
  }

  /// Get payment mode display name
  String getPaymentModeDisplay() {
    switch (payment_mode.toLowerCase()) {
      case 'cash':
        return 'नकद';
      case 'bank':
        return 'बैंक';
      case 'upi':
        return 'UPI';
      case 'cheque':
        return 'चेक';
      default:
        return payment_mode;
    }
  }

  /// Get formatted date for display
  String getFormattedDate() {
    try {
      final date = DateTime.parse(created_at);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return created_at;
    }
  }

  /// Get formatted datetime for display
  String getFormattedDateTime() {
    try {
      final date = DateTime.parse(created_at);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return created_at;
    }
  }

  @override
  String toString() {
    return 'Payment(id: $id, buyer_code: $buyer_code, buyer_name: $buyer_name, amount: $amount, payment_mode: $payment_mode, created_at: $created_at)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          buyer_code == other.buyer_code &&
          amount == other.amount;

  @override
  int get hashCode => id.hashCode ^ buyer_code.hashCode ^ amount.hashCode;
}
