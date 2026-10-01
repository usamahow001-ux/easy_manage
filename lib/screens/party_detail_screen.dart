import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/party.dart';
import '../models/transaction.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/transaction_list_item.dart';
import '../services/whatsapp_service.dart';
import '../services/pdf_service.dart';
import 'add_transaction_screen.dart';

class PartyDetailScreen extends StatefulWidget {
  final String partyId;

  const PartyDetailScreen({super.key, required this.partyId});

  @override
  State<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends State<PartyDetailScreen> {
  String _filterType = 'all'; // all, gave, got
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    if (txDate == today) return 'Today';
    if (txDate == yesterday) return 'Yesterday';
    return DateFormat('dd MMMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final loc = provider.loc;
    final isDark = provider.isDarkMode;
    final currency = provider.businessProfile.currencySymbol;

    final party = provider.parties.firstWhere(
      (p) => p.id == widget.partyId,
      orElse: () => Party(id: '', name: 'Not Found', phone: '', type: PartyType.customer, createdAt: DateTime.now()),
    );

    if (party.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Contact Details')),
        body: const Center(child: Text('Party not found')),
      );
    }

    final balance = provider.getPartyBalance(party.id);
    var transactions = provider.getTransactionsForParty(party.id);

    // Filter transactions
    if (_filterType == 'gave') {
      transactions = transactions.where((t) => t.type == TransactionType.youGave).toList();
    } else if (_filterType == 'got') {
      transactions = transactions.where((t) => t.type == TransactionType.youGot).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      transactions = transactions.where((t) {
        final matchesNote = t.note.toLowerCase().contains(query);
        final matchesBill = t.billNumber.toLowerCase().contains(query);
        final matchesAmount = t.amount.toString().contains(query);
        return matchesNote || matchesBill || matchesAmount;
      }).toList();
    }

    // Determine status
    bool isReceivable = false;
    bool isPayable = false;
    bool isSettled = balance.abs() < 0.01;

    if (!isSettled) {
      if (party.type == PartyType.customer) {
        isReceivable = balance > 0;
        isPayable = balance < 0;
      } else {
        isPayable = balance > 0;
        isReceivable = balance < 0;
      }
    }

    final Color statusColor = isSettled
        ? (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)
        : (isReceivable ? AppTheme.creditGreen : AppTheme.debitRed);

    String statusText = 'Account Settled (0)';
    if (isReceivable) {
      statusText = '${loc.tr('you_will_get')} : $currency ${balance.abs().toStringAsFixed(0)}';
    } else if (isPayable) {
      statusText = '${loc.tr('you_will_give')} : $currency ${balance.abs().toStringAsFixed(0)}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              party.name,
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (party.phone.isNotEmpty)
              Text(
                party.phone,
                style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              ),
          ],
        ),
        actions: [
          if (party.phone.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.call_rounded, color: AppTheme.primaryGreen),
              tooltip: loc.tr('call'),
              onPressed: () => WhatsAppService.makePhoneCall(party.phone),
            ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryGreen),
            tooltip: loc.tr('pdf_statement'),
            onPressed: () async {
              final pdfBytes = await PdfService.generatePartyStatement(
                party: party,
                transactions: provider.getTransactionsForParty(party.id),
                business: provider.businessProfile,
                runningBalance: balance,
              );
              await PdfService.printOrSharePdf(
                pdfData: pdfBytes,
                fileName: '${party.name.replaceAll(' ', '_')}_Statement',
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'delete') {
                _confirmDeleteParty(context, provider, party);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded, color: AppTheme.debitRed, size: 20),
                    const SizedBox(width: 8),
                    Text(loc.tr('delete'), style: const TextStyle(color: AppTheme.debitRed)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Balance Banner & Action Chips
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 1.5),
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
                    Text(
                      loc.tr('net_balance'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        party.type == PartyType.customer ? loc.tr('customers') : loc.tr('suppliers'),
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          statusText,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (party.address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          party.address,
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (party.phone.isNotEmpty) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.mark_chat_unread_rounded, color: Color(0xFF25D366), size: 16),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('WhatsApp', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : Colors.black87,
                            side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            WhatsAppService.sendPaymentReminder(
                              party: party,
                              balance: balance,
                              business: provider.businessProfile,
                              template: loc.tr('whatsapp_msg_template'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.sms_outlined, color: AppTheme.primaryGreen, size: 16),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('SMS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : Colors.black87,
                            side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            final msg = loc.tr('whatsapp_msg_template')
                                .replaceAll('{name}', party.name)
                                .replaceAll('{business}', provider.businessProfile.businessName)
                                .replaceAll('{currency}', currency)
                                .replaceAll('{balance}', balance.abs().toStringAsFixed(0));
                            WhatsAppService.sendSms(phone: party.phone, message: msg);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share_outlined, color: AppTheme.primaryGreen, size: 16),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('PDF Report', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                          side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final pdfBytes = await PdfService.generatePartyStatement(
                            party: party,
                            transactions: provider.getTransactionsForParty(party.id),
                            business: provider.businessProfile,
                            runningBalance: balance,
                          );
                          await PdfService.printOrSharePdf(
                            pdfData: pdfBytes,
                            fileName: '${party.name.replaceAll(' ', '_')}_Khata',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Filter Tabs (All, Gave, Got)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildTypeChip('all', 'All (${provider.getTransactionsForParty(party.id).length})'),
                const SizedBox(width: 8),
                _buildTypeChip('gave', 'Gave (-)'),
                const SizedBox(width: 8),
                _buildTypeChip('got', 'Got (+)'),
              ],
            ),
          ),
          // Transactions List
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.withValues(alpha: 0.4)),
                          const SizedBox(height: 8),
                          Text(
                            loc.tr('no_transactions'),
                            style: GoogleFonts.inter(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Use the buttons below to record your first entry.',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final showDateHeader = index == 0 ||
                          _getDateHeader(transactions[index - 1].date) != _getDateHeader(tx.date);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDateHeader)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
                              child: Text(
                                _getDateHeader(tx.date),
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ),
                          TransactionListItem(
                            transaction: tx,
                            currency: currency,
                            isDarkMode: isDark,
                            onDelete: () => provider.deleteTransaction(tx.id),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          // Bottom Dual Action Bar (YOU GAVE vs YOU GOT)
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
                // YOU GAVE (Maine Diye) - Red Button
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.debitRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        loc.tr('you_gave'),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddTransactionScreen(
                            party: party,
                            initialType: TransactionType.youGave,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // YOU GOT (Maine Liye) - Green Button
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.creditGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        loc.tr('you_got'),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddTransactionScreen(
                            party: party,
                            initialType: TransactionType.youGot,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final isSelected = _filterType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _filterType = type);
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

  void _confirmDeleteParty(BuildContext context, AppStateProvider provider, Party party) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${party.name}?'),
        content: const Text('All transactions associated with this contact will also be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.debitRed),
            onPressed: () {
              provider.deleteParty(party.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
