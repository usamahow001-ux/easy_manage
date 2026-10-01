import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_state_provider.dart';
import '../services/google_drive_service.dart';
import '../theme/app_theme.dart';

class ChatBackupScreen extends StatefulWidget {
  const ChatBackupScreen({super.key});

  @override
  State<ChatBackupScreen> createState() => _ChatBackupScreenState();
}

class _ChatBackupScreenState extends State<ChatBackupScreen> {
  bool _isBackingUp = false;
  double _backupProgress = 0.0;
  String _backupStatusText = '';

  Future<void> _performWhatsAppStyleBackup() async {
    final provider = context.read<AppStateProvider>();
    final driveService = provider.googleDriveService;

    final account = driveService.connectedGoogleAccount.trim();
    if (account.isEmpty) {
      final signedIn = await driveService.signInWithGoogle();
      setState(() {});
      if (signedIn == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a Google Account to back up.')),
          );
        }
        return;
      }
    }

    setState(() {
      _isBackingUp = true;
      _backupProgress = 0.2;
      _backupStatusText = 'Creating local encrypted snapshot...';
    });

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _backupProgress = 0.6;
      _backupStatusText = 'Connecting to Google Drive ($account)...';
    });

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _backupProgress = 0.85;
      _backupStatusText = 'Uploading ledger data to Drive...';
    });

    final info = await provider.backupToGoogleDrive();

    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    setState(() {
      _backupProgress = 1.0;
      _backupStatusText = 'Backup completed!';
      _isBackingUp = false;
    });

    if (driveService.lastCloudBackupError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Local backup saved, but Google Drive Cloud: ${driveService.lastCloudBackupError}'),
          backgroundColor: Colors.orange.shade900,
          duration: const Duration(seconds: 6),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('✓ Backed up to Google Drive Cloud (${info.backupSizeKb} KB)'),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isDark = provider.isDarkMode;
    final driveService = provider.googleDriveService;
    final backupMeta = driveService.getBackupMetadata();
    final connectedEmail = driveService.connectedGoogleAccount;
    final isVerified = driveService.isAccountVerified;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Google Drive & Chat Backup',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'What is Saved in Backup',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF4285F4).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF4285F4),
                size: 20,
              ),
            ),
            onPressed: () => _showBackupInfoModal(context, provider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // WhatsApp Style Top Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.cloud_upload_rounded, color: AppTheme.primaryGreen, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Last Backup',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Back up your customers, suppliers, transactions, and cashbook to your verified Google Drive account. You can restore them anytime you reinstall the app.",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                // Backup Meta Details
                _buildBackupDetailRow('Local Phone:', dateFormat.format(provider.lastSyncTime)),
                _buildBackupDetailRow(
                  'Google Drive:',
                  backupMeta != null ? dateFormat.format(backupMeta.lastBackupTime) : 'Never',
                ),
                _buildBackupDetailRow(
                  'Size:',
                  backupMeta != null ? '${backupMeta.backupSizeKb} KB' : '0 KB',
                ),
                _buildBackupDetailRow(
                  'Google Account:',
                  connectedEmail.isNotEmpty
                      ? (isVerified ? '$connectedEmail (✓ Verified)' : '$connectedEmail (Unverified)')
                      : 'Not connected',
                ),
                if (_isBackingUp) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _backupProgress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _backupStatusText,
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 16),
                // Prominent WhatsApp Style BACK UP Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: _isBackingUp
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.cloud_upload_rounded, size: 20),
                    label: Text(
                      _isBackingUp ? 'Backing up...' : 'BACK UP NOW',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                    ),
                    onPressed: _isBackingUp ? null : _performWhatsAppStyleBackup,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Google Drive Settings Section Header
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Google Account & Settings',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          // Settings Card Container
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            child: Column(
              children: [
                // 1. Google Account (with verification status)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_circle_rounded, color: Color(0xFF4285F4), size: 22),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Google Account',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (connectedEmail.isNotEmpty && isVerified) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.creditGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '✓ Verified',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.creditGreen),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    connectedEmail.isNotEmpty
                        ? connectedEmail
                        : 'Tap to connect & verify Google email',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: connectedEmail.isNotEmpty
                          ? (isDark ? Colors.grey : Colors.black87)
                          : AppTheme.primaryGreen,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () => _handleGoogleAccountConnect(context, provider),
                ),
                const Divider(height: 1, indent: 56),

                // 2. Frequency
                ListTile(
                  leading: const Icon(Icons.history_rounded, color: AppTheme.primaryGreen),
                  title: Text('Back up to Google Drive', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(driveService.backupFrequency, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () => _showFrequencySelector(context, driveService),
                ),
                const Divider(height: 1, indent: 56),

                // 3. Back up over
                ListTile(
                  leading: const Icon(Icons.wifi_rounded, color: Color(0xFFF59E0B)),
                  title: Text('Back up over', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(driveService.backupNetwork, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () => _showNetworkSelector(context, driveService),
                ),
                const Divider(height: 1, indent: 56),

                // 4. Include media
                SwitchListTile(
                  secondary: const Icon(Icons.image_outlined, color: Color(0xFF8B5CF6)),
                  title: Text('Include Bill Photos', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('Back up transaction slip attachments', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  value: driveService.includeMedia,
                  activeThumbColor: AppTheme.primaryGreen,
                  onChanged: (val) async {
                    await driveService.setIncludeMedia(val);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Restore Section
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Restore & Sync Data',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.cloud_download_rounded, color: Color(0xFF4285F4), size: 22),
                  ),
                  title: Text('Restore from Google Drive', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('Search and download ledger backup from your verified Google account', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () => _showRestoreFromDriveFlow(context, provider),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.share_outlined, color: Colors.teal, size: 22),
                  ),
                  title: Text('Export File / Share', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('Share ledger backup file via WhatsApp or Email', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () {
                    final jsonString = provider.storageService.exportAllDataJson();
                    SharePlus.instance.share(
                      ShareParams(
                        text: jsonString,
                        subject: 'EasyManage Khata Backup ${DateTime.now().toIso8601String()}',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildIncludedItemRow(IconData icon, String title, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF4285F4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            count,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showBackupInfoModal(BuildContext context, AppStateProvider provider) {
    final isDark = provider.isDarkMode;
    final business = provider.businessProfile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4285F4).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF4285F4), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What is Saved in Google Backup?',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Complete Ledger Snapshot Breakdown',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Your encrypted Google Drive backup preserves a complete snapshot of your business ledger data so you can restore it anytime you reinstall or switch devices:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCardElevated : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                  ),
                  child: Column(
                    children: [
                      _buildIncludedItemRow(
                        Icons.storefront_rounded,
                        'Business Profile',
                        '${business.businessName.isNotEmpty ? business.businessName : 'My Business'} (${business.currencyCode})',
                      ),
                      const Divider(height: 14),
                      _buildIncludedItemRow(
                        Icons.people_outline_rounded,
                        'Contacts & Ledgers',
                        '${provider.parties.length} contacts saved',
                      ),
                      const Divider(height: 14),
                      _buildIncludedItemRow(
                        Icons.swap_horiz_rounded,
                        'Khata Transactions',
                        '${provider.transactions.length} entries (Maine Diye / Liye)',
                      ),
                      const Divider(height: 14),
                      _buildIncludedItemRow(
                        Icons.account_balance_wallet_outlined,
                        'Cashbook Records',
                        '${provider.cashEntries.length} cash flow records',
                      ),
                      const Divider(height: 14),
                      _buildIncludedItemRow(
                        Icons.calculate_outlined,
                        'Calculator History',
                        '${provider.calculatorHistory.length} saved calculations',
                      ),
                      const Divider(height: 14),
                      _buildIncludedItemRow(
                        Icons.delete_outline_rounded,
                        'Recycle Bin Items',
                        '${provider.deletedItems.length} deleted records (30-day safety)',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppTheme.primaryGreen, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '100% Private & Encrypted: Only your verified Google Account can download or restore this backup.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Got It',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackupDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _showFrequencySelector(BuildContext context, GoogleDriveService driveService) {
    final options = ['Daily', 'Weekly', 'Monthly', 'Only when I tap "Back up"', 'Never'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Back up to Google Drive'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final isSelected = driveService.backupFrequency == opt;
            return ListTile(
              title: Text(opt, style: GoogleFonts.inter(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen) : null,
              onTap: () async {
                await driveService.setBackupFrequency(opt);
                setState(() {});
                if (ctx.mounted) Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showNetworkSelector(BuildContext context, GoogleDriveService driveService) {
    final options = ['Wi-Fi only', 'Wi-Fi or cellular'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Back up over'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final isSelected = driveService.backupNetwork == opt;
            return ListTile(
              title: Text(opt, style: GoogleFonts.inter(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen) : null,
              onTap: () async {
                await driveService.setBackupNetwork(opt);
                setState(() {});
                if (ctx.mounted) Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // 1-Tap Google Account Connection (Android / iOS System Account Selector)
  Future<void> _handleGoogleAccountConnect(BuildContext context, AppStateProvider provider) async {
    final driveService = provider.googleDriveService;

    if (driveService.connectedGoogleAccount.isNotEmpty) {
      // Account already linked: show switch or sign out options
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_circle_rounded, color: Color(0xFF4285F4), size: 24),
              ),
              const SizedBox(width: 10),
              Text('Google Account', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Currently connected:', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                driveService.connectedGoogleAccount,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF4285F4)),
              ),
              if (driveService.connectedDisplayName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(driveService.connectedDisplayName, style: GoogleFonts.inter(fontSize: 12)),
              ],
              const SizedBox(height: 16),
              const Text('Would you like to switch to another Google account on this device or sign out?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await driveService.signOutGoogle();
                setState(() {});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Disconnected Google Account.')),
                  );
                }
              },
              child: const Text('Sign Out', style: TextStyle(color: AppTheme.debitRed)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final account = await driveService.signInWithGoogle();
                setState(() {});
                if (account != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ Switched to Google Account: ${account.email}'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                }
              },
              child: const Text('Switch Account', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    // Connect via native Google Sign-In Account Selector
    final account = await driveService.signInWithGoogle();
    setState(() {});
    if (account != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Connected Google Account: ${account.email}'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } else if (driveService.lastSignInError != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(driveService.lastSignInError!),
          backgroundColor: AppTheme.debitRed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Interactive Restore from Google Drive with 1-Tap Account Selector & Preview
  Future<void> _showRestoreFromDriveFlow(BuildContext context, AppStateProvider provider) async {
    final driveService = provider.googleDriveService;

    // If no Google account linked, trigger 1-tap Google Sign-In
    if (driveService.connectedGoogleAccount.isEmpty) {
      final account = await driveService.signInWithGoogle();
      setState(() {});
      if (account == null) return;
    }

    if (!context.mounted) return;

    final email = driveService.connectedGoogleAccount;

    // Show quick progress dialog while searching Google Drive
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryGreen),
                SizedBox(height: 14),
                Text('Searching Google Drive for backup...'),
              ],
            ),
          ),
        ),
      ),
    );

    final foundPayload = await driveService.fetchDriveBackupPayload(email);

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final partiesCount = (foundPayload?['parties'] as List?)?.length ?? 0;
          final txCount = (foundPayload?['transactions'] as List?)?.length ?? 0;
          final cashCount = (foundPayload?['cashEntries'] as List?)?.length ?? 0;
          final timestamp = foundPayload?['backupTimestamp'] as String? ?? '';
          final dateStr = timestamp.isNotEmpty
              ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(timestamp))
              : 'N/A';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_download_rounded, color: Color(0xFF4285F4), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Restore from Google Drive',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF4285F4).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_circle_rounded, color: Color(0xFF4285F4), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Google Drive Account', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                              Text(
                                email,
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final switched = await driveService.signInWithGoogle();
                            setState(() {});
                            if (switched != null && context.mounted) {
                              _showRestoreFromDriveFlow(context, provider);
                            }
                          },
                          child: const Text('Switch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (foundPayload != null) ...[
                    // Backup Found Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Backup Found on Google Drive!',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGreen),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('📅 Date: $dateStr', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('👥 Contacts: $partiesCount (Customers & Suppliers)', style: GoogleFonts.inter(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('📝 Ledger Transactions: $txCount entries', style: GoogleFonts.inter(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('💵 Cashbook Records: $cashCount entries', style: GoogleFonts.inter(fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '⚠️ Restoring will download this backup snapshot and replace current local entries.',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.orange.shade800),
                    ),
                  ] else ...[
                    // No Backup Found on this account
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppTheme.debitRed, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No ledger backup found on this Google Drive account yet. Tap "Switch" above to pick another account or tap "Back Up Now" to save your data.',
                              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.debitRed),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              if (foundPayload != null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final success = await provider.restoreFromGoogleDrive(email);
                    setState(() {});
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? '✓ Google Drive backup restored successfully!' : 'Failed to restore backup.'),
                          backgroundColor: success ? AppTheme.primaryGreen : AppTheme.debitRed,
                        ),
                      );
                    }
                  },
                  child: const Text('Restore My Ledger', style: TextStyle(color: Colors.white)),
                ),
            ],
          );
        },
      ),
    );
  }
}
