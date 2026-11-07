import 'package:flutter_test/flutter_test.dart';
import 'package:insta_lens_mobile/main.dart';

void main() {
  testWidgets('InstaLensApp launches and displays branding', (WidgetTester tester) async {
    await tester.pumpWidget(const InstaLensApp());
    expect(find.text('InstaLens'), findsOneWidget);
    expect(find.text('Extract Links & Summary'), findsOneWidget);
  });
}
