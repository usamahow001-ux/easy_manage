import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/business_profile.dart';
import '../theme/app_theme.dart';
import 'business_profile_screen.dart';
import 'account_settings_screen.dart';
import 'recycle_bin_screen.dart';
import 'language_selection_screen.dart';
import 'settings_search_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _shareApp() {
    const shareText =
        'Manage your Khata & Customer Ledgers effortlessly with Easy Manage!\nDownload now: https://easymanage.app/download';
    try {
      // ignore: deprecated_member_use
      Share.share(shareText, subject: 'Download Easy Manage');
    } catch (_) {
      Clipboard.setData(const ClipboardData(text: 'https://easymanage.app/download'));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App download link copied to clipboard!')),
      );
    }
  }

  Future<void> _openExternalLink(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 24),
            SizedBox(width: 8),
            Text('Privacy Policy'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Data Encryption & Storage',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
              ),
              const SizedBox(height: 4),
              Text(
                'Easy Manage stores financial records and contacts securely. Data is encrypted locally and synchronized with Firebase Firestore using enterprise security standards.',
                style: GoogleFonts.inter(fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),
              Text(
                '2. Permissions',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
              ),
              const SizedBox(height: 4),
              Text(
                'Contacts and SMS permissions are solely used when you explicitly request to select a party or send payment reminders. Your data is never sold or shared with third parties.',
                style: GoogleFonts.inter(fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _openExternalLink('https://usamahow001-ux.github.io/easy_manage/privacy-policy.html'),
            child: const Text('View on Web'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.description_outlined, color: Color(0xFF3B82F6), size: 24),
            SizedBox(width: 8),
            Text('Terms of Service'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Accurate Record Keeping',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF3B82F6)),
              ),
              const SizedBox(height: 4),
              Text(
                'Users are solely responsible for ensuring financial records and amounts entered into customer and supplier ledgers reflect agreed terms.',
                style: GoogleFonts.inter(fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),
              Text(
                '2. Offline & Cloud Integrity',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF3B82F6)),
              ),
              const SizedBox(height: 4),
              Text(
                'Easy Manage operates completely offline first and auto-syncs when internet is available. Ensure periodic backups to avoid data loss.',
                style: GoogleFonts.inter(fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _openExternalLink('https://usamahow001-ux.github.io/easy_manage/terms.html'),
            child: const Text('View on Web'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final loc = provider.loc;
    final isDark = provider.isDarkMode;
    final business = provider.businessProfile;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.tr('more'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          // 1. Search Settings Icon
          IconButton(
            tooltip: 'Search Settings',
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsSearchScreen()),
              );
            },
          ),
          // 2. Dark Mode Toggle Icon
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppTheme.accentGold : null,
              size: 20,
            ),
            onPressed: () => provider.toggleDarkMode(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // WhatsApp-style Business Profile Header
          _buildWhatsAppProfileCard(context, provider, business, isDark),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // 1. Account Screen (Security, Cloud Sync, Account Info, Log Out, Delete Account)
          _buildSettingsTile(
            icon: Icons.key_rounded,
            iconColor: AppTheme.primaryGreen,
            title: 'Account',
            subtitle: 'Security, cloud sync, logout, delete account',
            isDark: isDark,
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 8),

          // 2. Deleted Items (formerly Recycle Bin: 30-day deleted entries retention)
          _buildSettingsTile(
            icon: Icons.delete_outline_rounded,
            iconColor: AppTheme.debitRed,
            title: 'Deleted Items',
            subtitle: 'Recover deleted entries & parties (${provider.deletedItems.length} items)',
            isDark: isDark,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (provider.deletedItems.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.debitRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${provider.deletedItems.length}',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.debitRed),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RecycleBinScreen()),
              );
            },
          ),
          const SizedBox(height: 8),

          // 3. App Language
          _buildSettingsTile(
            icon: Icons.language_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: loc.tr('language'),
            subtitle: provider.language == AppLanguage.urdu
                ? 'اردو (Urdu)'
                : (provider.language == AppLanguage.romanUrdu ? 'Hinglish (Maine Dena Hai)' : 'English'),
            isDark: isDark,
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LanguageSelectionScreen(isFirstTime: false),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // 4. Privacy Policy (Above Invite a Friend)
          _buildSettingsTile(
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF10B981),
            title: 'Privacy Policy',
            subtitle: 'Data protection, permissions & privacy terms',
            isDark: isDark,
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () => _showPrivacyPolicy(context),
          ),
          const SizedBox(height: 8),

          // 5. Terms of Service (Above Invite a Friend)
          _buildSettingsTile(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF6366F1),
            title: 'Terms of Service',
            subtitle: 'Rules, conditions & terms of ledger usage',
            isDark: isDark,
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () => _showTermsOfService(context),
          ),
          const SizedBox(height: 8),

          // 6. Invite a Friend
          _buildSettingsTile(
            icon: Icons.group_add_outlined,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Invite a Friend',
            subtitle: 'Share Easy Manage download link with friends & merchants',
            isDark: isDark,
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: _shareApp,
          ),
          const SizedBox(height: 36),

          // WhatsApp style "from Easy Manage" footer
          Center(
            child: Column(
              children: [
                Text(
                  'from',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  'Easy Manage',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v1.0.0 • Cloud Synced Ledger',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// WhatsApp-Style Business Profile Card Header
  Widget _buildWhatsAppProfileCard(
    BuildContext context,
    AppStateProvider provider,
    BusinessProfile business,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Avatar with App Icon & edit badge
                Stack(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryGreen, AppTheme.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Container(
                          color: isDark ? AppTheme.darkCardElevated : Colors.white,
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => CircleAvatar(
                              radius: 26,
                              backgroundColor: isDark ? AppTheme.darkCardElevated : const Color(0xFFE8F5E9),
                              child: Text(
                                business.businessName.isNotEmpty ? business.businessName[0].toUpperCase() : 'B',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppTheme.darkCard : Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(Icons.edit, size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                // Business Name & Owner Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        business.businessName.isNotEmpty ? business.businessName : 'My Business',
                        style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        business.ownerName.isNotEmpty
                            ? business.ownerName
                            : (business.phone.isNotEmpty ? business.phone : 'Digital Khata Merchant'),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (business.phone.isNotEmpty && business.ownerName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          business.phone,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // QR Code icon on the right
                IconButton(
                  tooltip: 'Share QR & Profile',
                  icon: const Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryGreen, size: 28),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
