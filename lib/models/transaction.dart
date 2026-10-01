enum TransactionType { youGave, youGot } // youGave = Maine Diye, youGot = Maine Liye
enum PaymentMode { cash, online, cheque }

class KhataTransaction {
  final String id;
  final String partyId;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String note;
  final String billNumber;
  final PaymentMode paymentMode;
  final String? imagePath;

  KhataTransaction({
    required this.id,
    required this.partyId,
    required this.amount,
    required this.type,
    required this.date,
    this.note = '',
    this.billNumber = '',
    this.paymentMode = PaymentMode.cash,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'partyId': partyId,
        'amount': amount,
        'type': type.name,
        'date': date.toIso8601String(),
        'note': note,
        'billNumber': billNumber,
        'paymentMode': paymentMode.name,
        'imagePath': imagePath,
      };

  factory KhataTransaction.fromJson(Map<String, dynamic> json) => KhataTransaction(
        id: json['id'] as String,
        partyId: json['partyId'] as String,
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        type: (json['type'] == 'youGot') ? TransactionType.youGot : TransactionType.youGave,
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
        note: json['note'] as String? ?? '',
        billNumber: json['billNumber'] as String? ?? '',
        paymentMode: PaymentMode.values.firstWhere(
          (m) => m.name == json['paymentMode'],
          orElse: () => PaymentMode.cash,
        ),
        imagePath: json['imagePath'] as String?,
      );

  KhataTransaction copyWith({
    String? id,
    String? partyId,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? note,
    String? billNumber,
    PaymentMode? paymentMode,
    String? imagePath,
  }) {
    return KhataTransaction(
      id: id ?? this.id,
      partyId: partyId ?? this.partyId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      note: note ?? this.note,
      billNumber: billNumber ?? this.billNumber,
      paymentMode: paymentMode ?? this.paymentMode,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
