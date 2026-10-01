enum PartyType { customer, supplier }

class Party {
  final String id;
  final String name;
  final String phone;
  final PartyType type;
  final String address;
  final DateTime createdAt;
  final double openingBalance; // positive means they owe us, negative means we owe them
  final int avatarColorIndex;
  final String notes;

  Party({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    this.address = '',
    required this.createdAt,
    this.openingBalance = 0.0,
    this.avatarColorIndex = 0,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'type': type.name,
        'address': address,
        'createdAt': createdAt.toIso8601String(),
        'openingBalance': openingBalance,
        'avatarColorIndex': avatarColorIndex,
        'notes': notes,
      };

  factory Party.fromJson(Map<String, dynamic> json) => Party(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String? ?? '',
        type: (json['type'] == 'supplier') ? PartyType.supplier : PartyType.customer,
        address: json['address'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0.0,
        avatarColorIndex: json['avatarColorIndex'] as int? ?? 0,
        notes: json['notes'] as String? ?? '',
      );

  Party copyWith({
    String? id,
    String? name,
    String? phone,
    PartyType? type,
    String? address,
    DateTime? createdAt,
    double? openingBalance,
    int? avatarColorIndex,
    String? notes,
  }) {
    return Party(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      openingBalance: openingBalance ?? this.openingBalance,
      avatarColorIndex: avatarColorIndex ?? this.avatarColorIndex,
      notes: notes ?? this.notes,
    );
  }
}
