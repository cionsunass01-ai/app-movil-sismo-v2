import 'package:flutter_test/flutter_test.dart';
import 'package:aguacion_app/main.dart';
import 'package:aguacion_app/presentation/screens/main_screen.dart';

void main() {
  testWidgets('AguaCION app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AguaCIONApp());
    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.text('SUNASS'), findsOneWidget);
    expect(find.text('Puntos'), findsOneWidget);
    expect(find.text('Mi Sector'), findsOneWidget);
    expect(find.text('Agua Segura'), findsOneWidget);
  });
}
