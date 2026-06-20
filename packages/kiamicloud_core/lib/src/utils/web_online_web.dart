import 'dart:html' as html;

import 'package:flutter/foundation.dart';

/// Estado de rede na Web via [navigator.onLine].
bool webNavigatorOnLine() {
  if (!kIsWeb) return true;
  try {
    return html.window.navigator.onLine ?? true;
  } catch (_) {
    return true;
  }
}
