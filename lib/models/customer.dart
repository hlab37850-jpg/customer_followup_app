class Customer {
  final int? id;
  final String name;
  final String phone;
  final String company;
  final String notes;
  final String createdAt;

  const Customer({
    this.id,
    required this.name,
    required this.phone,
    required this.company,
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'company': company,
        'notes': notes,
        'created_at': createdAt,
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'] as int?,
        name: map['name'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        company: map['company'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        createdAt: map['created_at'] as String? ?? '',
      );
}
