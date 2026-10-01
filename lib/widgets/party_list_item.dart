import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/party.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../services/whatsapp_service.dart';

class PartyListItem extends StatelessWidget {
  final Party party;
  final VoidCallback onTap;

  const PartyListItem({
    super.key,
    required this.party,
    required this.onTap,
  });

  static const List<Color> avatarColors = [
    Color(0xFF0D9488),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF6366F1),
  ];

  String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 60) {
      return difference.inMinutes <= 1 ? 'Just now' : '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('dd MMM').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final balance = provider.getPartyBalance(party.id);
    final lastActive = provider.getPartyLastActivity(party.id);
    final currency = provider.businessProfile.currencySymbol;
    final loc = provider.loc;
    final isDark = provider.isDarkMode;

    final colorIndex = party.avatarColorIndex % avatarColors.length;
    final avatarColor = avatarColors[colorIndex];

    // Determine status & color
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

    String statusLabel = loc.tr('filter_cleared');
    if (isReceivable) {
      statusLabel = loc.tr('you_will_get');
    } else if (isPayable) {
      statusLabel = loc.tr('you_will_give');
    }

    final initials = party.name.isNotEmpty
        ? party.name.trim().split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join('').toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Avatar with gradient border
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [avatarColor.withValues(alpha: 0.8), avatarColor.withValues(alpha: 0.3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
                    child: Text(
                      initials,
                      style: GoogleFonts.outfit(
                        color: avatarColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Party Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              party.name,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lastActive != null)
                            Text(
                              _formatRelativeTime(lastActive),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (party.phone.isNotEmpty) ...[
                            Icon(
                              Icons.phone_iphone_rounded,
                              size: 13,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                party.phone,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              child: Text(
                                party.type == PartyType.customer ? loc.tr('customers') : loc.tr('suppliers'),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Balance & Status Pill
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currency ${balance.abs().toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (party.phone.isNotEmpty && isReceivable) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mark_chat_unread_rounded, color: Color(0xFF25D366), size: 16),
                    ),
                    tooltip: 'Send WhatsApp Reminder',
                    onPressed: () {
                      WhatsAppService.sendPaymentReminder(
                        party: party,
                        balance: balance,
                        business: provider.businessProfile,
                        template: loc.tr('whatsapp_msg_template'),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
