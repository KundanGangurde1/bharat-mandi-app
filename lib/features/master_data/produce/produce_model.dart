class Produce {
  final int? id;
  final String name;
  final String code;
  final String? category;
  final String? unit;
  final bool active;
  final String createdAt;

  Produce({
    this.id,
    required this.name,
    required this.code,
    this.category,
    this.unit,
    this.active = true,
    required this.createdAt,
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
    );
  }
}
