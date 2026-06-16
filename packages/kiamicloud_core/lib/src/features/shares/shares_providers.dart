import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/kiami_file_share.dart';
import '../files/providers/files_providers.dart';

final fileSharesProvider =
    FutureProvider.autoDispose<List<KiamiFileShare>>((ref) async {
  final api = ref.watch(kiamiApiClientProvider);
  return api.listFileShares();
});
