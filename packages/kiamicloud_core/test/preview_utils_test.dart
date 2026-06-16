import 'package:flutter_test/flutter_test.dart';
import 'package:kiamicloud_core/src/utils/pdf_preview.dart';
import 'package:kiamicloud_core/src/utils/text_preview.dart';

void main() {
  group('canPreviewTextFileName', () {
    test('accepts common text extensions', () {
      expect(canPreviewTextFileName('notes.txt'), isTrue);
      expect(canPreviewTextFileName('readme.md'), isTrue);
      expect(canPreviewTextFileName('data.json'), isTrue);
    });

    test('rejects binaries', () {
      expect(canPreviewTextFileName('photo.jpg'), isFalse);
      expect(canPreviewTextFileName('archive'), isFalse);
    });
  });

  group('canPreviewPdfFile', () {
    test('accepts pdf within limit', () {
      expect(canPreviewPdfFile('doc.pdf', 1024), isTrue);
    });

    test('rejects oversized pdf', () {
      expect(canPreviewPdfFile('big.pdf', kPdfPreviewMaxBytes + 1), isFalse);
    });
  });
}
