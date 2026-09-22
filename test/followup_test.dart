import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Follow-up creation', () {
    final followup = {'id': 1, 'status': 'pending'};
    expect(followup['status'], 'pending');
  });
}
