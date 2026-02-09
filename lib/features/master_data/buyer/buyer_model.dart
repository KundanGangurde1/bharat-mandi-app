class Buyer {
  final int? id;
  final String name;
  final String code;
  final bool active;
  final String createdAt;

  Buyer({
    this.id,
    required this.name,
    required this.code,
    this.active = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'active': active ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory Buyer.fromMap(Map<String, dynamic> map) {
    return Buyer(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      active: map['active'] == 1,
      createdAt: map['created_at'],
    );
  }
}
