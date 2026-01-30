class Firm {
  final int? id;
  final String name;
  final String? code;
  final String owner_name;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String? gst_number;
  final String? pan_number;
  final bool active;
  final String created_at;
  final String? updated_at;

  Firm({
    this.id,
    required this.name,
    this.code,
    required this.owner_name,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.gst_number,
    this.pan_number,
    this.active = true,
    required this.created_at,
    this.updated_at,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'owner_name': owner_name,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'gst_number': gst_number,
      'pan_number': pan_number,
      'active': active ? 1 : 0,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }

  factory Firm.fromMap(Map<String, dynamic> map) {
    return Firm(
      id: map['id'],
      name: map['name'] ?? '',
      code: map['code'],
      owner_name: map['owner_name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
      gst_number: map['gst_number'],
      pan_number: map['pan_number'],
      active: (map['active'] ?? 1) == 1,
      created_at: map['created_at'] ?? DateTime.now().toIso8601String(),
      updated_at: map['updated_at'],
    );
  }

  Firm copyWith({
    int? id,
    String? name,
    String? code,
    String? owner_name,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? gst_number,
    String? pan_number,
    bool? active,
    String? created_at,
    String? updated_at,
  }) {
    return Firm(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      owner_name: owner_name ?? this.owner_name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      gst_number: gst_number ?? this.gst_number,
      pan_number: pan_number ?? this.pan_number,
      active: active ?? this.active,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }
}
