import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/web_online.dart';

final connectivityServiceProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// `true` quando há alguma ligação de rede (wifi, mobile, ethernet).
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  if (kIsWeb) {
    var last = webNavigatorOnLine();
    yield last;
    await for (final _ in Stream.periodic(const Duration(seconds: 8))) {
      final next = webNavigatorOnLine();
      if (next != last) {
        last = next;
        yield next;
      }
    }
    return;
  }

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
