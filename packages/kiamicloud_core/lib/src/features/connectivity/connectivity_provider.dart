import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityServiceProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// `true` quando há alguma ligação de rede (wifi, mobile, ethernet).
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = ref.watch(connectivityServiceProvider);

  Future<bool> check() async {
    final results = await connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  yield await check();

  await for (final results in connectivity.onConnectivityChanged) {
    yield results.any((r) => r != ConnectivityResult.none);
  }
});
