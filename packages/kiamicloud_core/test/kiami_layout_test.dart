import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiamicloud_core/src/constants/kiami_constants.dart';
import 'package:kiamicloud_core/src/utils/kiami_layout.dart';

Widget _wrap(Size size, Widget child) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('kiamiIsWideLayout', () {
    testWidgets('mobile Android 360px', (tester) async {
      await tester.pumpWidget(_wrap(const Size(360, 800), const SizedBox()));
      expect(kiamiIsWideLayout(tester.element(find.byType(SizedBox))), isFalse);
      expect(
        kiamiShowsShellBackButton(tester.element(find.byType(SizedBox))),
        isTrue,
      );
    });

    testWidgets('tablet web 800px', (tester) async {
      await tester.pumpWidget(_wrap(const Size(800, 600), const SizedBox()));
      expect(kiamiIsWideLayout(tester.element(find.byType(SizedBox))), isFalse);
    });

    testWidgets('desktop 1280px', (tester) async {
      await tester.pumpWidget(_wrap(const Size(1280, 900), const SizedBox()));
      expect(kiamiIsWideLayout(tester.element(find.byType(SizedBox))), isTrue);
      expect(
        kiamiShowsShellBackButton(tester.element(find.byType(SizedBox))),
        isFalse,
      );
    });
  });

  group('kiamiContentHorizontalPadding', () {
    testWidgets('reduz padding em ecrãs estreitos', (tester) async {
      await tester.pumpWidget(_wrap(const Size(320, 640), const SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      expect(kiamiContentHorizontalPadding(ctx), 12);
    });

    testWidgets('padding maior em desktop', (tester) async {
      await tester.pumpWidget(_wrap(const Size(1400, 900), const SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      expect(kiamiContentHorizontalPadding(ctx), 32);
    });
  });

  group('grid columns', () {
    test('categorias — mobile 2 colunas', () {
      expect(
        kiamiCategoryGridCrossAxisCount(390, nativeDesktop: false),
        2,
      );
    });

    test('categorias — web largo 4 colunas', () {
      expect(
        kiamiCategoryGridCrossAxisCount(1300, nativeDesktop: false),
        4,
      );
    });

    test('categorias — desktop nativo 3 colunas', () {
      expect(
        kiamiCategoryGridCrossAxisCount(
          KiamiConstants.breakpointTablet,
          nativeDesktop: true,
        ),
        3,
      );
    });

    test('ficheiros — usa largura útil', () {
      expect(kiamiFileGridCrossAxisCount(750), 2);
      expect(kiamiFileGridCrossAxisCount(900), 3);
      expect(kiamiFileGridCrossAxisCount(1250), 4);
    });
  });

  group('kiamiContentWidth', () {
    testWidgets('prefere constraints do pai', (tester) async {
      late BoxConstraints captured;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: MaterialApp(
            home: Scaffold(
              body: LayoutBuilder(
                builder: (context, constraints) {
                  captured = constraints;
                  expect(kiamiContentWidth(context, constraints), constraints.maxWidth);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      expect(captured.maxWidth, greaterThan(0));
    });
  });
}
