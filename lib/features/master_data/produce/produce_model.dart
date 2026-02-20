class Produce {
  final int? id;
  final String name;
  final String code;
  final String? category;
  final String? unit;
  final bool active;
  final String createdAt;

  // ✅ NEW: Commission fields
  final String commissionType; // 'DEFAULT' or 'PER_PRODUCE'
  final int? commissionId; // Expense Type ID (if per_produce)
  final String? commissionApplyOn; // 'farmer' or 'buyer' (if per_produce)

  Produce({
    this.id,
    required this.name,
    required this.code,
    this.category,
    this.unit,
    this.active = true,
    required this.createdAt,
    this.commissionType = 'DEFAULT',
    this.commissionId,
    this.commissionApplyOn,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'category': category,
      'unit': unit,
      'active': active ? 1 : 0,
      'created_at': createdAt,
      // ✅ NEW: Commission fields
      'commission_type': commissionType,
      'commission_id': commissionId,
      'commission_apply_on': commissionApplyOn,
    };
  }

  factory Produce.fromMap(Map<String, dynamic> map) {
    return Produce(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      category: map['category'],
      unit: map['unit'],
      active: map['active'] == 1,
      createdAt: map['created_at'],
      // ✅ NEW: Commission fields
      commissionType: map['commission_type'] ?? 'DEFAULT',
      commissionId: map['commission_id'],
      commissionApplyOn: map['commission_apply_on'],
    );
  }
}
