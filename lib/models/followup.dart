class Followup {
  final int? id;
  final int customerId;
  final String note;
  final DateTime date;
  final String status;

  const Followup({
    this.id,
    required this.customerId,
    required this.note,
    required this.date,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'customer_id': customerId,
        'note': note,
        'date': date.toIso8601String(),
        'status': status,
      };

  factory Followup.fromMap(Map<String, dynamic> map) => Followup(
        id: map['id'] as int?,
        customerId: map['customer_id'] as int,
        note: map['note'] as String? ?? '',
        date: DateTime.parse(map['date'] as String),
        status: map['status'] as String? ?? 'pending',
      );
}
