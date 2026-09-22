import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Appointment creation', () {
    final appointment = {'id': 1, 'title': 'Meeting'};
    expect(appointment['title'], 'Meeting');
  });
}
