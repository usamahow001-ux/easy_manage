enum CashType { cashIn, cashOut }

class CashEntry {
  final String id;
  final double amount;
  final CashType type;
  final DateTime date;
  final String category;
  final String note;
  final String paymentMode;

  CashEntry({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.category,
    this.note = '',
    this.paymentMode = 'Cash',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type.name,
        'date': date.toIso8601String(),
        'category': category,
        'note': note,
        'paymentMode': paymentMode,
      };

  factory CashEntry.fromJson(Map<String, dynamic> json) => CashEntry(
        id: json['id'] as String,
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        type: (json['type'] == 'cashOut') ? CashType.cashOut : CashType.cashIn,
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
        category: json['category'] as String? ?? 'General',
        note: json['note'] as String? ?? '',
        paymentMode: json['paymentMode'] as String? ?? 'Cash',
      );
}
