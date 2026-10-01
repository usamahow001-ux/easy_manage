import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/deleted_item.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  String _selectedFilter = 'all'; // all, party, transaction, cashEntry

  IconData _getTypeIcon(DeletedItemType type) {
    switch (type) {
      case DeletedItemType.party:
        return Icons.person_outline_rounded;
      case DeletedItemType.transaction:
        return Icons.receipt_long_outlined;
      case DeletedItemType.cashEntry:
        return Icons.account_balance_wallet_outlined;
    }
  }

  Color _getTypeColor(DeletedItemType type) {
    switch (type) {
      case DeletedItemType.party:
        return const Color(0xFF3B82F6);
      case DeletedItemType.transaction:
        return AppTheme.primaryGreen;
      case DeletedItemType.cashEntry:
        return AppTheme.accentGold;
    }
  }

  String _getTypeLabel(DeletedItemType type) {
    switch (type) {
      case DeletedItemType.party:
        return 'Contact';
      case DeletedItemType.transaction:
        return 'Transaction';
      case DeletedItemType.cashEntry:
        return 'Cash Entry';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final loc = provider.loc;
    final isDark = provider.isDarkMode;
    final currency = provider.businessProfile.currencySymbol;
    final allItems = provider.deletedItems;

    final filteredList = allItems.where((item) {
      if (_selectedFilter == 'party') return item.type == DeletedItemType.party;
      if (_selectedFilter == 'transaction') return item.type == DeletedItemType.transaction;
      if (_selectedFilter == 'cashEntry') return item.type == DeletedItemType.cashEntry;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.tr('recycle_bin'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          if (allItems.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.debitRed, size: 18),
              label: Text(
                loc.tr('empty_bin'),
                style: GoogleFonts.inter(color: AppTheme.debitRed, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _confirmEmptyBin(context, provider),
            ),
        ],
      ),
      body: Column(
        children: [
          // 30-Day Policy Alert Banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_delete_outlined, color: AppTheme.primaryGreen, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '30-Day Retention Policy',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loc.tr('auto_delete_notice'),
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
          ),
          // Filter Chips
          if (allItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All (${allItems.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('party', 'Contacts (${allItems.where((e) => e.type == DeletedItemType.party).length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('transaction', 'Transactions (${allItems.where((e) => e.type == DeletedItemType.transaction).length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('cashEntry', 'Cash Entries (${allItems.where((e) => e.type == DeletedItemType.cashEntry).length})'),
                  ],
                ),
              ),
            ),
          // Items List
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Padding(
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
                            child: const Icon(Icons.delete_outline_rounded, size: 56, color: AppTheme.primaryGreen),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Recycle Bin is Empty',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Deleted contacts, transactions, and cash entries will appear here for 30 days before permanent removal.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      final color = _getTypeColor(item.type);
                      final icon = _getTypeIcon(item.type);
                      final daysLeft = item.daysRemaining;
                      final isUrgent = daysLeft <= 3;
                      final dateFormat = DateFormat('dd MMM yyyy • hh:mm a');

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, color: color, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: GoogleFonts.outfit(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (isUrgent ? AppTheme.debitRed : AppTheme.primaryGreen).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '$daysLeft days left',
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isUrgent ? AppTheme.debitRed : AppTheme.primaryGreen,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_getTypeLabel(item.type)} • ${item.subtitle}',
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
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Deleted: ${dateFormat.format(item.deletedAt)}',
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                                ),
                                if (item.amount > 0)
                                  Text(
                                    '$currency ${item.amount.toStringAsFixed(0)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.restore_from_trash_rounded, size: 16, color: AppTheme.primaryGreen),
                                    label: Text(
                                      loc.tr('restore'),
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 13),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      side: const BorderSide(color: AppTheme.primaryGreen),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () async {
                                      await provider.restoreDeletedItem(item);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(loc.tr('item_restored')),
                                            backgroundColor: AppTheme.primaryGreen,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.delete_forever_rounded, size: 16, color: AppTheme.debitRed),
                                    label: Text(
                                      loc.tr('delete_permanently'),
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.debitRed, fontSize: 13),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      side: const BorderSide(color: AppTheme.debitRed),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _confirmPermanentDelete(context, provider, item),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label) {
    final isSelected = _selectedFilter == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = type);
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

  void _confirmPermanentDelete(BuildContext context, AppStateProvider provider, DeletedItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: Text('Are you sure you want to permanently delete "${item.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.debitRed),
            onPressed: () {
              provider.permanentlyDelete(item.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyBin(BuildContext context, AppStateProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Recycle Bin?'),
        content: const Text('All items in the Recycle Bin will be permanently removed immediately. This action cannot be reversed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.debitRed),
            onPressed: () {
              provider.emptyRecycleBin();
              Navigator.pop(ctx);
            },
            child: const Text('Empty Bin'),
          ),
        ],
      ),
    );
  }
}
