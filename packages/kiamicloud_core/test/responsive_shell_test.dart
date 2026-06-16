import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiamicloud_core/src/widgets/file_category_grid.dart';

Future<void> _setSize(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  group('FileCategoryGrid', () {
    testWidgets('sem overflow em mobile Android', (tester) async {
      await _setSize(tester, const Size(360, 800));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FileCategoryGrid(
                grouped: {},
                onCategoryTap: _noopCategory,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('sem overflow em web com sidebar simulada', (tester) async {
      await _setSize(tester, const Size(1280, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                const SizedBox(width: 268),
                Expanded(
                  child: SingleChildScrollView(
                    child: FileCategoryGrid(
                      grouped: const {},
                      onCategoryTap: _noopCategory,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('sem overflow em desktop estreito', (tester) async {
      await _setSize(tester, const Size(1024, 768));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FileCategoryGrid(
              grouped: {},
              onCategoryTap: _noopCategory,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}

void _noopCategory(_) {}
