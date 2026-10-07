import '../models/transaction.dart';
import '../models/business_profile.dart';

class CustomerShopKhata {
  final String shopId;
  final String shopName;
  final String ownerName;
  final String shopPhone;
  final String shopAddress;
  final String currencySymbol;
  final double netBalance; // positive = customer owes shop, negative = advance/shop owes customer
  final DateTime lastUpdated;
  final List<KhataTransaction> transactions;

  CustomerShopKhata({
    required this.shopId,
    required this.shopName,
    required this.ownerName,
    required this.shopPhone,
    this.shopAddress = '',
    this.currencySymbol = 'Rs.',
    required this.netBalance,
    required this.lastUpdated,
    this.transactions = const [],
  });

  Map<String, dynamic> toJson() => {
        'shopId': shopId,
        'shopName': shopName,
        'ownerName': ownerName,
        'shopPhone': shopPhone,
        'shopAddress': shopAddress,
        'currencySymbol': currencySymbol,
        'netBalance': netBalance,
        'lastUpdated': lastUpdated.toIso8601String(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };

  factory CustomerShopKhata.fromJson(Map<String, dynamic> json) {
    final rawList = json['transactions'] as List? ?? [];
    final txs = rawList.map((e) => KhataTransaction.fromJson(e as Map<String, dynamic>)).toList();

    return CustomerShopKhata(
      shopId: json['shopId'] as String? ?? '',
      shopName: json['shopName'] as String? ?? 'Shop',
      ownerName: json['ownerName'] as String? ?? '',
      shopPhone: json['shopPhone'] as String? ?? '',
      shopAddress: json['shopAddress'] as String? ?? '',
      currencySymbol: json['currencySymbol'] as String? ?? 'Rs.',
      netBalance: (json['netBalance'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
      transactions: txs,
    );
  }

  factory CustomerShopKhata.fromBusinessAndParty({
    required BusinessProfile business,
    required double balance,
    required List<KhataTransaction> transactions,
  }) {
    DateTime latest = DateTime.now();
    if (transactions.isNotEmpty) {
      final sorted = List<KhataTransaction>.from(transactions)..sort((a, b) => b.date.compareTo(a.date));
      latest = sorted.first.date;
    }

    return CustomerShopKhata(
      shopId: business.id,
      shopName: business.businessName,
      ownerName: business.ownerName,
      shopPhone: business.phone,
      shopAddress: business.address,
      currencySymbol: business.currencySymbol,
      netBalance: balance,
      lastUpdated: latest,
      transactions: transactions,
    );
  }
}
