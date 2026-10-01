import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'recycle_bin_screen.dart';
import 'chat_backup_screen.dart';
import 'language_selection_screen.dart';
import 'reports_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isAppSettingsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final loc = provider.loc;
    final isDark = provider.isDarkMode;
    final business = provider.businessProfile;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.tr('more'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.accentGold.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDark ? AppTheme.accentGold : AppTheme.lightTextSecondary,
                size: 20,
              ),
            ),
            onPressed: () => provider.toggleDarkMode(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Business Profile Card at Top (Interactive & Fully Responsive)
          Container(
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
                onTap: () => _showEditBusinessModal(context, provider),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryGreen, AppTheme.primaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
                          child: const Icon(Icons.store_rounded, color: AppTheme.primaryGreen, size: 24),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              business.businessName.isNotEmpty ? business.businessName : loc.tr('business_name'),
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              business.ownerName.isNotEmpty ? '${loc.tr('owner_name')}: ${business.ownerName}' : loc.tr('app_tagline'),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (business.phone.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 12, color: AppTheme.primaryGreen),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      business.phone,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppTheme.primaryGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              loc.tr('edit'),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // WhatsApp Style Google Drive Backup Tile
          _buildSectionHeader(loc.tr('cloud_backup_title'), isDark),
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.add_to_drive_rounded,
            iconColor: const Color(0xFF4285F4),
            title: loc.tr('chat_backup'),
            subtitle: loc.tr('chat_backup_subtitle'),
            isDark: isDark,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Google Drive',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF4285F4)),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChatBackupScreen()),
              );
            },
          ),
          const SizedBox(height: 20),

          // General Settings Section
          _buildSectionHeader(loc.tr('general_preferences'), isDark),
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.language_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: loc.tr('language'),
            subtitle: provider.language == AppLanguage.urdu
                ? 'اردو (Urdu)'
                : (provider.language == AppLanguage.romanUrdu ? 'Hinglish (Maine Dena Hai)' : 'English'),
            isDark: isDark,
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () => _showLanguageDialog(context, provider),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.attach_money_rounded,
            iconColor: AppTheme.accentGold,
            title: loc.tr('currency'),
            subtitle: '${business.currencySymbol} (${business.currencyCode})',
            isDark: isDark,
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () => _showCurrencyDialog(context, provider),
          ),

          const SizedBox(height: 20),
          // Expandable APP SETTINGS Section
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: _isAppSettingsExpanded,
                onExpansionChanged: (val) => setState(() => _isAppSettingsExpanded = val),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppTheme.primaryGreen, size: 22),
                ),
                title: Text(
                  loc.tr('app_settings_security'),
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  loc.tr('app_settings_security_subtitle'),
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
                children: [
                  const Divider(height: 1),
                  // 1. App Lock / PIN Lock
                  ListTile(
                    leading: Icon(
                      provider.isAppLockEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
                      color: provider.isAppLockEnabled ? AppTheme.creditGreen : AppTheme.accentGold,
                      size: 22,
                    ),
                    title: Text(loc.tr('app_lock_security'), style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(
                      provider.isAppLockEnabled ? loc.tr('app_lock_enabled_subtitle') : loc.tr('app_lock_disabled_subtitle'),
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    onTap: () => _showAppLockModal(context, provider),
                  ),
                  const Divider(height: 1, indent: 56),
                  // 2. Privacy Policy
                  ListTile(
                    leading: const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 22),
                    title: Text(loc.tr('privacy_policy'), style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(loc.tr('privacy_policy_subtitle'), style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    onTap: () => _showPrivacyPolicyModal(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  // 3. Terms of Service
                  ListTile(
                    leading: const Icon(Icons.description_outlined, color: Color(0xFF3B82F6), size: 22),
                    title: Text(loc.tr('terms_of_service'), style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(loc.tr('terms_subtitle'), style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    onTap: () => _showTermsModal(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  // 4. Data Reset
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_rounded, color: AppTheme.debitRed, size: 22),
                    title: Text(loc.tr('delete_account'), style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.debitRed)),
                    subtitle: Text(loc.tr('delete_account_subtitle'), style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.debitRed),
                    onTap: () => _showDeleteAccountConfirmation(context, provider),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Business Reports & Statements Section (Under App Settings & Security)
          _buildSectionHeader(loc.tr('business_reports'), isDark),
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.analytics_outlined,
            iconColor: const Color(0xFF0F766E),
            title: loc.tr('business_reports'),
            subtitle: loc.tr('business_reports_subtitle'),
            isDark: isDark,
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
          ),
          const SizedBox(height: 20),

          // 30-Day Recycle Bin Section
          _buildSectionHeader(loc.tr('recycle_bin_section'), isDark),
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.delete_outline_rounded,
            iconColor: AppTheme.debitRed,
            title: loc.tr('recycle_bin'),
            subtitle: '${loc.tr('recycle_bin_subtitle')} (${provider.deletedItems.length} items)',
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

          const SizedBox(height: 32),
          // Version Footer at Bottom
          Center(
            child: Column(
              children: [
                Text(
                  loc.tr('app_name'),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${loc.tr('version')} • 100% Secure & Offline-First',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
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
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 2. App Lock Modal
  void _showAppLockModal(BuildContext context, AppStateProvider provider) {
    final pinController = TextEditingController();
    bool isSettingNewPin = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: provider.isDarkMode ? AppTheme.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  top: 14,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
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
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          provider.loc.tr('app_lock_security'),
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable 4-Digit PIN Lock'),
                      subtitle: const Text('Require PIN each time app is opened'),
                      value: provider.isAppLockEnabled,
                      activeThumbColor: AppTheme.primaryGreen,
                      onChanged: (val) {
                        if (val) {
                          setModalState(() => isSettingNewPin = true);
                        } else {
                          provider.setAppLock(enabled: false, pin: '');
                          setModalState(() => isSettingNewPin = false);
                        }
                      },
                    ),
                    if (isSettingNewPin || (provider.isAppLockEnabled && provider.appLockPin.isEmpty)) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text('Enter new 4-digit security PIN:'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                        decoration: const InputDecoration(
                          hintText: '••••',
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            final pin = pinController.text.trim();
                            if (pin.length != 4) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('PIN must be 4 digits')),
                              );
                              return;
                            }
                            provider.setAppLock(enabled: true, pin: pin);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✓ App Lock PIN configured successfully')),
                            );
                          },
                          child: Text(provider.loc.tr('save')),
                        ),
                      ),
                    ],
                    if (provider.isAppLockEnabled && provider.appLockPin.isNotEmpty) ...[
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Biometric Fingerprint / Face ID'),
                        subtitle: const Text('Quick unlock using biometric sensor'),
                        value: provider.isBiometricEnabled,
                        activeThumbColor: AppTheme.primaryGreen,
                        onChanged: (val) => provider.setBiometricEnabled(val),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.pin_outlined, color: AppTheme.primaryGreen),
                        title: const Text('Change Security PIN'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => setModalState(() => isSettingNewPin = true),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

  // 3. Privacy Policy Modal
  void _showPrivacyPolicyModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(22),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Privacy Policy', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('1. Data Ownership & Security', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                  const SizedBox(height: 4),
                  Text(
                    'Easy Manage is built with an offline-first architecture. All customer records, invoices, supplier payables, and cashbook entries are encrypted and stored locally on your device with optional encrypted Google Drive backup.',
                    style: GoogleFonts.inter(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  Text('2. Automated 30-Day Recycle Bin', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                  const SizedBox(height: 4),
                  Text(
                    'When contacts or transactions are deleted, they are stored in the in-app Recycle Bin for 30 days to prevent accidental data loss. After 30 days, they are permanently purged.',
                    style: GoogleFonts.inter(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  Text('3. Private Google Drive Backups', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                  const SizedBox(height: 4),
                  Text(
                    'Your Google Drive backups are stored in your own personal Google account storage. We do not access, sell, or share your business ledger data.',
                    style: GoogleFonts.inter(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  // Button: Open Full Online Policy
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppTheme.primaryGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.open_in_browser_rounded, color: AppTheme.primaryGreen, size: 20),
                    label: const Text(
                      'View Full Official Privacy Policy (Web)',
                      style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    onPressed: () => _openExternalLink('https://usamahow001-ux.github.io/easy_manage/privacy-policy.html'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('I Understand & Agree'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Terms of Service Modal
  void _showTermsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(22),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Terms of Service', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('1. Use of Service', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                  const SizedBox(height: 4),
                  Text(
                    'Easy Manage is designed to help small businesses, merchants, and individuals track transactions, customer balances, and cash flow. You agree to use the application for lawful bookkeeping purposes only.',
                    style: GoogleFonts.inter(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  Text('2. Data Responsibility', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                  const SizedBox(height: 4),
                  Text(
                    'Easy Manage is an offline-first app. Users are responsible for taking periodic backups to Google Drive to ensure business continuity if devices are replaced or lost.',
                    style: GoogleFonts.inter(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  // Button: Open Full Online Terms
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.open_in_browser_rounded, color: Color(0xFF3B82F6), size: 20),
                    label: const Text(
                      'View Full Terms of Service (Web)',
                      style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    onPressed: () => _openExternalLink('https://usamahow001-ux.github.io/easy_manage/terms.html'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('I Agree to Terms'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 4. Data Deletion Confirmation
  void _showDeleteAccountConfirmation(BuildContext context, AppStateProvider provider) {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppTheme.debitRed, size: 24),
            SizedBox(width: 8),
            Expanded(child: Text('Reset Ledger Data?')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Warning: This action will permanently erase:\n• All customer and supplier ledgers\n• All transactions and cashbook history\n\nThis cannot be undone.',
              style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            Text(
              'Type RESET to confirm:',
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                hintText: 'RESET',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(provider.loc.tr('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.debitRed),
            onPressed: () async {
              if (confirmController.text.trim().toUpperCase() != 'RESET') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please type RESET to confirm')),
                );
                return;
              }
              Navigator.pop(ctx);
              await provider.deleteAccountPermanently();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All ledger data has been reset.'),
                    backgroundColor: AppTheme.debitRed,
                  ),
                );
              }
            },
            child: const Text('Confirm Reset'),
          ),
        ],
      ),
    );
  }

  void _showEditBusinessModal(BuildContext context, AppStateProvider provider) {
    final business = provider.businessProfile;
    final loc = provider.loc;
    final nameController = TextEditingController(text: business.businessName);
    final ownerController = TextEditingController(text: business.ownerName);
    final phoneController = TextEditingController(text: business.phone);
    final addressController = TextEditingController(text: business.address);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: provider.isDarkMode ? AppTheme.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              top: 14,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.tr('edit_business_profile'),
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: loc.tr('business_name'),
                    prefixIcon: const Icon(Icons.store_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ownerController,
                  decoration: InputDecoration(
                    labelText: loc.tr('owner_name'),
                    prefixIcon: const Icon(Icons.person_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: loc.tr('phone'),
                    prefixIcon: const Icon(Icons.phone_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: loc.tr('address'),
                    prefixIcon: const Icon(Icons.location_on_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      final updated = business.copyWith(
                        businessName: nameController.text.trim(),
                        ownerName: ownerController.text.trim(),
                        phone: phoneController.text.trim(),
                        address: addressController.text.trim(),
                      );
                      provider.updateBusinessProfile(updated);
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      loc.tr('save'),
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

  void _showLanguageDialog(BuildContext context, AppStateProvider provider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LanguageSelectionScreen(isFirstTime: false),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, AppStateProvider provider) {
    final currencies = [
      {'symbol': 'Rs.', 'code': 'PKR', 'name': 'Pakistani Rupee'},
      {'symbol': '\$', 'code': 'USD', 'name': 'US Dollar'},
      {'symbol': '£', 'code': 'GBP', 'name': 'British Pound'},
      {'symbol': '€', 'code': 'EUR', 'name': 'Euro'},
      {'symbol': 'AED', 'code': 'AED', 'name': 'UAE Dirham'},
      {'symbol': 'SAR', 'code': 'SAR', 'name': 'Saudi Riyal'},
      {'symbol': '₹', 'code': 'INR', 'name': 'Indian Rupee'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(provider.loc.tr('select_currency')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies.map((c) {
              final isCurrent = provider.businessProfile.currencyCode == c['code'];
              return ListTile(
                title: Text('${c['name']} (${c['code']})'),
                trailing: Text(
                  c['symbol']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isCurrent ? AppTheme.primaryGreen : null,
                  ),
                ),
                onTap: () {
                  final updated = provider.businessProfile.copyWith(
                    currencySymbol: c['symbol'],
                    currencyCode: c['code'],
                  );
                  provider.updateBusinessProfile(updated);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
