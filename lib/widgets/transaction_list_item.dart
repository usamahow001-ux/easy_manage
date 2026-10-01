import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

class TransactionListItem extends StatelessWidget {
  final KhataTransaction transaction;
  final String currency;
  final bool isDarkMode;
  final VoidCallback onDelete;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.currency,
    required this.isDarkMode,
    required this.onDelete,
  });

  IconData _getPaymentIcon(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return Icons.money_rounded;
      case PaymentMode.online:
        return Icons.account_balance_rounded;
      case PaymentMode.cheque:
        return Icons.fact_check_outlined;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: Text(
          'Delete transaction of $currency ${transaction.amount.toStringAsFixed(0)}? This will recalculate the contact balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.debitRed),
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGave = transaction.type == TransactionType.youGave;
    final color = isGave ? AppTheme.debitRed : AppTheme.creditGreen;
    final dateFormat = DateFormat('dd MMM yyyy • hh:mm a');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDarkMode ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGave ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isGave ? 'Maine Diye (Gave)' : 'Maine Liye (Got)',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                    if (transaction.billNumber.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#${transaction.billNumber}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (transaction.note.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    transaction.note,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDarkMode ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      dateFormat.format(transaction.date),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDarkMode ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getPaymentIcon(transaction.paymentMode), size: 10, color: AppTheme.primaryGreen),
                          const SizedBox(width: 3),
                          Text(
                            transaction.paymentMode.name.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
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
          const SizedBox(width: 8),
          // Amount & Delete Button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isGave ? "-" : "+"} $currency ${transaction.amount.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _showDeleteConfirmation(context),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: isDarkMode ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
