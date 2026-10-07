import 'package:uuid/uuid.dart';
import '../services/phone_helper.dart';

class BusinessProfile {
  final String id;
  final String businessName;
  final String ownerName;
  final String phone;
  final String address;
  final String currencySymbol;
  final String currencyCode;

  BusinessProfile({
    String? id,
    this.businessName = 'My Business',
    this.ownerName = 'Owner',
    this.phone = '',
    this.address = '',
    this.currencySymbol = 'Rs.',
    this.currencyCode = 'PKR',
  }) : id = id ?? const Uuid().v4();

  String get normalizedPhone => PhoneHelper.normalize(phone);

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessName': businessName,
        'ownerName': ownerName,
        'phone': phone,
        'address': address,
        'currencySymbol': currencySymbol,
        'currencyCode': currencyCode,
      };

  factory BusinessProfile.fromJson(Map<String, dynamic> json) => BusinessProfile(
        id: json['id'] as String?,
        businessName: json['businessName'] as String? ?? 'My Business',
        ownerName: json['ownerName'] as String? ?? 'Owner',
        phone: json['phone'] as String? ?? '',
        address: json['address'] as String? ?? '',
        currencySymbol: json['currencySymbol'] as String? ?? 'Rs.',
        currencyCode: json['currencyCode'] as String? ?? 'PKR',
      );

  BusinessProfile copyWith({
    String? id,
    String? businessName,
    String? ownerName,
    String? phone,
    String? address,
    String? currencySymbol,
    String? currencyCode,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }
}
