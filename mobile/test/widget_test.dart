import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onele/main.dart';
import 'package:onele/widgets/common.dart';

void main() {
  testWidgets('affiche l\'écran de connexion au démarrage', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const OneleApp());
    await tester.pumpAndSettle();

    expect(find.text('Onélé'), findsOneWidget);
    expect(find.widgetWithText(PrimaryButton, 'Se connecter'), findsOneWidget);
  });
}
