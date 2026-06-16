import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/kiami_file.dart';
import '../files/providers/files_providers.dart';

final trashFilesProvider = FutureProvider.autoDispose<List<KiamiFile>>((ref) async {
  return ref.watch(kiamiApiClientProvider).listTrashFiles();
});
