import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiamicloud_core/src/assets/kiami_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> expectAsset(String path) async {
    final keys = [
      'packages/${KiamiAssets.package}/$path',
      path,
    ];

    var loaded = false;
    for (final key in keys) {
      try {
        final data = await rootBundle.load(key);
        expect(data.lengthInBytes, greaterThan(0));
        loaded = true;
        break;
      } catch (_) {}
    }

    expect(loaded, isTrue, reason: '$path not found in bundle');
  }

  test('Logo_barra_claro.png exists in asset bundle', () async {
    await expectAsset(KiamiAssets.logoBarLightPng);
  });

  test('Logo_barra_dark.png exists in asset bundle', () async {
    await expectAsset(KiamiAssets.logoBarDarkPng);
  });

  test('splashpage.png exists in asset bundle', () async {
    await expectAsset(KiamiAssets.splashpage);
  });

  test('icone.png exists in asset bundle', () async {
    await expectAsset(KiamiAssets.appIconPng);
  });
}
