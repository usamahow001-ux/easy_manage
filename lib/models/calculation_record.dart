class CalculationRecord {
  final String expression;
  final String result;
  final DateTime time;

  CalculationRecord({
    required this.expression,
    required this.result,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
    'expression': expression,
    'result': result,
    'time': time.toIso8601String(),
  };

  factory CalculationRecord.fromJson(Map<String, dynamic> json) => CalculationRecord(
    expression: json['expression'] as String? ?? '',
    result: json['result'] as String? ?? '0',
    time: json['time'] != null
        ? DateTime.tryParse(json['time'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}
