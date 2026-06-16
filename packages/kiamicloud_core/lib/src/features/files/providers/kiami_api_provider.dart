import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/kiami_api_client.dart';

final kiamiApiClientProvider = Provider<KiamiApiClient>((ref) {
  return KiamiApiClient();
});
