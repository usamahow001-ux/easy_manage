enum DeletedItemType { party, transaction, cashEntry }

class DeletedItem {
  final String id;
  final DeletedItemType type;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime deletedAt;
  final Map<String, dynamic> rawData;

  DeletedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.deletedAt,
    required this.rawData,
  });

  int get daysRemaining {
    final expiry = deletedAt.add(const Duration(days: 30));
    final diff = expiry.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get isExpired => DateTime.now().difference(deletedAt).inDays >= 30;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'subtitle': subtitle,
        'amount': amount,
        'deletedAt': deletedAt.toIso8601String(),
        'rawData': rawData,
      };

  factory DeletedItem.fromJson(Map<String, dynamic> json) => DeletedItem(
        id: json['id'] as String,
        type: DeletedItemType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => DeletedItemType.transaction,
        ),
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        deletedAt: DateTime.parse(json['deletedAt'] as String),
        rawData: (json['rawData'] as Map<String, dynamic>?) ?? {},
      );
}
