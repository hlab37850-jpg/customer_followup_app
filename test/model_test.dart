import 'package:flutter_test/flutter_test.dart';
import 'package:customer_followup_app/models/customer.dart';
import 'package:customer_followup_app/models/task.dart';

void main() {
  test('Customer map conversion works', () {
    final customer = Customer(
      id: 1,
      name: 'عميل',
      phone: '000',
      company: 'شركة',
      createdAt: DateTime(2026).toIso8601String(),
    );

    final copy = Customer.fromMap(customer.toMap());

    expect(copy.id, 1);
    expect(copy.name, 'عميل');
    expect(copy.phone, '000');
  });

  test('Task completed state is persisted in map', () {
    final task = const Task(
      id: 3,
      description: 'اختبار',
      completed: true,
    );

    final map = task.toMap();

    expect(map['completed'], 1);
  });
}
