import 'package:flutter_test/flutter_test.dart';
import 'package:customer_followup_app/app.dart';

void main() {
  testWidgets('Application starts', (tester) async {
    await tester.pumpWidget(const CustomerFollowupApp());
    await tester.pump();

    expect(find.text('لوحة التحكم'), findsOneWidget);
    expect(find.text('متابعة العملاء'), findsOneWidget);
  });
}
