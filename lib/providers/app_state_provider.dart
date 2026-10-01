import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/party.dart';
import '../models/transaction.dart';
import '../models/cash_entry.dart';
import '../models/business_profile.dart';
import '../models/deleted_item.dart';
import '../models/calculation_record.dart';
import '../services/storage_service.dart';
import '../services/google_drive_service.dart';
import '../l10n/app_localizations.dart';

enum PartyFilter { all, pendingOnly, clearedOnly }
enum PartySort { recent, name, balanceHigh }
enum TimePeriod { all, today, thisWeek, thisMonth }

class AppStateProvider extends ChangeNotifier {
  final StorageService storageService;
  late final GoogleDriveService googleDriveService;

  List<Party> _parties = [];
  List<KhataTransaction> _transactions = [];
  List<CashEntry> _cashEntries = [];
  List<DeletedItem> _deletedItems = [];
  List<CalculationRecord> _calculatorHistory = [];
  BusinessProfile _businessProfile = BusinessProfile();

  // Auth & Cloud state
  bool _isLoggedIn = true;
  String _userIdentifier = '';
  DateTime _lastSyncTime = DateTime.now();

  // App Lock state
  bool _isAppLockEnabled = false;
  String _appLockPin = '';
  bool _isBiometricEnabled = true;
  bool _isAppUnlocked = false;

  AppLanguage _language = AppLanguage.english;
  bool _isDarkMode = false;
  String _searchQuery = '';
  PartyFilter _partyFilter = PartyFilter.all;
  PartySort _partySort = PartySort.recent;
  TimePeriod _cashPeriod = TimePeriod.all;

  AppStateProvider(this.storageService) {
    googleDriveService = GoogleDriveService(storageService.prefs);
    _loadAllData();
  }

  // Getters
  List<Party> get parties => _parties;
  List<KhataTransaction> get transactions => _transactions;
  List<CashEntry> get cashEntries => _cashEntries;
  List<DeletedItem> get deletedItems => _deletedItems;
  List<CalculationRecord> get calculatorHistory => _calculatorHistory;
  BusinessProfile get businessProfile => _businessProfile;
  AppLanguage get language => _language;
  bool get isDarkMode => _isDarkMode;
  String get searchQuery => _searchQuery;
  PartyFilter get partyFilter => _partyFilter;
  PartySort get partySort => _partySort;
  TimePeriod get cashPeriod => _cashPeriod;

  bool get isLoggedIn => _isLoggedIn;
  String get userIdentifier => _userIdentifier;
  DateTime get lastSyncTime => _lastSyncTime;

  bool get isAppLockEnabled => _isAppLockEnabled;
  String get appLockPin => _appLockPin;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isAppUnlocked => _isAppUnlocked;

  AppLocalizations get loc => AppLocalizations(_language);

  // Language selection state
  bool get hasSelectedLanguage => storageService.hasSelectedLanguage();
  Future<void> setLanguageSelected(bool val) async {
    await storageService.setLanguageSelected(val);
    notifyListeners();
  }

  // Calculator History methods
  void addCalculationRecord(CalculationRecord record) {
    _calculatorHistory.insert(0, record);
    if (_calculatorHistory.length > 200) {
      _calculatorHistory = _calculatorHistory.sublist(0, 200);
    }
    storageService.saveCalculatorHistory(_calculatorHistory.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  void clearCalculatorHistory() {
    _calculatorHistory.clear();
    storageService.clearCalculatorHistory();
    notifyListeners();
  }

  void _loadAllData() {
    _parties = storageService.loadParties();
    _transactions = storageService.loadTransactions();
    _cashEntries = storageService.loadCashEntries();
    _deletedItems = storageService.loadDeletedItems();
    _businessProfile = storageService.loadBusinessProfile();

    final rawCalcHistory = storageService.loadCalculatorHistory();
    _calculatorHistory = rawCalcHistory.map((e) => CalculationRecord.fromJson(e)).toList();

    _isLoggedIn = storageService.loadAuthLoggedIn();
    _userIdentifier = storageService.loadAuthIdentifier();
    _lastSyncTime = DateTime.tryParse(storageService.loadLastSyncTime()) ?? DateTime.now();

    _isAppLockEnabled = storageService.loadAppLockEnabled();
    _appLockPin = storageService.loadAppLockPin();
    _isBiometricEnabled = storageService.loadAppLockBiometric();
    _isAppUnlocked = !_isAppLockEnabled;

    final savedLang = storageService.loadLanguage();
    if (savedLang == 'ur') {
      _language = AppLanguage.urdu;
    } else if (savedLang == 'ur_roman' || savedLang == 'hinglish') {
      _language = AppLanguage.romanUrdu;
    } else {
      _language = AppLanguage.english;
    }
    _isDarkMode = storageService.loadDarkMode();
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q.trim().toLowerCase();
    notifyListeners();
  }

  void setPartyFilter(PartyFilter filter) {
    _partyFilter = filter;
    notifyListeners();
  }

  void setPartySort(PartySort sort) {
    _partySort = sort;
    notifyListeners();
  }

  void setCashPeriod(TimePeriod period) {
    _cashPeriod = period;
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    if (_language == AppLanguage.english) {
      _language = AppLanguage.urdu;
    } else if (_language == AppLanguage.urdu) {
      _language = AppLanguage.romanUrdu;
    } else {
      _language = AppLanguage.english;
    }
    String code = 'en';
    if (_language == AppLanguage.urdu) code = 'ur';
    if (_language == AppLanguage.romanUrdu) code = 'ur_roman';
    await storageService.saveLanguage(code);
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage lang) async {
    _language = lang;
    String code = 'en';
    if (_language == AppLanguage.urdu) code = 'ur';
    if (_language == AppLanguage.romanUrdu) code = 'ur_roman';
    await storageService.saveLanguage(code);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await storageService.saveDarkMode(_isDarkMode);
    notifyListeners();
  }

  // App Lock Methods
  bool unlockWithPin(String enteredPin) {
    if (_appLockPin.isEmpty || enteredPin == _appLockPin) {
      _isAppUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void unlockWithBiometric() {
    _isAppUnlocked = true;
    notifyListeners();
  }

  void lockApp() {
    if (_isAppLockEnabled) {
      _isAppUnlocked = false;
      notifyListeners();
    }
  }

  Future<void> configureAppLock({
    required bool enabled,
    required String pin,
    bool biometric = true,
  }) async {
    _isAppLockEnabled = enabled;
    _appLockPin = pin;
    _isBiometricEnabled = biometric;
    _isAppUnlocked = true;

    await storageService.saveAppLockEnabled(enabled);
    await storageService.saveAppLockPin(pin);
    await storageService.saveAppLockBiometric(biometric);
    notifyListeners();
  }

  Future<void> setAppLock({required bool enabled, required String pin, bool biometric = true}) async {
    await configureAppLock(enabled: enabled, pin: pin, biometric: biometric);
  }

  Future<void> setBiometricEnabled(bool biometric) async {
    _isBiometricEnabled = biometric;
    await storageService.saveAppLockBiometric(biometric);
    notifyListeners();
  }

  // Google Drive Backup & Sync
  Future<GoogleDriveBackupInfo> backupToGoogleDrive([String? email]) async {
    final targetEmail = email ?? googleDriveService.connectedGoogleAccount;
    final info = await googleDriveService.backupToGoogleDrive(
      accountEmail: targetEmail,
      business: _businessProfile,
      parties: _parties,
      transactions: _transactions,
      cashEntries: _cashEntries,
      deletedItems: _deletedItems,
      calculatorHistory: _calculatorHistory.map((e) => e.toJson()).toList(),
      totalReceivable: totalReceivable,
      totalPayable: totalPayable,
    );
    _lastSyncTime = DateTime.now();
    await storageService.updateLastSyncTime();
    notifyListeners();
    return info;
  }

  Future<bool> restoreFromGoogleDrive([String? email]) async {
    final targetEmail = email ?? googleDriveService.connectedGoogleAccount;
    final payload = await googleDriveService.fetchDriveBackupPayload(targetEmail);
    if (payload == null) return false;

    try {
      if (payload['business'] != null) {
        _businessProfile = BusinessProfile.fromJson(payload['business'] as Map<String, dynamic>);
      }
      if (payload['parties'] != null) {
        final list = payload['parties'] as List;
        _parties = list.map((e) => Party.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (payload['transactions'] != null) {
        final list = payload['transactions'] as List;
        _transactions = list.map((e) => KhataTransaction.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (payload['cashEntries'] != null) {
        final list = payload['cashEntries'] as List;
        _cashEntries = list.map((e) => CashEntry.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (payload['deletedItems'] != null) {
        final list = payload['deletedItems'] as List;
        _deletedItems = list.map((e) => DeletedItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (payload['calculatorHistory'] != null) {
        final list = payload['calculatorHistory'] as List;
        _calculatorHistory = list.map((e) => CalculationRecord.fromJson(e as Map<String, dynamic>)).toList();
        await storageService.saveCalculatorHistory(list.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
      await storageService.saveParties(_parties);
      await storageService.saveTransactions(_transactions);
      await storageService.saveCashEntries(_cashEntries);
      await storageService.saveDeletedItems(_deletedItems);
      await storageService.saveBusinessProfile(_businessProfile);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Cloud Sync & Verification
  Future<void> syncToCloud() async {
    if (_userIdentifier.isEmpty) return;
    final payload = {
      'syncedAt': DateTime.now().toIso8601String(),
      'identifier': _userIdentifier,
      'business': _businessProfile.toJson(),
      'parties': _parties.map((p) => p.toJson()).toList(),
      'transactions': _transactions.map((t) => t.toJson()).toList(),
      'cashEntries': _cashEntries.map((c) => c.toJson()).toList(),
      'deletedItems': _deletedItems.map((d) => d.toJson()).toList(),
    };
    await storageService.saveCloudVault(_userIdentifier, payload);
    _lastSyncTime = DateTime.now();
    await storageService.updateLastSyncTime();

    if (googleDriveService.isAutoBackupEnabled) {
      await backupToGoogleDrive();
    }
    notifyListeners();
  }

  // Login & Restore Flow
  Future<bool> loginWithIdentifier(String identifier) async {
    final cleanId = identifier.trim();
    if (cleanId.isEmpty) return false;

    final vault = storageService.getCloudVault(cleanId);
    if (vault != null) {
      try {
        if (vault['business'] != null) {
          _businessProfile = BusinessProfile.fromJson(vault['business'] as Map<String, dynamic>);
        }
        if (vault['parties'] != null) {
          final list = vault['parties'] as List;
          _parties = list.map((e) => Party.fromJson(e as Map<String, dynamic>)).toList();
        }
        if (vault['transactions'] != null) {
          final list = vault['transactions'] as List;
          _transactions = list.map((e) => KhataTransaction.fromJson(e as Map<String, dynamic>)).toList();
        }
        if (vault['cashEntries'] != null) {
          final list = vault['cashEntries'] as List;
          _cashEntries = list.map((e) => CashEntry.fromJson(e as Map<String, dynamic>)).toList();
        }
        if (vault['deletedItems'] != null) {
          final list = vault['deletedItems'] as List;
          _deletedItems = list.map((e) => DeletedItem.fromJson(e as Map<String, dynamic>)).toList();
        }
        await storageService.saveParties(_parties);
        await storageService.saveTransactions(_transactions);
        await storageService.saveCashEntries(_cashEntries);
        await storageService.saveDeletedItems(_deletedItems);
        await storageService.saveBusinessProfile(_businessProfile);
      } catch (_) {}
    } else {
      await syncToCloud();
    }

    _userIdentifier = cleanId;
    _isLoggedIn = true;
    _isAppUnlocked = true;
    await storageService.setAuthStatus(isLoggedIn: true, identifier: cleanId);
    await syncToCloud();
    notifyListeners();
    return true;
  }

  // Google Login & Restore Flow
  Future<bool> loginWithGoogle(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return false;

    await googleDriveService.linkGoogleAccount(cleanEmail);

    // Check if Google Drive has backup payload
    final drivePayload = await googleDriveService.fetchDriveBackupPayload(cleanEmail);
    if (drivePayload != null) {
      await restoreFromGoogleDrive(cleanEmail);
    } else {
      // Check cloud vault
      final vault = storageService.getCloudVault(cleanEmail);
      if (vault != null) {
        await loginWithIdentifier(cleanEmail);
      } else {
        await syncToCloud();
      }
    }

    _userIdentifier = cleanEmail;
    _isLoggedIn = true;
    _isAppUnlocked = true;
    await storageService.setAuthStatus(isLoggedIn: true, identifier: cleanEmail);
    await syncToCloud();
    notifyListeners();
    return true;
  }

  // Sign Out / Switch Account
  Future<void> signOut() async {
    _isLoggedIn = false;
    _isAppUnlocked = true;
    await storageService.setAuthStatus(isLoggedIn: false, identifier: _userIdentifier);
    notifyListeners();
  }

  // Delete Account
  Future<void> deleteAccountPermanently() async {
    await googleDriveService.deleteDriveBackup(googleDriveService.connectedGoogleAccount);
    await storageService.wipeAllAccountData();
    _parties.clear();
    _transactions.clear();
    _cashEntries.clear();
    _deletedItems.clear();
    _businessProfile = BusinessProfile();
    _isLoggedIn = false;
    _userIdentifier = '';
    _isAppLockEnabled = false;
    _appLockPin = '';
    _isAppUnlocked = true;
    notifyListeners();
  }

  // Calculation Helpers
  double getPartyBalance(String partyId) {
    final party = _parties.firstWhere(
      (p) => p.id == partyId,
      orElse: () => Party(id: '', name: '', phone: '', type: PartyType.customer, createdAt: DateTime.now()),
    );
    if (party.id.isEmpty) return 0.0;

    double balance = party.openingBalance;
    final partyTxs = _transactions.where((t) => t.partyId == partyId);

    for (var tx in partyTxs) {
      if (party.type == PartyType.customer) {
        if (tx.type == TransactionType.youGave) {
          balance += tx.amount;
        } else {
          balance -= tx.amount;
        }
      } else {
        if (tx.type == TransactionType.youGot) {
          balance += tx.amount;
        } else {
          balance -= tx.amount;
        }
      }
    }
    return balance;
  }

  Map<String, double> getAllPartyBalances() {
    final map = <String, double>{};
    for (var party in _parties) {
      map[party.id] = getPartyBalance(party.id);
    }
    return map;
  }

  DateTime? getPartyLastActivity(String partyId) {
    final txs = _transactions.where((t) => t.partyId == partyId);
    if (txs.isEmpty) {
      final p = _parties.firstWhere((e) => e.id == partyId, orElse: () => Party(id: '', name: '', phone: '', type: PartyType.customer, createdAt: DateTime.now()));
      return p.createdAt;
    }
    DateTime latest = txs.first.date;
    for (var t in txs) {
      if (t.date.isAfter(latest)) {
        latest = t.date;
      }
    }
    return latest;
  }

  // Total Receivable
  double get totalReceivable {
    double total = 0.0;
    for (var party in _parties) {
      final bal = getPartyBalance(party.id);
      if (party.type == PartyType.customer && bal > 0) {
        total += bal;
      } else if (party.type == PartyType.supplier && bal < 0) {
        total += bal.abs();
      }
    }
    return total;
  }

  // Total Payable
  double get totalPayable {
    double total = 0.0;
    for (var party in _parties) {
      final bal = getPartyBalance(party.id);
      if (party.type == PartyType.supplier && bal > 0) {
        total += bal;
      } else if (party.type == PartyType.customer && bal < 0) {
        total += bal.abs();
      }
    }
    return total;
  }

  int getPendingCount(PartyType type) {
    return _parties.where((p) => p.type == type && getPartyBalance(p.id).abs() > 0.01).length;
  }

  int getSettledCount(PartyType type) {
    return _parties.where((p) => p.type == type && getPartyBalance(p.id).abs() <= 0.01).length;
  }

  List<Party> getFilteredParties(PartyType type) {
    var list = _parties.where((p) {
      if (p.type != type) return false;
      if (_searchQuery.isNotEmpty) {
        final matchesName = p.name.toLowerCase().contains(_searchQuery);
        final matchesPhone = p.phone.toLowerCase().contains(_searchQuery);
        if (!matchesName && !matchesPhone) return false;
      }
      final bal = getPartyBalance(p.id);
      if (_partyFilter == PartyFilter.pendingOnly && bal.abs() <= 0.01) return false;
      if (_partyFilter == PartyFilter.clearedOnly && bal.abs() > 0.01) return false;
      return true;
    }).toList();

    switch (_partySort) {
      case PartySort.name:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case PartySort.balanceHigh:
        list.sort((a, b) {
          final balA = getPartyBalance(a.id).abs();
          final balB = getPartyBalance(b.id).abs();
          return balB.compareTo(balA);
        });
        break;
      case PartySort.recent:
        list.sort((a, b) {
          final dateA = getPartyLastActivity(a.id) ?? a.createdAt;
          final dateB = getPartyLastActivity(b.id) ?? b.createdAt;
          return dateB.compareTo(dateA);
        });
        break;
    }

    return list;
  }

  List<KhataTransaction> getTransactionsForParty(String partyId) {
    return _transactions.where((t) => t.partyId == partyId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Cashbook calculations
  List<CashEntry> getFilteredCashEntries() {
    final now = DateTime.now();
    return _cashEntries.where((c) {
      switch (_cashPeriod) {
        case TimePeriod.today:
          return c.date.year == now.year && c.date.month == now.month && c.date.day == now.day;
        case TimePeriod.thisWeek:
          final diff = now.difference(c.date).inDays;
          return diff >= 0 && diff <= 7;
        case TimePeriod.thisMonth:
          return c.date.year == now.year && c.date.month == now.month;
        case TimePeriod.all:
          return true;
      }
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double get totalCashIn {
    return getFilteredCashEntries()
        .where((c) => c.type == CashType.cashIn)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalCashOut {
    return getFilteredCashEntries()
        .where((c) => c.type == CashType.cashOut)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get todayCashBalance {
    final now = DateTime.now();
    final todayIn = _cashEntries.where((c) =>
        c.type == CashType.cashIn &&
        c.date.year == now.year &&
        c.date.month == now.month &&
        c.date.day == now.day).fold(0.0, (sum, item) => sum + item.amount);

    final todayOut = _cashEntries.where((c) =>
        c.type == CashType.cashOut &&
        c.date.year == now.year &&
        c.date.month == now.month &&
        c.date.day == now.day).fold(0.0, (sum, item) => sum + item.amount);

    return todayIn - todayOut;
  }

  // CRUD Parties
  Future<void> addParty({
    required String name,
    required String phone,
    required PartyType type,
    String address = '',
    double openingBalance = 0.0,
    String notes = '',
  }) async {
    final newParty = Party(
      id: const Uuid().v4(),
      name: name,
      phone: phone,
      type: type,
      address: address,
      createdAt: DateTime.now(),
      openingBalance: openingBalance,
      avatarColorIndex: (_parties.length % 6) + 1,
      notes: notes,
    );
    _parties.insert(0, newParty);
    await storageService.saveParties(_parties);
    await syncToCloud();
    notifyListeners();
  }

  Future<void> updateParty(Party updated) async {
    final idx = _parties.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _parties[idx] = updated;
      await storageService.saveParties(_parties);
      await syncToCloud();
      notifyListeners();
    }
  }

  Future<void> deleteParty(String partyId) async {
    final partyIdx = _parties.indexWhere((p) => p.id == partyId);
    if (partyIdx != -1) {
      final party = _parties[partyIdx];
      final partyTxs = _transactions.where((t) => t.partyId == partyId).toList();
      final balance = getPartyBalance(partyId);

      final deletedItem = DeletedItem(
        id: const Uuid().v4(),
        type: DeletedItemType.party,
        title: party.name,
        subtitle: '${party.type.name.toUpperCase()} • ${partyTxs.length} entries',
        amount: balance,
        deletedAt: DateTime.now(),
        rawData: {
          'party': party.toJson(),
          'transactions': partyTxs.map((t) => t.toJson()).toList(),
        },
      );
      _deletedItems.insert(0, deletedItem);
      await storageService.saveDeletedItems(_deletedItems);

      _parties.removeAt(partyIdx);
      _transactions.removeWhere((t) => t.partyId == partyId);
      await storageService.saveParties(_parties);
      await storageService.saveTransactions(_transactions);
      await syncToCloud();
      notifyListeners();
    }
  }

  // CRUD Transactions
  Future<void> addTransaction({
    required String partyId,
    required double amount,
    required TransactionType type,
    required DateTime date,
    String note = '',
    String billNumber = '',
    PaymentMode paymentMode = PaymentMode.cash,
    String? imagePath,
  }) async {
    final newTx = KhataTransaction(
      id: const Uuid().v4(),
      partyId: partyId,
      amount: amount,
      type: type,
      date: date,
      note: note,
      billNumber: billNumber,
      paymentMode: paymentMode,
      imagePath: imagePath,
    );
    _transactions.insert(0, newTx);
    await storageService.saveTransactions(_transactions);
    await syncToCloud();
    notifyListeners();
  }

  Future<void> deleteTransaction(String txId) async {
    final txIdx = _transactions.indexWhere((t) => t.id == txId);
    if (txIdx != -1) {
      final tx = _transactions[txIdx];
      final party = _parties.firstWhere(
        (p) => p.id == tx.partyId,
        orElse: () => Party(id: '', name: 'Contact', phone: '', type: PartyType.customer, createdAt: DateTime.now()),
      );

      final deletedItem = DeletedItem(
        id: const Uuid().v4(),
        type: DeletedItemType.transaction,
        title: party.name,
        subtitle: tx.note.isNotEmpty ? tx.note : '${tx.type.name} • ${tx.paymentMode.name}',
        amount: tx.amount,
        deletedAt: DateTime.now(),
        rawData: tx.toJson(),
      );
      _deletedItems.insert(0, deletedItem);
      await storageService.saveDeletedItems(_deletedItems);

      _transactions.removeAt(txIdx);
      await storageService.saveTransactions(_transactions);
      await syncToCloud();
      notifyListeners();
    }
  }

  // CRUD Cash Entries
  Future<void> addCashEntry({
    required double amount,
    required CashType type,
    required DateTime date,
    required String category,
    String note = '',
    String paymentMode = 'Cash',
  }) async {
    final entry = CashEntry(
      id: const Uuid().v4(),
      amount: amount,
      type: type,
      date: date,
      category: category,
      note: note,
      paymentMode: paymentMode,
    );
    _cashEntries.insert(0, entry);
    await storageService.saveCashEntries(_cashEntries);
    await syncToCloud();
    notifyListeners();
  }

  Future<void> deleteCashEntry(String id) async {
    final entryIdx = _cashEntries.indexWhere((c) => c.id == id);
    if (entryIdx != -1) {
      final entry = _cashEntries[entryIdx];

      final deletedItem = DeletedItem(
        id: const Uuid().v4(),
        type: DeletedItemType.cashEntry,
        title: entry.category,
        subtitle: entry.note.isNotEmpty ? entry.note : '${entry.type.name} • ${entry.paymentMode}',
        amount: entry.amount,
        deletedAt: DateTime.now(),
        rawData: entry.toJson(),
      );
      _deletedItems.insert(0, deletedItem);
      await storageService.saveDeletedItems(_deletedItems);

      _cashEntries.removeAt(entryIdx);
      await storageService.saveCashEntries(_cashEntries);
      await syncToCloud();
      notifyListeners();
    }
  }

  // Recycle Bin Actions
  Future<void> restoreDeletedItem(DeletedItem item) async {
    if (item.type == DeletedItemType.party) {
      final partyData = item.rawData['party'] as Map<String, dynamic>;
      final restoredParty = Party.fromJson(partyData);
      _parties.removeWhere((p) => p.id == restoredParty.id);
      _parties.insert(0, restoredParty);

      final txList = item.rawData['transactions'] as List?;
      if (txList != null) {
        for (var t in txList) {
          final tx = KhataTransaction.fromJson(t as Map<String, dynamic>);
          _transactions.removeWhere((x) => x.id == tx.id);
          _transactions.add(tx);
        }
      }
      await storageService.saveParties(_parties);
      await storageService.saveTransactions(_transactions);
    } else if (item.type == DeletedItemType.transaction) {
      final tx = KhataTransaction.fromJson(item.rawData);
      _transactions.removeWhere((x) => x.id == tx.id);
      _transactions.insert(0, tx);
      await storageService.saveTransactions(_transactions);
    } else if (item.type == DeletedItemType.cashEntry) {
      final ce = CashEntry.fromJson(item.rawData);
      _cashEntries.removeWhere((x) => x.id == ce.id);
      _cashEntries.insert(0, ce);
      await storageService.saveCashEntries(_cashEntries);
    }

    _deletedItems.removeWhere((d) => d.id == item.id);
    await storageService.saveDeletedItems(_deletedItems);
    await syncToCloud();
    notifyListeners();
  }

  Future<void> permanentlyDelete(String id) async {
    _deletedItems.removeWhere((d) => d.id == id);
    await storageService.saveDeletedItems(_deletedItems);
    await syncToCloud();
    notifyListeners();
  }

  Future<void> emptyRecycleBin() async {
    _deletedItems.clear();
    await storageService.saveDeletedItems(_deletedItems);
    await syncToCloud();
    notifyListeners();
  }

  // Business Profile
  Future<void> updateBusinessProfile(BusinessProfile profile) async {
    _businessProfile = profile;
    await storageService.saveBusinessProfile(profile);
    await syncToCloud();
    notifyListeners();
  }
}
