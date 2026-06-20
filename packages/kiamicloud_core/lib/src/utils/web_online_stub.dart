import 'package:flutter/foundation.dart';

/// Estado de rede na Web — stub fora da Web.
bool webNavigatorOnLine() {
  if (!kIsWeb) return true;
  return true;
}
