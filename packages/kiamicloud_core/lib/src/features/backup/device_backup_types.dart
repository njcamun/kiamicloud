import '../../api/models/kiami_file.dart';

/// Âmbito do back-up / restore do dispositivo.
enum DeviceBackupScope {
  contacts,
  apps,
  both,
}

class DeviceBackupProgress {
  const DeviceBackupProgress({
    required this.fraction,
    required this.label,
  });

  final double fraction;
  final String label;
}

typedef DeviceBackupUpload = Future<void> Function(
  String fileName,
  Object file,
  String mimeType,
);

/// Resultado do restore.
class DeviceRestoreResult {
  const DeviceRestoreResult({
    this.contactsRestored = 0,
    this.apksQueued = 0,
  });

  final int contactsRestored;
  final int apksQueued;
}

const String kiamiBackupContactsPrefix = 'kiami-backup-contacts-';
const String kiamiBackupAppsPrefix = 'kiami-backup-apps-';

bool isKiamiBackupContactsFile(String name) =>
    name.startsWith(kiamiBackupContactsPrefix) && name.endsWith('.vcf');

bool isKiamiBackupAppsFile(String name) =>
    name.startsWith(kiamiBackupAppsPrefix) && name.endsWith('.zip');

bool isKiamiBackupFile(String name) =>
    isKiamiBackupContactsFile(name) || isKiamiBackupAppsFile(name);

String? backupStampFromFileName(String name) {
  final match = RegExp(
    r'kiami-backup-(?:contacts|apps)-(.+)\.(?:vcf|zip)$',
  ).firstMatch(name);
  return match?.group(1);
}

/// Par contactos + apps com o mesmo carimbo de data no nome do ficheiro.
class DeviceBackupSet {
  const DeviceBackupSet({
    required this.stamp,
    this.contactsFile,
    this.appsFile,
  });

  final String stamp;
  final KiamiFile? contactsFile;
  final KiamiFile? appsFile;

  bool get hasContacts => contactsFile != null;
  bool get hasApps => appsFile != null;
  bool get isEmpty => !hasContacts && !hasApps;

  DeviceBackupScope get scope {
    if (hasContacts && hasApps) return DeviceBackupScope.both;
    if (hasContacts) return DeviceBackupScope.contacts;
    return DeviceBackupScope.apps;
  }

  String displayLabel(String Function(String stamp) formatStamp) =>
      formatStamp(stamp);
}

List<DeviceBackupSet> groupKiamiBackupFiles(List<KiamiFile> files) {
  final backupFiles = files.where((f) => isKiamiBackupFile(f.name)).toList();
  final byStamp = <String, DeviceBackupSet>{};

  for (final file in backupFiles) {
    final stamp = backupStampFromFileName(file.name);
    if (stamp == null) continue;
    final existing = byStamp[stamp];
    if (isKiamiBackupContactsFile(file.name)) {
      byStamp[stamp] = DeviceBackupSet(
        stamp: stamp,
        contactsFile: file,
        appsFile: existing?.appsFile,
      );
    } else if (isKiamiBackupAppsFile(file.name)) {
      byStamp[stamp] = DeviceBackupSet(
        stamp: stamp,
        contactsFile: existing?.contactsFile,
        appsFile: file,
      );
    }
  }

  final sets = byStamp.values.where((s) => !s.isEmpty).toList()
    ..sort((a, b) => b.stamp.compareTo(a.stamp));
  return sets;
}