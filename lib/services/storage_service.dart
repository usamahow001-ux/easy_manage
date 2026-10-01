import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/party.dart';
import '../models/transaction.dart';
import '../models/cash_entry.dart';
import '../models/business_profile.dart';
import '../models/deleted_item.dart';

class StorageService {
  static const String _kParties = 'easymanage_parties_v1';
  static const String _kTransactions = 'easymanage_transactions_v1';
  static const String _kCashEntries = 'easymanage_cashentries_v1';
  static const String _kBusinessProfile = 'easymanage_business_v1';
  static const String _kLanguage = 'easymanage_language_v1';
  static const String _kLanguageSelected = 'easymanage_language_selected_v1';
  static const String _kDarkMode = 'easymanage_darkmode_v1';
  static const String _kFirstRun = 'easymanage_first_run_v1';
  static const String _kDeletedItems = 'easymanage_deleted_items_v1';
  static const String _kCalculatorHistory = 'easymanage_calculator_history_v1';

  // Auth & Security & Cloud Keys
  static const String _kAuthLoggedIn = 'easymanage_auth_logged_in_v1';
  static const String _kAuthIdentifier = 'easymanage_auth_identifier_v1';
  static const String _kLastSyncTime = 'easymanage_last_sync_time_v1';
  static const String _kAppLockEnabled = 'easymanage_app_lock_enabled_v1';
  static const String _kAppLockPin = 'easymanage_app_lock_pin_v1';
  static const String _kAppLockBiometric = 'easymanage_app_lock_biometric_v1';
  static const String _kCloudVaultPrefix = 'easymanage_cloud_vault_';

  final SharedPreferences prefs;

  StorageService(this.prefs);

  static Future<StorageService> init() async {
    final sp = await SharedPreferences.getInstance();
    final service = StorageService(sp);
    
    // Purge any legacy dummy/demo records if present
    await service._cleanupDemoDataIfPresent();

    if (!sp.containsKey(_kFirstRun)) {
      await sp.setBool(_kFirstRun, false);
    }
    return service;
  }

  Future<void> _cleanupDemoDataIfPresent() async {
    // Check if parties in storage are the dummy/demo ones
    final rawParties = prefs.getString(_kParties);
    if (rawParties != null && rawParties.isNotEmpty) {
      try {
        final list = jsonDecode(rawParties) as List;
        final isAllDemo = list.isNotEmpty && list.every((item) {
          final id = item['id'] as String? ?? '';
          final name = item['name'] as String? ?? '';
          return id == 'p_1' || id == 'p_2' || id == 'p_3' || id == 'p_4' ||
              name == 'Ahmed Super Store' || name == 'Tariq Electronics' ||
              name == 'National Wholesale Mills' || name == 'Bilal Traders & Distributors';
        });

        if (isAllDemo) {
          await prefs.remove(_kParties);
          await prefs.remove(_kTransactions);
          await prefs.remove(_kCashEntries);
        }
      } catch (_) {}
    }

    // Check if business profile is the dummy profile
    final rawBiz = prefs.getString(_kBusinessProfile);
    if (rawBiz != null && rawBiz.isNotEmpty) {
      try {
        final biz = jsonDecode(rawBiz) as Map<String, dynamic>;
        if (biz['businessName'] == 'Al-Madina Traders' || biz['ownerName'] == 'Muhammad Usama') {
          await prefs.remove(_kBusinessProfile);
        }
      } catch (_) {}
    }

    // Clean dummy phone if present
    final authId = prefs.getString(_kAuthIdentifier);
    if (authId == '0300 1234567' || authId == '03001234567') {
      await prefs.setString(_kAuthIdentifier, '');
    }
  }

  // Parties
  List<Party> loadParties() {
    final raw = prefs.getString(_kParties);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Party.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveParties(List<Party> parties) async {
    final raw = jsonEncode(parties.map((p) => p.toJson()).toList());
    await prefs.setString(_kParties, raw);
  }

  // Transactions
  List<KhataTransaction> loadTransactions() {
    final raw = prefs.getString(_kTransactions);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => KhataTransaction.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTransactions(List<KhataTransaction> txs) async {
    final raw = jsonEncode(txs.map((t) => t.toJson()).toList());
    await prefs.setString(_kTransactions, raw);
  }

  // Cash Entries
  List<CashEntry> loadCashEntries() {
    final raw = prefs.getString(_kCashEntries);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => CashEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCashEntries(List<CashEntry> entries) async {
    final raw = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_kCashEntries, raw);
  }

  // Business Profile
  BusinessProfile loadBusinessProfile() {
    final raw = prefs.getString(_kBusinessProfile);
    if (raw == null || raw.isEmpty) return BusinessProfile();
    try {
      return BusinessProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return BusinessProfile();
    }
  }

  Future<void> saveBusinessProfile(BusinessProfile profile) async {
    await prefs.setString(_kBusinessProfile, jsonEncode(profile.toJson()));
  }

  // Deleted Items / 30-day Recycle Bin
  List<DeletedItem> loadDeletedItems() {
    final raw = prefs.getString(_kDeletedItems);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      final items = list.map((e) => DeletedItem.fromJson(e as Map<String, dynamic>)).toList();
      final validItems = items.where((item) => !item.isExpired).toList();
      if (validItems.length != items.length) {
        saveDeletedItems(validItems);
      }
      return validItems;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDeletedItems(List<DeletedItem> items) async {
    final validItems = items.where((item) => !item.isExpired).toList();
    final raw = jsonEncode(validItems.map((e) => e.toJson()).toList());
    await prefs.setString(_kDeletedItems, raw);
  }

  // Auth & Cloud Sync State
  bool loadAuthLoggedIn() => prefs.getBool(_kAuthLoggedIn) ?? true;
  String loadAuthIdentifier() => prefs.getString(_kAuthIdentifier) ?? '';
  String loadLastSyncTime() => prefs.getString(_kLastSyncTime) ?? DateTime.now().toIso8601String();

  Future<void> setAuthStatus({required bool isLoggedIn, required String identifier}) async {
    await prefs.setBool(_kAuthLoggedIn, isLoggedIn);
    await prefs.setString(_kAuthIdentifier, identifier);
    await prefs.setString(_kLastSyncTime, DateTime.now().toIso8601String());
  }

  Future<void> updateLastSyncTime() async {
    await prefs.setString(_kLastSyncTime, DateTime.now().toIso8601String());
  }

  // Cloud Vault: saves / retrieves complete data payload keyed by phone/email
  Future<void> saveCloudVault(String identifier, Map<String, dynamic> data) async {
    final cleanId = identifier.replaceAll(' ', '').toLowerCase();
    await prefs.setString('$_kCloudVaultPrefix$cleanId', jsonEncode(data));
  }

  Map<String, dynamic>? getCloudVault(String identifier) {
    final cleanId = identifier.replaceAll(' ', '').toLowerCase();
    final raw = prefs.getString('$_kCloudVaultPrefix$cleanId');
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteCloudVault(String identifier) async {
    final cleanId = identifier.replaceAll(' ', '').toLowerCase();
    await prefs.remove('$_kCloudVaultPrefix$cleanId');
  }

  // App Lock Security
  bool loadAppLockEnabled() => prefs.getBool(_kAppLockEnabled) ?? false;
  Future<void> saveAppLockEnabled(bool enabled) => prefs.setBool(_kAppLockEnabled, enabled);

  String loadAppLockPin() => prefs.getString(_kAppLockPin) ?? '';
  Future<void> saveAppLockPin(String pin) => prefs.setString(_kAppLockPin, pin);

  bool loadAppLockBiometric() => prefs.getBool(_kAppLockBiometric) ?? true;
  Future<void> saveAppLockBiometric(bool biometric) => prefs.setBool(_kAppLockBiometric, biometric);

  // Language Selection
  bool hasSelectedLanguage() => prefs.getBool(_kLanguageSelected) ?? false;
  Future<void> setLanguageSelected(bool selected) => prefs.setBool(_kLanguageSelected, selected);

  String loadLanguage() => prefs.getString(_kLanguage) ?? 'en';
  Future<void> saveLanguage(String lang) => prefs.setString(_kLanguage, lang);

  bool loadDarkMode() => prefs.getBool(_kDarkMode) ?? false;
  Future<void> saveDarkMode(bool dark) => prefs.setBool(_kDarkMode, dark);

  // Calculator History Local Phone Storage
  List<Map<String, dynamic>> loadCalculatorHistory() {
    final raw = prefs.getString(_kCalculatorHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCalculatorHistory(List<Map<String, dynamic>> history) async {
    final raw = jsonEncode(history);
    await prefs.setString(_kCalculatorHistory, raw);
  }

  Future<void> clearCalculatorHistory() async {
    await prefs.remove(_kCalculatorHistory);
  }

  // Complete Export
  String exportAllDataJson() {
    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'account': loadAuthIdentifier(),
      'business': loadBusinessProfile().toJson(),
      'parties': loadParties().map((p) => p.toJson()).toList(),
      'transactions': loadTransactions().map((t) => t.toJson()).toList(),
      'cashEntries': loadCashEntries().map((c) => c.toJson()).toList(),
      'deletedItems': loadDeletedItems().map((d) => d.toJson()).toList(),
      'calculatorHistory': loadCalculatorHistory(),
    };
    return jsonEncode(data);
  }

  // Wipe All Account Data (Delete Account)
  Future<void> wipeAllAccountData() async {
    final id = loadAuthIdentifier();
    if (id.isNotEmpty) {
      await deleteCloudVault(id);
    }
    await prefs.remove(_kParties);
    await prefs.remove(_kTransactions);
    await prefs.remove(_kCashEntries);
    await prefs.remove(_kDeletedItems);
    await prefs.remove(_kBusinessProfile);
    await prefs.remove(_kAppLockEnabled);
    await prefs.remove(_kAppLockPin);
    await prefs.remove(_kLanguageSelected);
    await prefs.remove(_kCalculatorHistory);
    await setAuthStatus(isLoggedIn: false, identifier: '');
  }
}
