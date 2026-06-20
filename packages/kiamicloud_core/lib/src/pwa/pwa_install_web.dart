import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:flutter/foundation.dart';

import 'pwa_install_state.dart';

abstract final class PwaInstallController {
  static PwaInstallState _state = _computeInitial();
  static void Function(PwaInstallState)? _listener;
  static void Function(html.Event)? _onAvailable;
  static void Function(html.Event)? _onInstalled;

  static PwaInstallState get initial => _state;

  static PwaInstallState _computeInitial() {
    final standalone = _isStandalone();
    final ios = _isIosSafari();
    final androidPrompt = _hasDeferredPrompt();
    return PwaInstallState(
      isStandalone: standalone,
      canInstallAndroid: !standalone && androidPrompt,
      showIosHint: !standalone && ios && !androidPrompt,
    );
  }

  static bool _isStandalone() {
    try {
      if (html.window.matchMedia('(display-mode: standalone)').matches) {
        return true;
      }
      final standalone = js_util.getProperty(html.window.navigator, 'standalone');
      return standalone == true;
    } catch (_) {
      return false;
    }
  }

  static bool _isIosSafari() {
    final ua = html.window.navigator.userAgent.toLowerCase();
    final isIosDevice =
        ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
    if (!isIosDevice) return false;
    return !ua.contains('crios') && !ua.contains('fxios');
  }

  static bool _hasDeferredPrompt() {
    return js_util.getProperty(html.window, 'kiamiDeferredInstallPrompt') != null;
  }

  static void _emit(PwaInstallState next) {
    _state = next;
    _listener?.call(next);
  }

  static void attach(void Function(PwaInstallState) onChanged) {
    _listener = onChanged;
    onChanged(_state);

    _onAvailable ??= (_) {
      _emit(
        _state.copyWith(
          canInstallAndroid: true,
          showIosHint: false,
        ),
      );
    };
    _onInstalled ??= (_) {
      _emit(
        _state.copyWith(
          isStandalone: true,
          canInstallAndroid: false,
          showIosHint: false,
        ),
      );
    };

    html.window.addEventListener('kiami-pwa-install-available', _onAvailable!);
    html.window.addEventListener('kiami-pwa-installed', _onInstalled!);
  }

  static void detach() {
    if (_onAvailable != null) {
      html.window.removeEventListener(
        'kiami-pwa-install-available',
        _onAvailable,
      );
    }
    if (_onInstalled != null) {
      html.window.removeEventListener('kiami-pwa-installed', _onInstalled);
    }
    _listener = null;
    _onAvailable = null;
    _onInstalled = null;
  }

  static Future<void> promptInstall() async {
    try {
      final outcome = await js_util.promiseToFuture<Object?>(
        js_util.callMethod(html.window, 'kiamiInstallPwa', []),
      );
      if ('$outcome' == 'accepted') {
        _emit(
          _state.copyWith(
            canInstallAndroid: false,
            isStandalone: true,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('PWA install prompt failed: $e\n$st');
    }
  }

  static void dismiss() {
    _emit(_state.copyWith(dismissed: true));
  }
}
