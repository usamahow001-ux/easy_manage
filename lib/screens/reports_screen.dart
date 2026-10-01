import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/party.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../services/pdf_service.dart';
import 'party_detail_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final loc = provider.loc;
    final isDark = provider.isDarkMode;
    final currency = provider.businessProfile.currencySymbol;

    final receivable = provider.totalReceivable;
    final payable = provider.totalPayable;
    final cashIn = provider.totalCashIn;
    final cashOut = provider.totalCashOut;
    final partyBalances = provider.getAllPartyBalances();

    // Top Debtors (Customers owing money)
    final debtors = provider.parties.where((p) => p.type == PartyType.customer && (partyBalances[p.id] ?? 0) > 0).toList()
      ..sort((a, b) => (partyBalances[b.id] ?? 0).compareTo(partyBalances[a.id] ?? 0));

    // Top Creditors (Suppliers to pay)
    final creditors = provider.parties.where((p) => p.type == PartyType.supplier && (partyBalances[p.id] ?? 0) > 0).toList()
      ..sort((a, b) => (partyBalances[b.id] ?? 0).compareTo(partyBalances[a.id] ?? 0));

    final maxY = [cashIn, cashOut, receivable, payable, 1000.0].reduce((a, b) => a > b ? a : b) * 1.15;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.tr('reports'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business Overview Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFF0F766E), const Color(0xFF134E4A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : const Color(0xFF0F766E)).withValues(alpha: isDark ? 0.3 : 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          provider.businessProfile.businessName,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          loc.tr('financial_health'),
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.tr('total_receivable'), style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$currency ${receivable.toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(color: AppTheme.creditGreenLight, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.tr('total_payable'), style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$currency ${payable.toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(color: AppTheme.debitRedLight, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Financial Comparison Chart
            Text(
              loc.tr('cashflow_chart_title'),
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        maxY: maxY,
                        alignment: BarChartAlignment.spaceAround,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              String label = '';
                              switch (group.x) {
                                case 0:
                                  label = 'Cash In';
                                  break;
                                case 1:
                                  label = 'Cash Out';
                                  break;
                                case 2:
                                  label = 'Receivable';
                                  break;
                                case 3:
                                  label = 'Payable';
                                  break;
                              }
                              return BarTooltipItem(
                                '$label\n$currency ${rod.toY.toStringAsFixed(0)}',
                                GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                String text = '';
                                Color c = isDark ? Colors.white70 : Colors.black87;
                                switch (val.toInt()) {
                                  case 0:
                                    text = 'Cash In';
                                    c = AppTheme.creditGreen;
                                    break;
                                  case 1:
                                    text = 'Cash Out';
                                    c = AppTheme.debitRed;
                                    break;
                                  case 2:
                                    text = 'Receivable';
                                    c = AppTheme.primaryLight;
                                    break;
                                  case 3:
                                    text = 'Payable';
                                    c = AppTheme.accentGold;
                                    break;
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: c)),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: cashIn > 0 ? cashIn : 10,
                                color: AppTheme.creditGreen,
                                width: 22,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: cashOut > 0 ? cashOut : 10,
                                color: AppTheme.debitRed,
                                width: 22,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 2,
                            barRods: [
                              BarChartRodData(
                                toY: receivable > 0 ? receivable : 10,
                                color: AppTheme.primaryGreen,
                                width: 22,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 3,
                            barRods: [
                              BarChartRodData(
                                toY: payable > 0 ? payable : 10,
                                color: AppTheme.accentGold,
                                width: 22,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Report Actions Cards
            Text(
              'PDF Statement Downloads',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
            ),
            const SizedBox(height: 10),
            _buildReportActionCard(
              context: context,
              icon: Icons.menu_book_rounded,
              iconColor: AppTheme.primaryGreen,
              title: 'Complete Business Khata PDF',
              subtitle: 'Full list of all customers, suppliers, and ledger balances',
              onTap: () async {
                final pdfBytes = await PdfService.generateBusinessSummaryReport(
                  parties: provider.parties,
                  partyBalances: partyBalances,
                  business: provider.businessProfile,
                  totalReceivable: receivable,
                  totalPayable: payable,
                );
                await PdfService.printOrSharePdf(pdfData: pdfBytes, fileName: 'Business_Khata_Summary');
              },
            ),
            const SizedBox(height: 10),
            _buildReportActionCard(
              context: context,
              icon: Icons.account_balance_wallet_rounded,
              iconColor: const Color(0xFF3B82F6),
              title: 'Cashbook & Expenses PDF',
              subtitle: 'Itemized cash in/out register & expense breakdown',
              onTap: () async {
                final pdfBytes = await PdfService.generateCashbookReport(
                  entries: provider.cashEntries,
                  business: provider.businessProfile,
                  totalCashIn: provider.totalCashIn,
                  totalCashOut: provider.totalCashOut,
                );
                await PdfService.printOrSharePdf(pdfData: pdfBytes, fileName: 'Cashbook_Summary');
              },
            ),
            const SizedBox(height: 24),
            // Top Debtors
            Text(
              '${loc.tr('top_debtors')} (${debtors.length})',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
            ),
            const SizedBox(height: 8),
            if (debtors.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No pending customer balances! All clear.', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
              )
            else
              ...debtors.take(4).map((party) {
                final bal = partyBalances[party.id] ?? 0;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                      child: Text(
                        party.name.isNotEmpty ? party.name[0].toUpperCase() : '?',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                    ),
                    title: Text(party.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(party.phone.isNotEmpty ? party.phone : 'Customer', style: GoogleFonts.inter(fontSize: 12)),
                    trailing: Text(
                      '$currency ${bal.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.creditGreen),
                    ),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => PartyDetailScreen(partyId: party.id)));
                    },
                  ),
                );
              }),
            const SizedBox(height: 16),
            // Top Creditors
            Text(
              '${loc.tr('top_creditors')} (${creditors.length})',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
            ),
            const SizedBox(height: 8),
            if (creditors.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No payable supplier balances!', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
              )
            else
              ...creditors.take(4).map((party) {
                final bal = partyBalances[party.id] ?? 0;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.debitRed.withValues(alpha: 0.15),
                      child: Text(
                        party.name.isNotEmpty ? party.name[0].toUpperCase() : '?',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.debitRed),
                      ),
                    ),
                    title: Text(party.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(party.phone.isNotEmpty ? party.phone : 'Supplier', style: GoogleFonts.inter(fontSize: 12)),
                    trailing: Text(
                      '$currency ${bal.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.debitRed),
                    ),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => PartyDetailScreen(partyId: party.id)));
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildReportActionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
