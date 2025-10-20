import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pim/main.dart';
import 'package:pim/view/appointment/firebase_api.dart';
import 'package:pim/view/body/firebase_historique_api.dart';
import 'package:pim/view/auth/firebase_auth_api.dart';

// Mocks
class MockFirebaseApi extends Mock implements FirebaseApi {}
class MockFirebaseHistoriqueApi extends Mock implements FirebaseHistoriqueApi {}
class MockFirebaseAuthApi extends Mock implements FirebaseAuthApi {}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    final mockFirebaseApi = MockFirebaseApi();
    final mockHistApi = MockFirebaseHistoriqueApi();
    final mockAuthApi = MockFirebaseAuthApi();

    await tester.pumpWidget(MyApp(
      firebaseApi: mockFirebaseApi,
      firebaseHistoriqueApi: mockHistApi,
      firebaseAuthApi: mockAuthApi,
    ));

    await tester.pumpAndSettle();

    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });
}
