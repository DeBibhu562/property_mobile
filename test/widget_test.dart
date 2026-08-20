import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:propertydilado_mobile/main.dart';

void main() {
  testWidgets('App boots to splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PropertyDilaDoApp()));
    await tester.pump();

    expect(find.text('PropertyDilaDo'), findsOneWidget);
  });
}
