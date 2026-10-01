class BusinessProfile {
  final String businessName;
  final String ownerName;
  final String phone;
  final String address;
  final String currencySymbol;
  final String currencyCode;

  BusinessProfile({
    this.businessName = 'My Business',
    this.ownerName = 'Owner',
    this.phone = '',
    this.address = '',
    this.currencySymbol = 'Rs.',
    this.currencyCode = 'PKR',
  });

  Map<String, dynamic> toJson() => {
        'businessName': businessName,
        'ownerName': ownerName,
        'phone': phone,
        'address': address,
        'currencySymbol': currencySymbol,
        'currencyCode': currencyCode,
      };

  factory BusinessProfile.fromJson(Map<String, dynamic> json) => BusinessProfile(
        businessName: json['businessName'] as String? ?? 'My Business',
        ownerName: json['ownerName'] as String? ?? 'Owner',
        phone: json['phone'] as String? ?? '',
        address: json['address'] as String? ?? '',
        currencySymbol: json['currencySymbol'] as String? ?? 'Rs.',
        currencyCode: json['currencyCode'] as String? ?? 'PKR',
      );

  BusinessProfile copyWith({
    String? businessName,
    String? ownerName,
    String? phone,
    String? address,
    String? currencySymbol,
    String? currencyCode,
  }) {
    return BusinessProfile(
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }
}
