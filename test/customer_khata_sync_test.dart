import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_manage/models/party.dart';
import 'package:easy_manage/models/transaction.dart';
import 'package:easy_manage/models/business_profile.dart';
import 'package:easy_manage/services/phone_helper.dart';
import 'package:easy_manage/services/cloud_sync_service.dart';

void main() {
  group('PhoneHelper Tests', () {
    test('normalizes standard 11 digit mobile number', () {
      expect(PhoneHelper.normalize('0300 1234567'), '+923001234567');
      expect(PhoneHelper.normalize('0300-1234567'), '+923001234567');
      expect(PhoneHelper.normalize('03001234567'), '+923001234567');
    });

    test('normalizes 10 digit number starting with 3', () {
      expect(PhoneHelper.normalize('3001234567'), '+923001234567');
    });

    test('preserves already normalized international number', () {
      expect(PhoneHelper.normalize('+923001234567'), '+923001234567');
      expect(PhoneHelper.normalize('+14155552671'), '+14155552671');
    });
  });

  group('CloudSyncService & Customer Lookup Tests', () {
    test('Shopkeeper data syncs and customer can query their khata by phone', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final syncService = CloudSyncService(prefs);

      final business = BusinessProfile(
        id: 'shop_001',
        businessName: 'Al-Madina General Store',
        ownerName: 'Muhammad Ali',
        phone: '0300 1112233',
        address: 'Main Bazaar, Lahore',
      );

      final customerA = Party(
        id: 'p_cust_a',
        name: 'Usama Tariq',
        phone: '0300 9876543',
        type: PartyType.customer,
        createdAt: DateTime.now(),
        openingBalance: 100.0,
      );

      final customerB = Party(
        id: 'p_cust_b',
        name: 'Ahmed Khan',
        phone: '0321 5554433',
        type: PartyType.customer,
        createdAt: DateTime.now(),
        openingBalance: 0.0,
      );

      final tx1 = KhataTransaction(
        id: 'tx_1',
        partyId: customerA.id,
        amount: 500.0,
        type: TransactionType.youGave, // Udhaar Diya (Customer owes +500)
        date: DateTime.now(),
        note: 'Cooking Oil & Rice',
      );

      final tx2 = KhataTransaction(
        id: 'tx_2',
        partyId: customerA.id,
        amount: 200.0,
        type: TransactionType.youGot, // Payment received (-200)
        date: DateTime.now(),
        note: 'Cash payment',
      );

      // 1. Shopkeeper syncs
      final syncResult = await syncService.syncShopkeeperData(
        business: business,
        parties: [customerA, customerB],
        transactions: [tx1, tx2],
      );
      expect(syncResult, isTrue);

      // 2. Customer A logs in with their phone number
      final customerKhatas = await syncService.fetchCustomerKhatas('0300 9876543');
      expect(customerKhatas.length, 1);

      final khata = customerKhatas.first;
      expect(khata.shopName, 'Al-Madina General Store');
      expect(khata.ownerName, 'Muhammad Ali');
      expect(khata.transactions.length, 2);
      // Net balance = 100 opening + 500 youGave - 200 youGot = 400
      expect(khata.netBalance, 400.0);

      // 3. Customer B logs in
      final customerBKhatas = await syncService.fetchCustomerKhatas('0321 5554433');
      expect(customerBKhatas.length, 1);
      expect(customerBKhatas.first.netBalance, 0.0);

      // 4. Non-existent customer returns empty list
      final unregistered = await syncService.fetchCustomerKhatas('0345 0000000');
      expect(unregistered.isEmpty, isTrue);
    });
  });
}
