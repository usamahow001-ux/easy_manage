import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import '../models/customer_shop_khata.dart';
import '../models/transaction.dart';
import '../models/party.dart';
import '../models/business_profile.dart';
import '../providers/app_state_provider.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';

class CustomerLedgerScreen extends StatefulWidget {
  final CustomerShopKhata khata;

  const CustomerLedgerScreen({
    super.key,
    required this.khata,
  });

  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  String _searchQuery = '';
  String _filterType = 'all'; // all, debit, credit
  bool _isExporting = false;

  List<KhataTransaction> get _filteredTransactions {
    return widget.khata.transactions.where((tx) {
      if (_filterType == 'debit' && tx.type != TransactionType.youGave) return false;
      if (_filterType == 'credit' && tx.type != TransactionType.youGot) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchNote = tx.note.toLowerCase().contains(q);
        final matchBill = tx.billNumber.toLowerCase().contains(q);
        final matchAmount = tx.amount.toString().contains(q);
        return matchNote || matchBill || matchAmount;
      }
      return true;
    }).toList();
  }

  Future<void> _makeCall(String phone) async {
    if (phone.isEmpty) return;
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    if (phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    final url = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _downloadPdfStatement() async {
    setState(() => _isExporting = true);
    try {
      final dummyParty = Party(
        id: 'cust_view',
        name: 'Customer Account',
        phone: widget.khata.shopPhone,
        type: PartyType.customer,
        createdAt: DateTime.now(),
        openingBalance: 0.0,
      );

      final dummyBiz = BusinessProfile(
        id: widget.khata.shopId,
        businessName: widget.khata.shopName,
        ownerName: widget.khata.ownerName,
        phone: widget.khata.shopPhone,
        address: widget.khata.shopAddress,
        currencySymbol: widget.khata.currencySymbol,
      );

      final pdfBytes = await PdfService.generatePartyStatement(
        party: dummyParty,
        transactions: widget.khata.transactions,
        business: dummyBiz,
        runningBalance: widget.khata.netBalance,
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '${widget.khata.shopName.replaceAll(' ', '_')}_Khata_Statement.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHidden = provider.isBalanceHidden;
    final cur = widget.khata.currencySymbol;
    final balance = widget.khata.netBalance;
    final isOwed = balance > 0;
    final isAdvance = balance < 0;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.khata.shopName,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (widget.khata.ownerName.isNotEmpty)
              Text(
                'Owner: ${widget.khata.ownerName}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
          ],
        ),
        actions: [
          if (widget.khata.shopPhone.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.phone, color: AppTheme.primaryGreen),
              tooltip: 'Call Shop',
              onPressed: () => _makeCall(widget.khata.shopPhone),
            ),
            IconButton(
              icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
              tooltip: 'WhatsApp Shop',
              onPressed: () => _openWhatsApp(widget.khata.shopPhone),
            ),
          ],
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            tooltip: 'Download PDF Statement',
            onPressed: _isExporting ? null : _downloadPdfStatement,
          ),
        ],
      ),
      body: Column(
        children: [
          // Balance Banner Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isOwed
                    ? [AppTheme.debitRedDark, AppTheme.debitRed]
                    : (isAdvance
                        ? [AppTheme.creditGreenDark, AppTheme.creditGreen]
                        : [AppTheme.primaryDark, AppTheme.primaryGreen]),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: (isOwed ? Colors.red : Colors.teal).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isOwed
                          ? 'YOU OWE SHOP'
                          : (isAdvance ? 'YOUR ADVANCE BALANCE' : 'KHATA CLEARED'),
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Read-Only',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  isHidden ? '••••••••' : '$cur ${balance.abs().toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Last updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(widget.khata.lastUpdated)}',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Search & Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search items or bill #',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCardElevated : AppTheme.lightCardElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.filter_list, size: 22),
                  ),
                  onSelected: (val) => setState(() => _filterType = val),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'all', child: Text('All Transactions')),
                    const PopupMenuItem(value: 'debit', child: Text('Purchases / Udhaar')),
                    const PopupMenuItem(value: 'credit', child: Text('Payments / Vasooli')),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Transactions List
          Expanded(
            child: _filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No transactions found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredTransactions.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tx = _filteredTransactions[index];
                      final isGave = tx.type == TransactionType.youGave;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isGave
                                    ? AppTheme.debitRed.withValues(alpha: 0.12)
                                    : AppTheme.creditGreen.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isGave ? Icons.arrow_upward : Icons.arrow_downward,
                                color: isGave ? AppTheme.debitRed : AppTheme.creditGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isGave ? 'Purchase (Udhaar)' : 'Payment Received',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                        ),
                                      ),
                                      Text(
                                        '$cur ${tx.amount.toStringAsFixed(0)}',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: isGave ? AppTheme.debitRed : AppTheme.creditGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (tx.note.isNotEmpty)
                                    Text(
                                      tx.note,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                      ),
                                    ),
                                  if (tx.billNumber.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'Bill #${tx.billNumber}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppTheme.accentBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('dd MMM yyyy, hh:mm a').format(tx.date),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                                        ),
                                      ),
                                      if (tx.imagePath != null && tx.imagePath!.isNotEmpty)
                                        GestureDetector(
                                          onTap: () => _showImagePreview(context, tx.imagePath!),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.attachment, size: 14, color: AppTheme.accentBlue),
                                              SizedBox(width: 2),
                                              Text(
                                                'View Bill',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.accentBlue,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
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

  void _showImagePreview(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Attached Bill/Receipt'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            Flexible(
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Image file not found on device'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
