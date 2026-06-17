import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/models/file_thumbnail_url.dart';
import 'files_providers.dart';

final fileThumbnailUrlProvider =
    FutureProvider.autoDispose.family<FileThumbnailUrl?, String>(
  (ref, fileId) async {
    final link = ref.keepAlive();
    final timer = Timer(const Duration(minutes: 10), link.close);
    ref.onDispose(timer.cancel);

    final api = ref.watch(kiamiApiClientProvider);
    return api.getFileThumbnailUrl(fileId);
  },
);
