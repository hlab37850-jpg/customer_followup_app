import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Customer creation', () {
    final customer = {'id': 1, 'name': 'Ali'};
    expect(customer['name'], 'Ali');
  });
}
