import 'package:flutter_test/flutter_test.dart';
import 'package:lakshya_residency/main.dart';

void main() {
  testWidgets('Onboarding screen renders app title and next button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LakshyaResidencyApp());
    expect(find.text('Lakshya Residency'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
