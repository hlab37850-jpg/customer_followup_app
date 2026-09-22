class Customer {
  final int? id;
  final String name;
  final String phone;
  final String company;

  Customer({this.id, required this.name, required this.phone, required this.company});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'company': company,
  };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
    id: map['id'],
    name: map['name'],
    phone: map['phone'],
    company: map['company'],
  );
}
