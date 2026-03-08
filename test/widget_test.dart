import 'package:flutter_test/flutter_test.dart';

import 'package:direktor_appv2/app/direktor_app.dart';

void main() {
  testWidgets('loads Direktor app shell', (tester) async {
    await tester.pumpWidget(const DirektorApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('DIREKTOR'), findsWidgets);
    expect(
      find.text('Ingresar').evaluate().isNotEmpty ||
          find.text('Resumen del proyecto').evaluate().isNotEmpty,
      isTrue,
    );
  });
}
