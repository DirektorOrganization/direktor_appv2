import 'package:flutter_test/flutter_test.dart';

import 'package:direktor_appv2/app/direktor_app.dart';

void main() {
  testWidgets('loads Direktor login flow', (tester) async {
    await tester.pumpWidget(const DirektorApp());
    await tester.pump(const Duration(milliseconds: 1400));

    expect(find.text('DIREKTOR'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
