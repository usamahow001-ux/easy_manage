import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import 'business_profile_screen.dart';
import 'account_settings_screen.dart';
import 'recycle_bin_screen.dart';
import 'language_selection_screen.dart';

class SettingsSearchScreen extends StatefulWidget {
  const SettingsSearchScreen({super.key});

  @override
  State<SettingsSearchScreen> createState() => _SettingsSearchScreenState();
}

class _SettingsSearchItem {
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final Color color;
  final List<String> keywords;
  final void Function(BuildContext context, AppStateProvider provider) onTap;

  const _SettingsSearchItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.color,
    required this.keywords,
    required this.onTap,
  });
}

class _SettingsSearchScreenState extends State<SettingsSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  List<_SettingsSearchItem> _getAllItems() {
    return [
      _SettingsSearchItem(
        title: 'Account Settings',
        subtitle: 'Security, cloud sync, account info, log out, delete account',
        category: 'Account',
        icon: Icons.key_rounded,
        color: AppTheme.primaryGreen,
        keywords: ['account', 'profile', 'logout', 'signout', 'delete', 'security', 'info'],
        onTap: (ctx, _) {
          Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AccountSettingsScreen()));
        },
      ),
      _SettingsSearchItem(
        title: 'Security & App Lock',
        subtitle: 'PIN code and biometric fingerprint security',
        category: 'Account › Security',
        icon: Icons.security_rounded,
        color: AppTheme.creditGreen,
        keywords: ['security', 'pin', 'lock', 'app lock', 'fingerprint', 'biometric', 'password'],
        onTap: (ctx, _) {
          Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AccountSettingsScreen()));
        },
      ),
      _SettingsSearchItem(
        title: 'Multi-Device Cloud Sync',
        subtitle: 'Synchronize entries with Firebase Cloud across devices',
        category: 'Account › Cloud',
        icon: Icons.cloud_sync_rounded,
        color: const Color(0xFF0EA5E9),
        keywords: ['sync', 'cloud', 'backup', 'restore', 'online', 'firebase', 'multidevice', 'device'],
        onTap: (ctx, _) {
          Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AccountSettingsScreen()));
        },
      ),
      _SettingsSearchItem(
        title: 'Account Information',
        subtitle: 'View registered mobile number and cloud status',
        category: 'Account › Info',
        icon: Icons.info_outline_rounded,
        color: const Color(0xFF3B82F6),
        keywords: ['info', 'account info', 'mobile', 'phone', 'version', 'number'],
        onTap: (ctx, _) {
          Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AccountSettingsScreen()));
        },
      ),
      _SettingsSearchItem(
        title: 'Edit Business Profile',
        subtitle: 'Change business name, owner name, phone & address',
        category: 'Profile',
        icon: Icons.storefront_rounded,
        color: const Color(0xFFF59E0B),
        keywords: ['business', 'profile', 'name', 'store', 'shop', 'owner', 'address', 'edit'],
        onTap: (ctx, _) {
          Navigator.push(ctx, MaterialPageRoute(builder: (_) => const BusinessProfileScreen()));
        },
      ),
      _SettingsSearchItem(
        title: 'Deleted Items',
        subtitle: 'Restore deleted transactions and entries (30-day retention)',
        category: 'Data',
        icon: Icons.delete_outline_rounded,
        color: AppTheme.debitRed,
        keywords: ['deleted items', 'recycle', 'bin', 'trash', 'delete', 'deleted', 'restore', 'undo'],
        onTap: (ctx, _) {
          Navigator.push(ctx, MaterialPageRoute(builder: (_) => const RecycleBinScreen()));
        },
      ),
      _SettingsSearchItem(
        title: 'App Language',
        subtitle: 'English, اردو (Urdu), or Hinglish (Maine Dena Hai)',
        category: 'Preferences',
        icon: Icons.language_rounded,
        color: const Color(0xFF6366F1),
        keywords: ['language', 'urdu', 'english', 'hinglish', 'zaban', 'translate'],
        onTap: (ctx, _) {
          Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => const LanguageSelectionScreen(isFirstTime: false)),
          );
        },
      ),
      _SettingsSearchItem(
        title: 'Privacy Policy',
        subtitle: 'Read our data protection & privacy guidelines',
        category: 'Legal',
        icon: Icons.shield_outlined,
        color: const Color(0xFF10B981),
        keywords: ['privacy policy', 'policy', 'legal', 'security guidelines', 'privacy'],
        onTap: (ctx, _) {
          _showPrivacyPolicy(ctx);
        },
      ),
      _SettingsSearchItem(
        title: 'Terms of Service',
        subtitle: 'Terms and conditions for using Easy Manage',
        category: 'Legal',
        icon: Icons.description_outlined,
        color: const Color(0xFF6366F1),
        keywords: ['terms', 'service', 'rules', 'legal', 'agreement', 'conditions'],
        onTap: (ctx, _) {
          _showTermsOfService(ctx);
        },
      ),
      _SettingsSearchItem(
        title: 'Invite a Friend',
        subtitle: 'Share Easy Manage download link with friends and merchants',
        category: 'General',
        icon: Icons.group_add_outlined,
        color: const Color(0xFF8B5CF6),
        keywords: ['invite', 'share', 'friend', 'download', 'link', 'refer'],
        onTap: (_, _) {
          _shareApp();
        },
      ),
      _SettingsSearchItem(
        title: 'Dark Mode / Light Mode',
        subtitle: 'Toggle dark appearance and sleek theme',
        category: 'Appearance',
        icon: Icons.dark_mode_outlined,
        color: const Color(0xFFEAB308),
        keywords: ['dark', 'mode', 'light', 'theme', 'color', 'night', 'appearance'],
        onTap: (_, provider) {
          provider.toggleDarkMode();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isDark = provider.isDarkMode;
    final allItems = _getAllItems();

    final filteredItems = _query.isEmpty
        ? allItems
        : allItems.where((item) {
            final matchTitle = item.title.toLowerCase().contains(_query);
            final matchSubtitle = item.subtitle.toLowerCase().contains(_query);
            final matchCategory = item.category.toLowerCase().contains(_query);
            final matchKeywords = item.keywords.any((k) => k.toLowerCase().contains(_query));
            return matchTitle || matchSubtitle || matchCategory || matchKeywords;
          }).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search settings...',
            hintStyle: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () {
                _searchController.clear();
              },
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _query.isEmpty
          ? _buildSuggestionsView(context, provider, isDark)
          : _buildSearchResultsView(context, provider, filteredItems, isDark),
    );
  }

  Widget _buildSuggestionsView(BuildContext context, AppStateProvider provider, bool isDark) {
    final allItems = _getAllItems();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        Text(
          'Top Suggestions',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickChip('Account', Icons.key_rounded, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountSettingsScreen()));
            }),
            _buildQuickChip('Business Profile', Icons.storefront_rounded, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessProfileScreen()));
            }),
            _buildQuickChip('Security & PIN', Icons.security_rounded, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountSettingsScreen()));
            }),
            _buildQuickChip('Deleted Items', Icons.delete_outline_rounded, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RecycleBinScreen()));
            }),
            _buildQuickChip('Language', Icons.language_rounded, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LanguageSelectionScreen(isFirstTime: false)),
              );
            }),
            _buildQuickChip('Privacy Policy', Icons.shield_outlined, () {
              _showPrivacyPolicy(context);
            }),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'All Settings',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        ...allItems.map((item) => _buildItemTile(context, provider, item, isDark)),
      ],
    );
  }

  Widget _buildQuickChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppTheme.primaryGreen),
      label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.08),
      side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: onTap,
    );
  }

  Widget _buildSearchResultsView(
    BuildContext context,
    AppStateProvider provider,
    List<_SettingsSearchItem> items,
    bool isDark,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                'No settings found',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'No results matching "$_query". Try searching for account, security, profile, or policy.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _buildItemTile(context, provider, items[i], isDark),
    );
  }

  Widget _buildItemTile(
    BuildContext context,
    AppStateProvider provider,
    _SettingsSearchItem item,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, color: item.color, size: 22),
        ),
        title: Text(
          item.title,
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.subtitle,
              style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              item.category,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: item.color),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
        onTap: () => item.onTap(context, provider),
      ),
    );
  }
}
