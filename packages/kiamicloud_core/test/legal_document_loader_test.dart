import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiamicloud_core/src/assets/kiami_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legal_documentation.pdf exists in asset bundle', () async {
    final key = KiamiAssets.legalDocumentBundlePath;
    final data = await rootBundle.load(key);
    expect(data.lengthInBytes, greaterThan(1000));

    final header = String.fromCharCodes(data.buffer.asUint8List().take(5));
    expect(header, startsWith('%PDF'));
  });
}
