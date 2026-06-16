import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiamicloud_core/src/utils/upload_file_reader.dart';

void main() {
  test('rejects file larger than per-file limit', () async {
    final file = PlatformFile(
      name: 'big.bin',
      size: 200,
      bytes: Uint8List.fromList(List.filled(200, 0)),
    );

    final outcome = await readPlatformFileForUpload(
      file: file,
      maxFileBytes: 100,
      storageAvailableBytes: 1000,
    );

    expect(outcome, isA<UploadFileRejected>());
    final rejected = outcome as UploadFileRejected;
    expect(rejected.reason, UploadFileRejectReason.tooLargePerFile);
  });

  test('rejects file larger than available quota', () async {
    final file = PlatformFile(
      name: 'medium.bin',
      size: 80,
      bytes: Uint8List.fromList(List.filled(80, 0)),
    );

    final outcome = await readPlatformFileForUpload(
      file: file,
      maxFileBytes: 100,
      storageAvailableBytes: 50,
    );

    expect(outcome, isA<UploadFileRejected>());
    expect(
      (outcome as UploadFileRejected).reason,
      UploadFileRejectReason.exceedsQuota,
    );
  });
}
