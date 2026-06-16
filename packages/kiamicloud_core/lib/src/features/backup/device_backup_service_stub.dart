import 'device_backup_types.dart';

/// Implementação vazia (Web / desktop).
class DeviceBackupService {
  Future<bool> ensurePermissions(DeviceBackupScope scope) async => false;

  Future<bool> ensureRestorePermissions(DeviceBackupScope scope) async => false;

  Future<void> run({
    required DeviceBackupScope scope,
    required DeviceBackupUpload upload,
    required void Function(DeviceBackupProgress progress) onProgress,
  }) async {}

  Future<DeviceRestoreResult> restore({
    required DeviceBackupScope scope,
    List<int>? contactsBytes,
    List<int>? appsBytes,
    required void Function(DeviceBackupProgress progress) onProgress,
    Future<void> Function(int current, int total)? onBeforeApkInstall,
  }) async =>
      const DeviceRestoreResult();
}
