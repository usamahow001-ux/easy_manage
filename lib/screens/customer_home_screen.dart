import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import '../services/phone_helper.dart';
import '../theme/app_theme.dart';
import 'customer_ledger_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  String _search = '';
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      if (provider.customerPhoneNumber.isEmpty) {
        _promptForCustomerPhone(context, provider);
      } else {
        provider.refreshCustomerKhatas();
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _promptForCustomerPhone(BuildContext context, AppStateProvider provider) {
    _phoneController.text = provider.customerPhoneNumber;
    showDialog(
      context: context,
      barrierDismissible: provider.customerPhoneNumber.isNotEmpty,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.phone_android, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('Enter Your Phone Number'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your mobile number to view all Khatas and balances shared by your shopkeepers:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. 0300 1234567',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          if (provider.customerPhoneNumber.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final raw = _phoneController.text.trim();
              if (raw.isNotEmpty) {
                final normalized = PhoneHelper.normalize(raw);
                provider.setCustomerPhoneNumber(normalized);
                Navigator.pop(ctx);
              }
            },
            child: const Text('View My Khatas'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final khatas = provider.customerKhatas;

    final filtered = khatas.where((k) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return k.shopName.toLowerCase().contains(q) ||
          k.ownerName.toLowerCase().contains(q) ||
          k.shopPhone.contains(q);
    }).toList();

    double totalPayable = 0;
    double totalAdvance = 0;
    for (var k in khatas) {
      if (k.netBalance > 0) {
        totalPayable += k.netBalance;
      } else {
        totalAdvance += k.netBalance.abs();
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Khata Portal',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (provider.customerPhoneNumber.isNotEmpty)
              Text(
                'Phone: ${PhoneHelper.formatForDisplay(provider.customerPhoneNumber)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_iphone),
            tooltip: 'Change Phone Number',
            onPressed: () => _promptForCustomerPhone(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Khatas',
            onPressed: () => provider.refreshCustomerKhatas(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'switch_shop') {
                provider.setAppMode(AppMode.shopkeeper);
              } else if (val == 'change_phone') {
                _promptForCustomerPhone(context, provider);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'switch_shop',
                child: Row(
                  children: [
                    Icon(Icons.store, color: AppTheme.primaryGreen),
                    SizedBox(width: 8),
                    Text('Switch to Shopkeeper Mode'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'change_phone',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Change Phone Number'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshCustomerKhatas(),
        child: Column(
          children: [
            // Switcher banner & Live Date
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_pin_rounded, color: AppTheme.primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy').format(DateTime.now()),
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Toggle Privacy',
                        icon: Icon(
                          provider.isBalanceHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 18,
                          color: AppTheme.primaryGreen,
                        ),
                        onPressed: () => provider.toggleBalanceVisibility(),
                        visualDensity: VisualDensity.compact,
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        label: const Text('Shop Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => provider.setAppMode(AppMode.shopkeeper),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Overview Summary Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL YOU OWE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          provider.isBalanceHidden ? '••••••' : 'Rs. ${totalPayable.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.debitRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL ADVANCE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          provider.isBalanceHidden ? '••••••' : 'Rs. ${totalAdvance.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.creditGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search shops or owners...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) => setState(() => _search = val),
              ),
            ),

            const SizedBox(height: 12),

            // Shop List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.storefront_outlined,
                                size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'No Shop Khatas Found',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              provider.customerPhoneNumber.isEmpty
                                  ? 'Enter your phone number to find shared Khatas.'
                                  : 'No shop has added ${PhoneHelper.formatForDisplay(provider.customerPhoneNumber)} yet.\nAsk your shopkeeper to add this number in their Easy Manage app.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.phone),
                              label: const Text('Enter Different Number'),
                              onPressed: () => _promptForCustomerPhone(context, provider),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isOwed = item.netBalance > 0;
                        final isAdv = item.netBalance < 0;

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CustomerLedgerScreen(khata: item),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
                                  child: const Icon(
                                    Icons.storefront,
                                    color: AppTheme.primaryGreen,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.shopName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      if (item.ownerName.isNotEmpty)
                                        Text(
                                          'Owner: ${item.ownerName}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Updated ${DateFormat('dd MMM, hh:mm a').format(item.lastUpdated)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${item.currencySymbol} ${item.netBalance.abs().toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 17,
                                        color: isOwed
                                            ? AppTheme.debitRed
                                            : (isAdv
                                                ? AppTheme.creditGreen
                                                : Colors.grey),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isOwed ? 'You Owe' : (isAdv ? 'Advance' : 'Cleared'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isOwed
                                            ? AppTheme.debitRed
                                            : (isAdv
                                                ? AppTheme.creditGreen
                                                : Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
