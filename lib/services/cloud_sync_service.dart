import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Syncs the shopkeeper's business, parties, and transactions to the cloud index and Firebase Firestore
  Future<bool> syncShopkeeperData({
    required BusinessProfile business,
    required List<Party> parties,
    required List<KhataTransaction> transactions,
  }) async {
    // 1. Always maintain local cache for instant offline responsiveness
    try {
      final cloudIndexRaw = prefs.getString(_kCloudIndexKey);
      Map<String, dynamic> index = {};
      if (cloudIndexRaw != null && cloudIndexRaw.isNotEmpty) {
        try {
          index = jsonDecode(cloudIndexRaw) as Map<String, dynamic>;
        } catch (_) {}
      }

      final shopData = {
        'business': business.toJson(),
        'parties': parties.map((p) => p.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'lastSynced': DateTime.now().toIso8601String(),
      };

      index[business.id] = shopData;
      await prefs.setString(_kCloudIndexKey, jsonEncode(index));
    } catch (_) {}

    // 2. Real-time Firebase Firestore Sync across the internet
    try {
      if (Firebase.apps.isNotEmpty) {
        final firestore = FirebaseFirestore.instance;
        final shopDoc = firestore.collection('businesses').doc(business.id);

        await shopDoc.set({
          'business': business.toJson(),
          'lastSynced': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final batch = firestore.batch();
        for (final p in parties) {
          final pDoc = shopDoc.collection('parties').doc(p.id);
          batch.set(pDoc, {
            ...p.toJson(),
            'normalizedPhone': p.normalizedPhone,
            'shopId': business.id,
          }, SetOptions(merge: true));

          // Also write direct customer lookup document for instant live access
          if (p.normalizedPhone.isNotEmpty) {
            final partyTxs = transactions.where((t) => t.partyId == p.id).toList();
            double pBalance = p.openingBalance;
            for (final t in partyTxs) {
              if (t.type == TransactionType.youGave) {
                pBalance += t.amount;
              } else {
                pBalance -= t.amount;
              }
            }
            final custShopDoc = firestore
                .collection('customers')
                .doc(p.normalizedPhone)
                .collection('shops')
                .doc(business.id);
            batch.set(custShopDoc, {
              'shopId': business.id,
              'business': business.toJson(),
              'party': p.toJson(),
              'transactions': partyTxs.map((t) => t.toJson()).toList(),
              'balance': pBalance,
              'lastUpdated': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }

        for (final t in transactions) {
          final matchingParty = parties.firstWhere(
            (p) => p.id == t.partyId,
            orElse: () => Party(
              id: '',
              name: '',
              phone: '',
              type: PartyType.customer,
              createdAt: DateTime.now(),
            ),
          );
          final tDoc = shopDoc.collection('transactions').doc(t.id);
          batch.set(tDoc, {
            ...t.toJson(),
            'shopId': business.id,
            'customerPhone': matchingParty.normalizedPhone,
          }, SetOptions(merge: true));
        }

        await batch.commit();
        return true;
      }
    } catch (e) {
      debugPrint('Cloud Firestore sync: $e');
    }

    return true;
  }

  /// Fetches all shop Khatas where the customer phone number matches
  Future<List<CustomerShopKhata>> fetchCustomerKhatas(String customerPhone) async {
    final normalized = PhoneHelper.normalize(customerPhone);
    if (normalized.isEmpty) return [];

    // Save active customer phone
    await prefs.setString(_kCustomerPhoneKey, normalized);

    // 1. Query Firebase Cloud Firestore directly for real-time live data
    try {
      if (Firebase.apps.isNotEmpty) {
        final firestore = FirebaseFirestore.instance;

        // A. Direct Fast Customer Lookup Collection
        final customerShopsSnap = await firestore
            .collection('customers')
            .doc(normalized)
            .collection('shops')
            .get();

        if (customerShopsSnap.docs.isNotEmpty) {
          final List<CustomerShopKhata> directResults = [];
          for (final doc in customerShopsSnap.docs) {
            final data = doc.data();
            final bizData = data['business'] as Map<String, dynamic>?;
            if (bizData == null) continue;

            final biz = BusinessProfile.fromJson(bizData);
            final rawTxs = data['transactions'] as List? ?? [];
            final txs = rawTxs.map((t) => KhataTransaction.fromJson(Map<String, dynamic>.from(t as Map))).toList();
            final balance = (data['balance'] as num?)?.toDouble() ?? 0.0;

            directResults.add(CustomerShopKhata(
              shopId: data['shopId'] as String? ?? biz.id,
              shopName: biz.businessName,
              ownerName: biz.ownerName,
              shopPhone: biz.phone,
              shopAddress: biz.address,
              netBalance: balance,
              transactions: txs,
              lastUpdated: DateTime.now(),
            ));
          }
          if (directResults.isNotEmpty) return directResults;
        }

        // B. Fallback: Query collectionGroup('parties')
        final matchingPartiesSnap = await firestore
            .collectionGroup('parties')
            .where('normalizedPhone', isEqualTo: normalized)
            .get();

        if (matchingPartiesSnap.docs.isNotEmpty) {
          final List<CustomerShopKhata> cloudResults = [];
          for (final doc in matchingPartiesSnap.docs) {
            final data = doc.data();
            final shopId = data['shopId'] as String? ?? '';
            if (shopId.isEmpty) continue;

            final shopSnap = await firestore.collection('businesses').doc(shopId).get();
            final bizData = shopSnap.data()?['business'] as Map<String, dynamic>?;
            if (bizData == null) continue;

            final biz = BusinessProfile.fromJson(bizData);
            final party = Party.fromJson(data);

            final txsSnap = await firestore
                .collection('businesses')
                .doc(shopId)
                .collection('transactions')
                .where('partyId', isEqualTo: party.id)
                .get();

            final txs = txsSnap.docs.map((d) => KhataTransaction.fromJson(d.data())).toList();

            double balance = party.openingBalance;
            for (final t in txs) {
              if (t.type == TransactionType.youGave) {
                balance += t.amount;
              } else {
                balance -= t.amount;
              }
            }

            cloudResults.add(CustomerShopKhata.fromBusinessAndParty(
              business: biz,
              balance: balance,
              transactions: txs,
            ));
          }
          if (cloudResults.isNotEmpty) return cloudResults;
        }
      }
    } catch (e) {
      debugPrint('Cloud Firestore fetch: $e');
    }

    // 2. Fallback to local cache
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

        final matchingParties = parties.where((p) => p.normalizedPhone == normalized).toList();

        for (final party in matchingParties) {
          final partyTxs = txs.where((t) => t.partyId == party.id).toList();

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
