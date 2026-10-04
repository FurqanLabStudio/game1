import 'package:flutter_test/flutter_test.dart';

import 'package:game1/main.dart';

void main() {
  testWidgets('Home screen shows both games', (tester) async {
    await tester.pumpWidget(const PartyApp());
    expect(find.text('Snakes'), findsOneWidget);
    expect(find.text('Paint Fight'), findsOneWidget);
  });
}
