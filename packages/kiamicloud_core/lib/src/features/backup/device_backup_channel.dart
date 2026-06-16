import 'package:flutter/services.dart';

/// Lista de apps instaladas e instalação de APK (Android nativo).
class DeviceBackupChannel {
  DeviceBackupChannel._();

  static const _channel = MethodChannel('com.kiamicloud/device_backup');

  static Future<List<Map<String, dynamic>>> listUserApps() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('listUserApps');
    if (raw == null) return [];
    return raw
        .map((e) => Map<String, dynamic>.from(e as Map<Object?, Object?>))
        .toList();
  }

  /// Abre o instalador do sistema para o APK em [apkPath].
  static Future<void> installApk(String apkPath) async {
    await _channel.invokeMethod<void>('installApk', {'path': apkPath});
  }
}
