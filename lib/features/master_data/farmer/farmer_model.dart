class Farmer {
  final int? id;
  final String name;
  final String? code;
  final bool active;
  final String createdAt;

  Farmer({
    this.id,
    required this.name,
    this.code,
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

  factory Farmer.fromMap(Map<String, dynamic> map) {
    return Farmer(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      active: map['active'] == 1,
      createdAt: map['created_at'],
    );
  }
}
