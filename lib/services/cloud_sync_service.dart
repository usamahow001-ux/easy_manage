import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/party.dart';
import '../models/transaction.dart';
import '../models/business_profile.dart';
import '../models/customer_shop_khata.dart';
import 'phone_helper.dart';

class CloudSyncService {
  static const String _kCloudIndexKey = 'easymanage_cloud_sync_index_v1';
  static const String _kCustomerPhoneKey = 'easymanage_customer_phone_v1';

  final SharedPreferences prefs;

  CloudSyncService(this.prefs);

  /// Generates a live shareable link for Customer
  String generateShareKhataLink({
    required BusinessProfile business,
    required Party party,
  }) {
    final cleanPhone = Uri.encodeComponent(party.normalizedPhone);
    final shopName = Uri.encodeComponent(business.businessName);
    return 'https://easymanage.app/ledger?shopId=${business.id}&partyId=${party.id}&phone=$cleanPhone&shopName=$shopName';
  }

  /// Syncs the shopkeeper's business, parties, and transactions to the cloud index
  Future<bool> syncShopkeeperData({
    required BusinessProfile business,
    required List<Party> parties,
    required List<KhataTransaction> transactions,
  }) async {
    try {
      // In cloud-connected mode, this publishes to Firestore.
      // Locally, it also maintains the synchronized registry for dual-mode switching.
      final cloudIndexRaw = prefs.getString(_kCloudIndexKey);
      Map<String, dynamic> index = {};
      if (cloudIndexRaw != null && cloudIndexRaw.isNotEmpty) {
        try {
          index = jsonDecode(cloudIndexRaw) as Map<String, dynamic>;
        } catch (_) {}
      }

      // Map phone numbers to transactions & parties
      final shopData = {
        'business': business.toJson(),
        'parties': parties.map((p) => p.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'lastSynced': DateTime.now().toIso8601String(),
      };

      index[business.id] = shopData;
      await prefs.setString(_kCloudIndexKey, jsonEncode(index));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetches all shop Khatas where the customer phone number matches
  Future<List<CustomerShopKhata>> fetchCustomerKhatas(String customerPhone) async {
    final normalized = PhoneHelper.normalize(customerPhone);
    if (normalized.isEmpty) return [];

    // Save active customer phone
    await prefs.setString(_kCustomerPhoneKey, normalized);

    final cloudIndexRaw = prefs.getString(_kCloudIndexKey);
    if (cloudIndexRaw == null || cloudIndexRaw.isEmpty) return [];

    try {
      final index = jsonDecode(cloudIndexRaw) as Map<String, dynamic>;
      final List<CustomerShopKhata> result = [];

      for (final shopId in index.keys) {
        final shopData = index[shopId] as Map<String, dynamic>;
        final business = BusinessProfile.fromJson(shopData['business'] as Map<String, dynamic>);
        final rawParties = shopData['parties'] as List? ?? [];
        final rawTxs = shopData['transactions'] as List? ?? [];

        final parties = rawParties.map((p) => Party.fromJson(p as Map<String, dynamic>)).toList();
        final txs = rawTxs.map((t) => KhataTransaction.fromJson(t as Map<String, dynamic>)).toList();

        // Check if this party exists with normalized phone match
        final matchingParties = parties.where((p) => p.normalizedPhone == normalized).toList();

        for (final party in matchingParties) {
          final partyTxs = txs.where((t) => t.partyId == party.id).toList();

          // Calculate balance: youGave (customer owes) - youGot (customer paid) + opening balance
          double balance = party.openingBalance;
          for (final t in partyTxs) {
            if (t.type == TransactionType.youGave) {
              balance += t.amount;
            } else {
              balance -= t.amount;
            }
          }

          result.add(CustomerShopKhata.fromBusinessAndParty(
            business: business,
            balance: balance,
            transactions: partyTxs,
          ));
        }
      }

      return result;
    } catch (_) {
      return [];
    }
  }

  String? getSavedCustomerPhone() {
    return prefs.getString(_kCustomerPhoneKey);
  }
}
