import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiamicloud_core/kiamicloud_core.dart';

void main() {
  testWidgets('KiamiApp inicia com splash', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: KiamiApp(),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Minha Cloud'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2500));
  });
}
