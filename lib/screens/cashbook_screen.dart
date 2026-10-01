import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/cash_entry.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../services/pdf_service.dart';

class CashbookScreen extends StatelessWidget {
  const CashbookScreen({super.key});

  static const List<Map<String, dynamic>> categoryData = [
    {'name': 'Sales', 'icon': Icons.point_of_sale_rounded, 'color': Color(0xFF10B981)},
    {'name': 'Purchases', 'icon': Icons.inventory_2_outlined, 'color': Color(0xFF3B82F6)},
    {'name': 'Shop Rent', 'icon': Icons.store_mall_directory_rounded, 'color': Color(0xFF8B5CF6)},
    {'name': 'Electricity / Bills', 'icon': Icons.bolt_rounded, 'color': Color(0xFFF59E0B)},
    {'name': 'Salaries', 'icon': Icons.badge_outlined, 'color': Color(0xFFEC4899)},
    {'name': 'Tea & Snacks', 'icon': Icons.local_cafe_outlined, 'color': Color(0xFFD97706)},
    {'name': 'Transport / Delivery', 'icon': Icons.local_shipping_outlined, 'color': Color(0xFF0D9488)},
    {'name': 'Other Expenses', 'icon': Icons.receipt_long_outlined, 'color': Color(0xFF64748B)},
  ];

  IconData _getCategoryIcon(String category) {
    final found = categoryData.firstWhere(
      (c) => (c['name'] as String).toLowerCase() == category.toLowerCase(),
      orElse: () => {'icon': Icons.receipt_outlined},
    );
    return found['icon'] as IconData;
  }

  Color _getCategoryColor(String category) {
    final found = categoryData.firstWhere(
      (c) => (c['name'] as String).toLowerCase() == category.toLowerCase(),
      orElse: () => {'color': AppTheme.primaryGreen},
    );
    return found['color'] as Color;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final loc = provider.loc;
    final isDark = provider.isDarkMode;
    final currency = provider.businessProfile.currencySymbol;

    final cashIn = provider.totalCashIn;
    final cashOut = provider.totalCashOut;
    final netCash = cashIn - cashOut;
    final entries = provider.getFilteredCashEntries();
    final dateFormat = DateFormat('dd MMM yyyy • hh:mm a');

    final totalVolume = cashIn + cashOut;
    final inRatio = totalVolume > 0 ? (cashIn / totalVolume) : 0.5;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.tr('cashbook'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryGreen),
            tooltip: 'Export Cashbook PDF',
            onPressed: () async {
              final pdfBytes = await PdfService.generateCashbookReport(
                entries: entries,
                business: provider.businessProfile,
                totalCashIn: cashIn,
                totalCashOut: cashOut,
              );
              await PdfService.printOrSharePdf(pdfData: pdfBytes, fileName: 'Cashbook_Report');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Time Period Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodChip(provider, loc.tr('period_all'), TimePeriod.all),
                  const SizedBox(width: 8),
                  _buildPeriodChip(provider, loc.tr('period_today'), TimePeriod.today),
                  const SizedBox(width: 8),
                  _buildPeriodChip(provider, loc.tr('period_this_week'), TimePeriod.thisWeek),
                  const SizedBox(width: 8),
                  _buildPeriodChip(provider, loc.tr('period_this_month'), TimePeriod.thisMonth),
                ],
              ),
            ),
          ),
          // Cash Summary Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        loc.tr('net_balance'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${netCash >= 0 ? "+" : "-"} $currency ${netCash.abs().toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: netCash >= 0 ? AppTheme.primaryGreen : AppTheme.debitRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Visual ratio progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (inRatio * 100).toInt().clamp(1, 99),
                          child: Container(color: AppTheme.creditGreen),
                        ),
                        Expanded(
                          flex: ((1 - inRatio) * 100).toInt().clamp(1, 99),
                          child: Container(color: AppTheme.debitRed),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.arrow_downward_rounded, size: 14, color: AppTheme.creditGreen),
                              const SizedBox(width: 4),
                              Text(loc.tr('total_cash_in'), style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '+ $currency ${cashIn.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.creditGreen),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.arrow_upward_rounded, size: 14, color: AppTheme.debitRed),
                              const SizedBox(width: 4),
                              Text(loc.tr('total_cash_out'), style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '- $currency ${cashOut.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.debitRed),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Entries Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${loc.tr('cashbook')} (${entries.length})',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                ),
              ],
            ),
          ),
          // Cash entries list
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, size: 56, color: Colors.grey.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text(
                            'No cash entries found for this period.',
                            style: GoogleFonts.inter(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap Cash In or Cash Out below to add an entry.',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 84),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final item = entries[index];
                      final isIn = item.type == CashType.cashIn;
                      final color = isIn ? AppTheme.creditGreen : AppTheme.debitRed;
                      final catIcon = _getCategoryIcon(item.category);
                      final catColor = _getCategoryColor(item.category);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                catIcon,
                                color: catColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item.category,
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isIn ? 'IN' : 'OUT',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item.note.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        item.note,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dateFormat.format(item.date),
                                    style: GoogleFonts.inter(fontSize: 10, color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isIn ? "+" : "-"} $currency ${item.amount.toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _confirmDeleteCashEntry(context, provider, item, currency),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(Icons.delete_outline_rounded, size: 16, color: isDark ? Colors.white38 : Colors.black38),
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
          // Bottom Dual Action Bar for Cash In vs Cash Out
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.creditGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        loc.tr('cash_in'),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    onPressed: () => _showAddCashModal(context, provider, CashType.cashIn),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.debitRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        loc.tr('cash_out'),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    onPressed: () => _showAddCashModal(context, provider, CashType.cashOut),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(AppStateProvider provider, String label, TimePeriod period) {
    final isSelected = provider.cashPeriod == period;
    final isDark = provider.isDarkMode;

    return ChoiceChip(
      label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) provider.setCashPeriod(period);
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

  void _confirmDeleteCashEntry(BuildContext context, AppStateProvider provider, CashEntry item, String currency) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Cash Entry?'),
        content: Text('Delete ${item.category} entry of $currency ${item.amount.toStringAsFixed(0)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.debitRed),
            onPressed: () {
              provider.deleteCashEntry(item.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddCashModal(BuildContext context, AppStateProvider provider, CashType type) {
    final loc = provider.loc;
    final currency = provider.businessProfile.currencySymbol;
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedCat = type == CashType.cashIn ? 'Sales' : 'Other Expenses';
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: provider.isDarkMode ? AppTheme.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isIn = type == CashType.cashIn;
            final primaryColor = isIn ? AppTheme.creditGreen : AppTheme.debitRed;

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isIn ? loc.tr('cash_in') : loc.tr('cash_out'),
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
                      decoration: InputDecoration(
                        prefixText: '$currency ',
                        prefixStyle: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: primaryColor),
                        hintText: '0',
                        hintStyle: GoogleFonts.outfit(fontSize: 28, color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Quick amount chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [500.0, 1000.0, 2000.0, 5000.0, 10000.0].map((val) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text('+$currency ${val.toInt()}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: primaryColor)),
                              backgroundColor: primaryColor.withValues(alpha: 0.1),
                              side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              onPressed: () {
                                final cur = double.tryParse(amountController.text) ?? 0;
                                amountController.text = (cur + val).toStringAsFixed(0);
                                setModalState(() {});
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      loc.tr('category'),
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    // Category Grid
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categoryData.map((c) {
                        final name = c['name'] as String;
                        final icon = c['icon'] as IconData;
                        final isSelected = selectedCat == name;

                        return ChoiceChip(
                          avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : primaryColor),
                          label: Text(name, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                          selected: isSelected,
                          selectedColor: primaryColor,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : (provider.isDarkMode ? Colors.white70 : Colors.black87)),
                          backgroundColor: provider.isDarkMode ? AppTheme.darkCardElevated : Colors.grey.shade100,
                          side: BorderSide(color: isSelected ? primaryColor : Colors.transparent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (sel) {
                            if (sel) setModalState(() => selectedCat = name);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        hintText: loc.tr('note'),
                        prefixIcon: const Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          final amount = double.tryParse(amountController.text) ?? 0;
                          if (amount <= 0) return;
                          provider.addCashEntry(
                            amount: amount,
                            type: type,
                            date: selectedDate,
                            category: selectedCat,
                            note: noteController.text.trim(),
                          );
                          Navigator.pop(ctx);
                        },
                        child: Text(loc.tr('save'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
