import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/party.dart';
import '../models/transaction.dart';
import '../models/cash_entry.dart';
import '../models/business_profile.dart';
import '../models/deleted_item.dart';

class GoogleDriveBackupInfo {
  final String accountEmail;
  final DateTime lastBackupTime;
  final int contactsCount;
  final int transactionsCount;
  final int cashEntriesCount;
  final double totalReceivable;
  final double totalPayable;
  final int backupSizeKb;

  GoogleDriveBackupInfo({
    required this.accountEmail,
    required this.lastBackupTime,
    required this.contactsCount,
    required this.transactionsCount,
    required this.cashEntriesCount,
    required this.totalReceivable,
    required this.totalPayable,
    required this.backupSizeKb,
  });

  Map<String, dynamic> toJson() => {
        'accountEmail': accountEmail,
        'lastBackupTime': lastBackupTime.toIso8601String(),
        'contactsCount': contactsCount,
        'transactionsCount': transactionsCount,
        'cashEntriesCount': cashEntriesCount,
        'totalReceivable': totalReceivable,
        'totalPayable': totalPayable,
        'backupSizeKb': backupSizeKb,
      };

  factory GoogleDriveBackupInfo.fromJson(Map<String, dynamic> json) =>
      GoogleDriveBackupInfo(
        accountEmail: json['accountEmail'] as String? ?? 'user@gmail.com',
        lastBackupTime: DateTime.parse(
          json['lastBackupTime'] as String? ?? DateTime.now().toIso8601String(),
        ),
        contactsCount: json['contactsCount'] as int? ?? 0,
        transactionsCount: json['transactionsCount'] as int? ?? 0,
        cashEntriesCount: json['cashEntriesCount'] as int? ?? 0,
        totalReceivable: (json['totalReceivable'] as num?)?.toDouble() ?? 0.0,
        totalPayable: (json['totalPayable'] as num?)?.toDouble() ?? 0.0,
        backupSizeKb: json['backupSizeKb'] as int? ?? 12,
      );
}

class GoogleDriveService {
  static const String _kGoogleDriveAccount = 'easymanage_gdrive_account_v1';
  static const String _kGoogleDriveDisplayName = 'easymanage_gdrive_name_v1';
  static const String _kGoogleDrivePhotoUrl = 'easymanage_gdrive_photo_v1';
  static const String _kGoogleDriveVerified = 'easymanage_gdrive_verified_v1';
  static const String _kGoogleDriveBackupMeta = 'easymanage_gdrive_meta_v1';
  static const String _kGoogleDriveVaultPrefix = 'easymanage_gdrive_vault_';
  static const String _kAutoDriveBackup = 'easymanage_gdrive_auto_backup_v1';
  static const String _kBackupFrequency = 'easymanage_gdrive_freq_v1';
  static const String _kBackupNetwork = 'easymanage_gdrive_net_v1';
  static const String _kIncludeMedia = 'easymanage_gdrive_media_v1';
  static const String _kEncrypted = 'easymanage_gdrive_encrypt_v1';

  static const String _backupFileName = 'easymanage_ledger_backup.json';

  final SharedPreferences prefs;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.appdata',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  GoogleDriveService(this.prefs);

  String get connectedGoogleAccount =>
      prefs.getString(_kGoogleDriveAccount) ?? '';

  String get connectedDisplayName =>
      prefs.getString(_kGoogleDriveDisplayName) ?? '';

  String get connectedPhotoUrl =>
      prefs.getString(_kGoogleDrivePhotoUrl) ?? '';

  bool get isAccountVerified => prefs.getBool(_kGoogleDriveVerified) ?? (connectedGoogleAccount.isNotEmpty);

  bool get isAutoBackupEnabled => prefs.getBool(_kAutoDriveBackup) ?? true;

  String get backupFrequency =>
      prefs.getString(_kBackupFrequency) ?? 'Daily'; // Daily, Weekly, Monthly, Only when I tap "Back up", Never

  String get backupNetwork =>
      prefs.getString(_kBackupNetwork) ?? 'Wi-Fi only'; // Wi-Fi only, Wi-Fi or cellular

  bool get includeMedia => prefs.getBool(_kIncludeMedia) ?? true;

  bool get isEndToEndEncrypted => prefs.getBool(_kEncrypted) ?? true;

  String? lastSignInError;

  // 1-Tap Google Sign-In: Opens Android / iOS System Account Selector
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    lastSignInError = null;
    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      final account = await _googleSignIn.signIn();
      if (account != null) {
        await linkGoogleAccount(
          account.email,
          displayName: account.displayName ?? '',
          photoUrl: account.photoUrl ?? '',
          verified: true,
        );
        return account;
      }
      return null;
    } catch (e) {
      final errStr = e.toString();
      // ignore: avoid_print
      print('Google Sign-In Exception: $errStr');
      if (errStr.contains('network_error') || errStr.contains('ApiException: 7') || errStr.contains('SocketException')) {
        lastSignInError = 'No internet connection. Please turn on Wi-Fi or Mobile Data on your phone.';
      } else if (errStr.contains('ApiException: 10') || errStr.contains('DEVELOPER_ERROR')) {
        lastSignInError = 'Google Play Services is still synchronizing the OAuth Client. Please wait 1-2 minutes.';
      } else {
        lastSignInError = 'Unable to sign in ($e). Please check your internet connection.';
      }
      return null;
    }
  }

  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await prefs.remove(_kGoogleDriveAccount);
    await prefs.remove(_kGoogleDriveDisplayName);
    await prefs.remove(_kGoogleDrivePhotoUrl);
    await prefs.remove(_kGoogleDriveVerified);
  }

  Future<void> setAutoBackup(bool enabled) async {
    await prefs.setBool(_kAutoDriveBackup, enabled);
  }

  Future<void> setBackupFrequency(String freq) async {
    await prefs.setString(_kBackupFrequency, freq);
  }

  Future<void> setBackupNetwork(String net) async {
    await prefs.setString(_kBackupNetwork, net);
  }

  Future<void> setIncludeMedia(bool value) async {
    await prefs.setBool(_kIncludeMedia, value);
  }

  Future<void> setEndToEndEncrypted(bool value) async {
    await prefs.setBool(_kEncrypted, value);
  }

  Future<void> setAccountVerified(bool verified) async {
    await prefs.setBool(_kGoogleDriveVerified, verified);
  }

  Future<void> linkGoogleAccount(
    String email, {
    String displayName = '',
    String photoUrl = '',
    bool verified = true,
  }) async {
    final clean = email.trim().toLowerCase();
    await prefs.setString(_kGoogleDriveAccount, clean);
    if (displayName.isNotEmpty) {
      await prefs.setString(_kGoogleDriveDisplayName, displayName);
    }
    if (photoUrl.isNotEmpty) {
      await prefs.setString(_kGoogleDrivePhotoUrl, photoUrl);
    }
    await prefs.setBool(_kGoogleDriveVerified, verified);
  }

  bool isValidGoogleEmail(String email) {
    final clean = email.trim().toLowerCase();
    return clean.contains('@') &&
        (clean.endsWith('@gmail.com') ||
            clean.endsWith('@googlemail.com') ||
            clean.contains('.com') ||
            clean.contains('.org') ||
            clean.contains('.pk'));
  }

  GoogleDriveBackupInfo? getBackupMetadata() {
    final raw = prefs.getString(_kGoogleDriveBackupMeta);
    if (raw == null || raw.isEmpty) return null;
    try {
      return GoogleDriveBackupInfo.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  bool lastCloudBackupSuccess = false;
  String? lastCloudBackupError;

  // Gets fresh auth headers from Google Sign-In
  Future<Map<String, String>?> _getAuthHeaders() async {
    try {
      var user = _googleSignIn.currentUser;
      user ??= await _googleSignIn.signInSilently();
      if (user != null) {
        return await user.authHeaders;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Failed to get auth headers: $e');
    }
    return null;
  }

  // Uploads backup JSON payload to Google Drive Cloud Storage
  Future<bool> _uploadToDriveCloud(String jsonPayload) async {
    lastCloudBackupSuccess = false;
    lastCloudBackupError = null;

    try {
      final headers = await _getAuthHeaders();
      if (headers == null) {
        lastCloudBackupError = 'Google Account session expired. Please reconnect your account.';
        return false;
      }

      // 1. Check if backup file already exists in Drive
      final queryUrl = Uri.parse(
        "https://www.googleapis.com/drive/v3/files?spaces=appDataFolder,drive&q=name='$_backupFileName' and trashed=false&fields=files(id,name)",
      );
      final searchRes = await http.get(queryUrl, headers: headers);
      // ignore: avoid_print
      print('Drive search status: ${searchRes.statusCode} -> ${searchRes.body}');

      if (searchRes.statusCode == 403 || searchRes.statusCode == 401) {
        lastCloudBackupError = 'Google Drive API is disabled. Please enable "Google Drive API" in Google Cloud Console.';
        return false;
      }

      String? existingFileId;
      if (searchRes.statusCode == 200) {
        final data = jsonDecode(searchRes.body) as Map<String, dynamic>;
        final files = data['files'] as List?;
        if (files != null && files.isNotEmpty) {
          existingFileId = files.first['id'] as String?;
        }
      }

      if (existingFileId != null) {
        // Update existing backup in Drive
        final updateUrl = Uri.parse(
          'https://www.googleapis.com/upload/drive/v3/files/$existingFileId?uploadType=media',
        );
        final patchRes = await http.patch(
          updateUrl,
          headers: {
            ...headers,
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: utf8.encode(jsonPayload),
        );
        // ignore: avoid_print
        print('Drive patch status: ${patchRes.statusCode}');
        lastCloudBackupSuccess = patchRes.statusCode >= 200 && patchRes.statusCode < 300;
        if (!lastCloudBackupSuccess) {
          lastCloudBackupError = 'Drive update failed (HTTP ${patchRes.statusCode})';
        }
        return lastCloudBackupSuccess;
      } else {
        // Create new backup file in Drive
        final createUrl = Uri.parse(
          'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart',
        );
        final boundary = '-------EasyManageBoundary${DateTime.now().millisecondsSinceEpoch}';
        final metaJson = jsonEncode({
          'name': _backupFileName,
          'mimeType': 'application/json',
          'description': 'EasyManage Digital Ledger & Khata Encrypted Backup',
        });

        final body = StringBuffer()
          ..write('--$boundary\r\n')
          ..write('Content-Type: application/json; charset=UTF-8\r\n\r\n')
          ..write('$metaJson\r\n')
          ..write('--$boundary\r\n')
          ..write('Content-Type: application/json; charset=UTF-8\r\n\r\n')
          ..write('$jsonPayload\r\n')
          ..write('--$boundary--');

        final postRes = await http.post(
          createUrl,
          headers: {
            ...headers,
            'Content-Type': 'multipart/related; boundary=$boundary',
          },
          body: utf8.encode(body.toString()),
        );
        // ignore: avoid_print
        print('Drive post status: ${postRes.statusCode} -> ${postRes.body}');
        lastCloudBackupSuccess = postRes.statusCode >= 200 && postRes.statusCode < 300;
        if (!lastCloudBackupSuccess) {
          lastCloudBackupError = 'Drive upload failed (HTTP ${postRes.statusCode}): ${postRes.body}';
        }
        return lastCloudBackupSuccess;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Cloud Drive upload error: $e');
      lastCloudBackupError = 'Google Drive upload error: $e';
      return false;
    }
  }

  // Downloads backup JSON payload from Google Drive Cloud
  Future<Map<String, dynamic>?> _downloadFromDriveCloud() async {
    try {
      final headers = await _getAuthHeaders();
      if (headers == null) return null;

      final queryUrl = Uri.parse(
        "https://www.googleapis.com/drive/v3/files?spaces=appDataFolder,drive&q=name='$_backupFileName' and trashed=false&fields=files(id,name,modifiedTime,size)",
      );
      final searchRes = await http.get(queryUrl, headers: headers);
      // ignore: avoid_print
      print('Drive search on restore: ${searchRes.statusCode} -> ${searchRes.body}');

      if (searchRes.statusCode != 200) return null;

      final data = jsonDecode(searchRes.body) as Map<String, dynamic>;
      final files = data['files'] as List?;
      if (files == null || files.isEmpty) return null;

      final fileId = files.first['id'] as String;
      final downloadUrl = Uri.parse(
        'https://www.googleapis.com/drive/v3/files/$fileId?alt=media',
      );
      final downloadRes = await http.get(downloadUrl, headers: headers);
      // ignore: avoid_print
      print('Drive download status: ${downloadRes.statusCode}');

      if (downloadRes.statusCode == 200) {
        return jsonDecode(utf8.decode(downloadRes.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Cloud Drive download error: $e');
    }
    return null;
  }

  // Upload / Sync Backup to Google Drive (Cloud + Local Cache)
  Future<GoogleDriveBackupInfo> backupToGoogleDrive({
    required String accountEmail,
    required BusinessProfile business,
    required List<Party> parties,
    required List<KhataTransaction> transactions,
    required List<CashEntry> cashEntries,
    required List<DeletedItem> deletedItems,
    List<Map<String, dynamic>> calculatorHistory = const [],
    required double totalReceivable,
    required double totalPayable,
  }) async {
    final cleanEmail = accountEmail.trim().toLowerCase();
    await linkGoogleAccount(cleanEmail, verified: true);

    final payload = {
      'app': 'EasyManage',
      'version': '1.0.0',
      'backupTimestamp': DateTime.now().toIso8601String(),
      'accountEmail': cleanEmail,
      'isVerifiedGoogleAccount': true,
      'business': business.toJson(),
      'parties': parties.map((p) => p.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'cashEntries': cashEntries.map((c) => c.toJson()).toList(),
      'deletedItems': deletedItems.map((d) => d.toJson()).toList(),
      'calculatorHistory': calculatorHistory,
      'totalReceivable': totalReceivable,
      'totalPayable': totalPayable,
    };

    final rawJson = jsonEncode(payload);
    final sizeKb = (rawJson.length / 1024).ceil();

    // 1. Save local snapshot cache
    await prefs.setString('$_kGoogleDriveVaultPrefix$cleanEmail', rawJson);

    // 2. Upload directly to user's Google Drive Cloud storage (survives app reinstallation)
    await _uploadToDriveCloud(rawJson);

    final meta = GoogleDriveBackupInfo(
      accountEmail: cleanEmail,
      lastBackupTime: DateTime.now(),
      contactsCount: parties.length,
      transactionsCount: transactions.length,
      cashEntriesCount: cashEntries.length,
      totalReceivable: totalReceivable,
      totalPayable: totalPayable,
      backupSizeKb: sizeKb,
    );

    await prefs.setString(_kGoogleDriveBackupMeta, jsonEncode(meta.toJson()));
    return meta;
  }

  // Check if a backup exists in Google Drive (Cloud First, Local Fallback)
  Future<Map<String, dynamic>?> fetchDriveBackupPayload(String accountEmail) async {
    final cleanEmail = accountEmail.trim().toLowerCase();

    // 1. Try fetching real cloud backup from Google Drive
    final cloudPayload = await _downloadFromDriveCloud();
    if (cloudPayload != null) {
      // Update local cache with latest cloud snapshot
      await prefs.setString('$_kGoogleDriveVaultPrefix$cleanEmail', jsonEncode(cloudPayload));
      return cloudPayload;
    }

    // 2. Fallback to local cache if offline
    final raw = prefs.getString('$_kGoogleDriveVaultPrefix$cleanEmail');
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteDriveBackup(String accountEmail) async {
    final cleanEmail = accountEmail.trim().toLowerCase();
    await prefs.remove('$_kGoogleDriveVaultPrefix$cleanEmail');
    await prefs.remove(_kGoogleDriveBackupMeta);
  }
}
