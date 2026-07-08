import 'package:flutter_test/flutter_test.dart';

import 'package:cinmovies_app/main.dart';

void main() {
  testWidgets('App starts on splash route', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.pump();

    expect(find.text('Splash'), findsOneWidget);
  });
}
