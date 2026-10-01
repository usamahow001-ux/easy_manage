import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/party.dart';
import '../models/transaction.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';

class AddTransactionScreen extends StatefulWidget {
  final Party party;
  final TransactionType initialType;

  const AddTransactionScreen({
    super.key,
    required this.party,
    required this.initialType,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late TransactionType _type;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _billNoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  PaymentMode _paymentMode = PaymentMode.cash;

  static const List<String> presetNotes = [
    'Advance Payment',
    'Full Settlement',
    'Goods Delivery',
    'Monthly Bill',
    'Cash Deposit',
    'Bank Clearance',
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _billNoController.dispose();
    super.dispose();
  }

  void _addQuickAmount(double val) {
    final current = double.tryParse(_amountController.text) ?? 0;
    final updated = current + val;
    _amountController.text = updated.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final loc = provider.loc;
    final isDark = provider.isDarkMode;
    final currency = provider.businessProfile.currencySymbol;
    final isGave = _type == TransactionType.youGave;
    final primaryColor = isGave ? AppTheme.debitRed : AppTheme.creditGreen;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isGave ? loc.tr('you_gave') : loc.tr('you_got'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: primaryColor),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'For: ${widget.party.name}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Switcher Tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardElevated : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = TransactionType.youGave),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: isGave ? AppTheme.debitRed : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: isGave
                              ? [
                                  BoxShadow(
                                    color: AppTheme.debitRed.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            loc.tr('you_gave'),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isGave ? Colors.white : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = TransactionType.youGot),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: !isGave ? AppTheme.creditGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: !isGave
                              ? [
                                  BoxShadow(
                                    color: AppTheme.creditGreen.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            loc.tr('you_got'),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: !isGave ? Colors.white : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Big Amount Input
            Text(
              loc.tr('amount'),
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: GoogleFonts.outfit(fontSize: 30, fontWeight: FontWeight.bold, color: primaryColor),
              decoration: InputDecoration(
                prefixText: '$currency ',
                prefixStyle: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
                hintText: '0',
                hintStyle: GoogleFonts.outfit(fontSize: 30, color: Colors.grey.withValues(alpha: 0.3)),
              ),
            ),
            const SizedBox(height: 10),
            // Quick Amount Add Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickAddChip(500, currency),
                  const SizedBox(width: 8),
                  _buildQuickAddChip(1000, currency),
                  const SizedBox(width: 8),
                  _buildQuickAddChip(2000, currency),
                  const SizedBox(width: 8),
                  _buildQuickAddChip(5000, currency),
                  const SizedBox(width: 8),
                  _buildQuickAddChip(10000, currency),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Note / Description
            Text(
              loc.tr('note'),
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'e.g. 5 bags Sugar, Oil carton, Cash deposit...',
                prefixIcon: const Icon(Icons.edit_note_rounded),
              ),
            ),
            const SizedBox(height: 8),
            // Quick Note Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: presetNotes.map((preset) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(preset, style: GoogleFonts.inter(fontSize: 11)),
                      backgroundColor: isDark ? AppTheme.darkCardElevated : Colors.grey.shade100,
                      side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onPressed: () {
                        if (_noteController.text.isEmpty) {
                          _noteController.text = preset;
                        } else {
                          _noteController.text = '${_noteController.text}, $preset';
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            // Bill / Invoice No
            Text(
              loc.tr('bill_no'),
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _billNoController,
              decoration: InputDecoration(
                hintText: 'e.g. INV-2026, REC-104',
                prefixIcon: const Icon(Icons.receipt_outlined),
              ),
            ),
            const SizedBox(height: 16),
            // Payment Mode & Date Row
            Row(
              children: [
                // Date Picker
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.tr('date'),
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                            borderRadius: BorderRadius.circular(14),
                            color: isDark ? AppTheme.darkCardElevated : Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.primaryGreen),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  DateFormat('dd MMM yyyy').format(_selectedDate),
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Payment Mode
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.tr('payment_mode'),
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                          borderRadius: BorderRadius.circular(14),
                          color: isDark ? AppTheme.darkCardElevated : Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<PaymentMode>(
                            value: _paymentMode,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(
                                value: PaymentMode.cash,
                                child: Row(
                                  children: [
                                    const Icon(Icons.money_rounded, size: 16, color: AppTheme.primaryGreen),
                                    const SizedBox(width: 6),
                                    Text(loc.tr('cash'), style: GoogleFonts.inter(fontSize: 13)),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: PaymentMode.online,
                                child: Row(
                                  children: [
                                    const Icon(Icons.account_balance_rounded, size: 16, color: Color(0xFF3B82F6)),
                                    const SizedBox(width: 6),
                                    Text(loc.tr('bank_transfer'), style: GoogleFonts.inter(fontSize: 13)),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: PaymentMode.cheque,
                                child: Row(
                                  children: [
                                    const Icon(Icons.fact_check_outlined, size: 16, color: Color(0xFF8B5CF6)),
                                    const SizedBox(width: 6),
                                    Text(loc.tr('cheque'), style: GoogleFonts.inter(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _paymentMode = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: () {
                  final amount = double.tryParse(_amountController.text) ?? 0;
                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid amount')),
                    );
                    return;
                  }

                  provider.addTransaction(
                    partyId: widget.party.id,
                    amount: amount,
                    type: _type,
                    date: _selectedDate,
                    note: _noteController.text.trim(),
                    billNumber: _billNoController.text.trim(),
                    paymentMode: _paymentMode,
                  );

                  Navigator.pop(context);
                },
                child: Text(
                  loc.tr('save_transaction'),
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddChip(double amount, String currency) {
    return ActionChip(
      label: Text(
        '+$currency ${amount.toStringAsFixed(0)}',
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen),
      ),
      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
      side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () => _addQuickAmount(amount),
    );
  }
}
