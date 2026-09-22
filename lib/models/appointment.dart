class Appointment {
  final int? id;
  final int customerId;
  final DateTime dateTime;
  final String description;

  const Appointment({
    this.id,
    required this.customerId,
    required this.dateTime,
    required this.description,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'customer_id': customerId,
        'date_time': dateTime.toIso8601String(),
        'description': description,
      };

  factory Appointment.fromMap(Map<String, dynamic> map) => Appointment(
        id: map['id'] as int?,
        customerId: map['customer_id'] as int,
        dateTime: DateTime.parse(map['date_time'] as String),
        description: map['description'] as String? ?? '',
      );
}
