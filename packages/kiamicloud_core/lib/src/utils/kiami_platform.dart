import 'package:flutter/foundation.dart';

/// App nativa Windows / macOS / Linux (não Web nem mobile).
bool kiamiIsNativeDesktop() {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.windows ||
    TargetPlatform.macOS ||
    TargetPlatform.linux =>
      true,
    _ => false,
  };
}

/// Telemóvel/tablet Android (não Web).
bool kiamiIsAndroid() {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android;
}

/// Back-up de contactos/apps — apenas Android nativo.
bool kiamiDeviceBackupSupported() => kiamiIsAndroid();
