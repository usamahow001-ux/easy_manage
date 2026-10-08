import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/party.dart';
import '../providers/app_state_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/quick_stats_bar.dart';
import '../widgets/party_list_item.dart';
import 'party_detail_screen.dart';
import 'add_party_screen.dart';
import 'cashbook_screen.dart';
import 'calculator_screen.dart';
import 'settings_screen.dart';
import 'language_selection_screen.dart';
import 'customer_ledger_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentNavIndex = 0;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final loc = provider.loc;
    final isDark = provider.isDarkMode;

    final screens = [
      _buildKhataView(provider, loc, isDark),
      const CashbookScreen(),
      const CalculatorScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_currentNavIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (index) {
          setState(() => _currentNavIndex = index);
        },
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        indicatorColor: AppTheme.primaryGreen.withValues(alpha: 0.18),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryGreen),
            label: loc.tr('customers'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryGreen),
            label: loc.tr('cashbook'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.calculate_outlined),
            selectedIcon: const Icon(Icons.calculate_rounded, color: AppTheme.primaryGreen),
            label: loc.tr('calculator'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded, color: AppTheme.primaryGreen),
            label: loc.tr('more'),
          ),
        ],
      ),
      floatingActionButton: _currentNavIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.person_add_rounded),
              label: Text(
                _tabController.index == 0 ? loc.tr('add_customer') : loc.tr('add_supplier'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                final targetType = _tabController.index == 0 ? PartyType.customer : PartyType.supplier;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AddPartyScreen(initialType: targetType)),
                );
              },
            )
          : null,
    );
  }

  Widget _buildKhataView(AppStateProvider provider, dynamic loc, bool isDark) {
    final customerCount = provider.parties.where((p) => p.type == PartyType.customer).length;
    final supplierCount = provider.parties.where((p) => p.type == PartyType.supplier).length;

    return SafeArea(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Top App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Business Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            provider.businessProfile.businessName.isNotEmpty &&
                                    provider.businessProfile.businessName != 'My Business'
                                ? provider.businessProfile.businessName
                                : 'Easy Manage',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            provider.businessProfile.ownerName.isNotEmpty
                                ? provider.businessProfile.ownerName
                                : (provider.businessProfile.phone.isNotEmpty
                                    ? provider.businessProfile.phone
                                    : 'Digital Khata & Ledger'),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Notification Bell for Pending Khatas
                    if (provider.customerKhatas.isNotEmpty) ...[
                      IconButton(
                        tooltip: 'Pending Khatas (${provider.customerKhatas.length})',
                        icon: Badge(
                          label: Text(
                            '${provider.customerKhatas.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: AppTheme.debitRed,
                          child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFF59E0B)),
                        ),
                        onPressed: () => _showPendingKhatasModal(context, provider),
                      ),
                    ],
                    // Language Switcher Button
                    IconButton(
                      tooltip: loc.tr('select_language'),
                      icon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          provider.language == AppLanguage.urdu
                              ? 'اردو'
                              : (provider.language == AppLanguage.romanUrdu ? 'Hinglish' : 'EN'),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LanguageSelectionScreen(isFirstTime: false),
                          ),
                        );
                      },
                    ),
                    // Dark Mode Button
                    IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: isDark ? AppTheme.accentGold : AppTheme.lightTextSecondary,
                      ),
                      onPressed: () => provider.toggleDarkMode(),
                    ),
                  ],
                ),
              ),
            ),
            // Quick Stats Banner
            SliverToBoxAdapter(
              child: QuickStatsBar(
                onOpenCashbook: () {
                  setState(() => _currentNavIndex = 1);
                },
              ),
            ),
            // Pending Khata Notification Banner (When other shops have added this user)
            if (provider.customerKhatas.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: InkWell(
                    onTap: () => _showPendingKhatasModal(context, provider),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Pending Khata Notification',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF92400E),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD97706),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${provider.customerKhatas.length} New',
                                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${provider.customerKhatas.first.shopName} added you. Tap to view your live balance & statements.',
                                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFB45309)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFF92400E)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // Search Bar & Filter Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => provider.setSearchQuery(val),
                            decoration: InputDecoration(
                              hintText: loc.tr('search_hint'),
                              prefixIcon: const Icon(Icons.search_rounded, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        provider.setSearchQuery('');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Sort Button
                        PopupMenuButton<PartySort>(
                          icon: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkCardElevated : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                            ),
                            child: const Icon(Icons.sort_rounded, size: 20, color: AppTheme.primaryGreen),
                          ),
                          tooltip: loc.tr('sort_by'),
                          onSelected: (sort) => provider.setPartySort(sort),
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: PartySort.recent,
                              child: Row(
                                children: [
                                  Icon(Icons.history_rounded, size: 18, color: provider.partySort == PartySort.recent ? AppTheme.primaryGreen : null),
                                  const SizedBox(width: 8),
                                  Text(loc.tr('sort_recent')),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: PartySort.name,
                              child: Row(
                                children: [
                                  Icon(Icons.sort_by_alpha_rounded, size: 18, color: provider.partySort == PartySort.name ? AppTheme.primaryGreen : null),
                                  const SizedBox(width: 8),
                                  Text(loc.tr('sort_name')),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: PartySort.balanceHigh,
                              child: Row(
                                children: [
                                  Icon(Icons.trending_up_rounded, size: 18, color: provider.partySort == PartySort.balanceHigh ? AppTheme.primaryGreen : null),
                                  const SizedBox(width: 8),
                                  Text(loc.tr('sort_balance_high')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Filter Chips (All / Pending / Settled)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            provider,
                            loc.tr('filter_all'),
                            PartyFilter.all,
                            _tabController.index == 0 ? customerCount : supplierCount,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            provider,
                            loc.tr('filter_pending'),
                            PartyFilter.pendingOnly,
                            provider.getPendingCount(_tabController.index == 0 ? PartyType.customer : PartyType.supplier),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            provider,
                            loc.tr('filter_cleared'),
                            PartyFilter.clearedOnly,
                            provider.getSettledCount(_tabController.index == 0 ? PartyType.customer : PartyType.supplier),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Customer & Supplier Tabs
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCardElevated : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    onTap: (index) => setState(() {}),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                    tabs: [
                      Tab(text: '${loc.tr('customers')} ($customerCount)'),
                      Tab(text: '${loc.tr('suppliers')} ($supplierCount)'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPartyList(provider, PartyType.customer, loc),
            _buildPartyList(provider, PartyType.supplier, loc),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(AppStateProvider provider, String label, PartyFilter filter, int count) {
    final isSelected = provider.partyFilter == filter;
    final isDark = provider.isDarkMode;

    return ChoiceChip(
      label: Text(
        '$label ($count)',
        style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) provider.setPartyFilter(filter);
      },
      selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryGreen : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryGreen : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildPartyList(AppStateProvider provider, PartyType type, dynamic loc) {
    final list = provider.getFilteredParties(type);

    if (list.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  type == PartyType.customer ? Icons.people_outline_rounded : Icons.local_shipping_outlined,
                  size: 56,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                loc.tr('no_parties_found'),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: provider.isDarkMode ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                loc.tr('add_first_party'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: provider.isDarkMode ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: Text(
                  type == PartyType.customer ? loc.tr('add_customer') : loc.tr('add_supplier'),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AddPartyScreen(initialType: type)),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 84),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final party = list[index];
        return PartyListItem(
          party: party,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PartyDetailScreen(partyId: party.id),
              ),
            );
          },
        );
      },
    );
  }

  void _showPendingKhatasModal(BuildContext context, AppStateProvider provider) {
    final isDark = provider.isDarkMode;
    final khatas = provider.customerKhatas;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFF59E0B), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pending Khatas from Shops',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                          Text(
                            '${khatas.length} shop(s) have registered active ledgers for your phone number',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (khatas.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No pending khatas at the moment.',
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: khatas.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final khata = khatas[index];
                        final isDebit = khata.netBalance > 0; // Customer owes money
                        return Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCardElevated : AppTheme.lightCardElevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                              child: const Icon(Icons.storefront_rounded, color: AppTheme.primaryGreen),
                            ),
                            title: Text(
                              khata.shopName.isNotEmpty ? khata.shopName : 'Shop Ledger',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            subtitle: Text(
                              khata.shopPhone.isNotEmpty ? khata.shopPhone : 'Live Shared Khata',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Rs ${khata.netBalance.abs().toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDebit ? AppTheme.debitRed : AppTheme.creditGreen,
                                  ),
                                ),
                                Text(
                                  isDebit ? 'You Owe (Dena Hai)' : 'You Advance (Lena Hai)',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDebit ? AppTheme.debitRed : AppTheme.creditGreen,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CustomerLedgerScreen(khata: khata),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
