import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import 'splash_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isSettingPin = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _showAccountInfoDialog(BuildContext context, AppStateProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.info_outline_rounded, color: AppTheme.primaryGreen, size: 24),
            SizedBox(width: 8),
            Text('Account Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Phone Number', provider.userIdentifier.isNotEmpty ? provider.userIdentifier : 'Not registered'),
            const SizedBox(height: 10),
            _buildInfoRow('Business Name', provider.businessProfile.businessName),
            const SizedBox(height: 10),
            _buildInfoRow('Cloud Sync', 'Firebase Firestore (Active)'),
            const SizedBox(height: 10),
            _buildInfoRow('Security Status', provider.isAppLockEnabled ? 'PIN Protected' : 'Unlocked'),
            const SizedBox(height: 10),
            _buildInfoRow('App Version', 'Easy Manage v1.0.0'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _logout(BuildContext context, AppStateProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to log out of your account on this device?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.debitRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await provider.logoutUser();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context, AppStateProvider provider) async {
    final confirmController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppTheme.debitRed, size: 24),
            SizedBox(width: 8),
            Expanded(child: Text('Delete Account & Data?')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Warning: This action will permanently erase:\n• All customer and supplier ledgers\n• All transactions and cashbook history\n• Your cloud profile and settings\n\nThis action cannot be undone.',
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.debitRed),
            onPressed: () async {
              if (confirmController.text.trim() == 'RESET') {
                Navigator.pop(ctx);
                await provider.storageService.wipeAllAccountData();
                await provider.logoutUser();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SplashScreen()),
                    (route) => false,
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please type RESET exactly to confirm')),
                );
              }
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isDark = provider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Account',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 19),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Section 1: Multi-Device Cloud Sync
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cloud_sync_rounded, color: Color(0xFF0EA5E9), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Multi-Device Cloud Sync', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                          Text(
                            'Last: ${DateFormat('hh:mm a, dd MMM').format(provider.lastSyncTime)}',
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (provider.isSyncing)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Syncing with cloud...'), duration: Duration(milliseconds: 900)),
                          );
                          final ok = await provider.syncNow();
                          if (context.mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: ok ? AppTheme.primaryGreen : AppTheme.debitRed,
                                content: Text(ok ? 'Sync complete! All devices updated.' : 'Sync failed. Please check internet connection.'),
                              ),
                            );
                          }
                        },
                        child: const Text('Sync Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Your ledgers and transactions automatically sync to Firebase Cloud whenever you make changes.',
                  style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Section 2: Security & App Lock
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.creditGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.security_rounded, color: AppTheme.creditGreen, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Security & App Lock', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                          Text(
                            provider.isAppLockEnabled ? 'PIN & Biometric Lock Active' : 'Disabled',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: provider.isAppLockEnabled ? AppTheme.creditGreen : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: provider.isAppLockEnabled,
                      activeThumbColor: AppTheme.primaryGreen,
                      onChanged: (val) {
                        if (!val) {
                          provider.setAppLock(enabled: false, pin: '');
                          setState(() => _isSettingPin = false);
                        } else {
                          setState(() => _isSettingPin = true);
                        }
                      },
                    ),
                  ],
                ),
                if (_isSettingPin) ...[
                  const SizedBox(height: 14),
                  Text('Enter 4-Digit Security PIN', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: '4-digit PIN',
                            counterText: '',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          final pin = _pinController.text.trim();
                          if (pin.length == 4) {
                            provider.setAppLock(enabled: true, pin: pin);
                            setState(() => _isSettingPin = false);
                            _pinController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('App Lock enabled successfully!')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('PIN must be 4 digits')),
                            );
                          }
                        },
                        child: const Text('Save PIN'),
                      ),
                    ],
                  ),
                ],
                if (provider.isAppLockEnabled && provider.appLockPin.isNotEmpty) ...[
                  const Divider(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Biometric / Fingerprint Unlock', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Quick unlock using fingerprint or face', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    value: provider.isBiometricEnabled,
                    activeThumbColor: AppTheme.primaryGreen,
                    onChanged: (val) => provider.setBiometricEnabled(val),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Section 3: Account Information
          _buildCard(
            isDark: isDark,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6), size: 22),
              ),
              title: Text('Account Information', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Text(
                provider.userIdentifier.isNotEmpty ? 'Phone: ${provider.userIdentifier}' : 'Guest / Offline Mode',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              onTap: () => _showAccountInfoDialog(context, provider),
            ),
          ),
          const SizedBox(height: 14),

          // Section 4: Log Out
          _buildCard(
            isDark: isDark,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.debitRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout_rounded, color: AppTheme.debitRed, size: 22),
              ),
              title: Text('Log Out', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.debitRed)),
              subtitle: const Text('Sign out of your account on this device', style: TextStyle(fontSize: 12, color: Colors.grey)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.debitRed),
              onTap: () => _logout(context, provider),
            ),
          ),
          const SizedBox(height: 14),

          // Section 5: Delete My Account
          _buildCard(
            isDark: isDark,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_forever_rounded, color: Colors.grey, size: 22),
              ),
              title: Text('Delete My Account', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.grey)),
              subtitle: const Text('Permanently erase all ledgers, profile & data', style: TextStyle(fontSize: 12, color: Colors.grey)),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              onTap: () => _deleteAccount(context, provider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
