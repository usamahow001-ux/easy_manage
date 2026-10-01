import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/party.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';

class AddPartyScreen extends StatefulWidget {
  final PartyType initialType;

  const AddPartyScreen({super.key, required this.initialType});

  @override
  State<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends State<AddPartyScreen> {
  late PartyType _type;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _openingBalController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  int _balanceType = 0; // 0 = Zero, 1 = I will get (Receivable), -1 = I will give (Payable)

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _openingBalController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final loc = provider.loc;
    final isDark = provider.isDarkMode;
    final currency = provider.businessProfile.currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _type == PartyType.customer ? loc.tr('add_customer') : loc.tr('add_supplier'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer / Supplier Type Switcher
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
                      onTap: () => setState(() => _type = PartyType.customer),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: _type == PartyType.customer ? AppTheme.primaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: _type == PartyType.customer
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            loc.tr('customers'),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _type == PartyType.customer ? Colors.white : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = PartyType.supplier),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: _type == PartyType.supplier ? AppTheme.primaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: _type == PartyType.supplier
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            loc.tr('suppliers'),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _type == PartyType.supplier ? Colors.white : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
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
            // Name
            Text(
              loc.tr('name'),
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Haji Rashid, Nadeem Traders',
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),
            // Phone
            Text(
              loc.tr('phone'),
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'e.g. 0300 1234567',
                prefixIcon: const Icon(Icons.phone_iphone_rounded),
              ),
            ),
            const SizedBox(height: 16),
            // Opening Balance Section
            Text(
              loc.tr('opening_balance'),
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _openingBalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixText: '$currency ',
                      hintText: '0',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                      borderRadius: BorderRadius.circular(14),
                      color: isDark ? AppTheme.darkCardElevated : Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _balanceType,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(value: 0, child: Text(loc.tr('zero_balance'), style: GoogleFonts.inter(fontSize: 12))),
                          DropdownMenuItem(value: 1, child: Text(loc.tr('i_will_get'), style: GoogleFonts.inter(fontSize: 12, color: AppTheme.creditGreen, fontWeight: FontWeight.w600))),
                          DropdownMenuItem(value: -1, child: Text(loc.tr('i_will_give'), style: GoogleFonts.inter(fontSize: 12, color: AppTheme.debitRed, fontWeight: FontWeight.w600))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _balanceType = val);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Address
            Text(
              loc.tr('address'),
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'Shop / Street / City address',
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),
            // Notes
            Text(
              loc.tr('note'),
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Additional remarks...',
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 32),
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter party name')),
                    );
                    return;
                  }

                  final rawBal = double.tryParse(_openingBalController.text) ?? 0;
                  final openingBal = _balanceType == 0 ? 0.0 : (rawBal * _balanceType);

                  provider.addParty(
                    name: name,
                    phone: _phoneController.text.trim(),
                    type: _type,
                    address: _addressController.text.trim(),
                    openingBalance: openingBal,
                    notes: _notesController.text.trim(),
                  );

                  Navigator.pop(context);
                },
                child: Text(
                  loc.tr('save'),
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
