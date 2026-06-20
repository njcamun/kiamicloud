import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'device_backup_channel.dart';
import 'device_backup_types.dart';

/// Exporta e restaura contactos e/ou apps Android.
class DeviceBackupService {
  Future<bool> ensurePermissions(DeviceBackupScope scope) async {
    return _ensureContactsPermission(scope, write: false);
  }

  Future<bool> ensureRestorePermissions(DeviceBackupScope scope) async {
    if (!kIsWeb && Platform.isAndroid) {
      if (scope == DeviceBackupScope.contacts ||
          scope == DeviceBackupScope.both) {
        if (!await _ensureContactsPermission(scope, write: true)) {
          return false;
        }
      }
      if (scope == DeviceBackupScope.apps ||
          scope == DeviceBackupScope.both) {
        final install = await Permission.requestInstallPackages.status;
        if (!install.isGranted) {
          final req = await Permission.requestInstallPackages.request();
          if (!req.isGranted) return false;
        }
      }
      return true;
    }
    return false;
  }

  Future<bool> _ensureContactsPermission(
    DeviceBackupScope scope, {
    required bool write,
  }) async {
    if (!kIsWeb && Platform.isAndroid) {
      if (scope == DeviceBackupScope.contacts ||
          scope == DeviceBackupScope.both) {
        if (!await FlutterContacts.requestPermission(readonly: !write)) {
          return false;
        }
        final status = await Permission.contacts.status;
        if (!status.isGranted) {
          final req = await Permission.contacts.request();
          if (!req.isGranted) return false;
        }
      }
      return true;
    }
    return false;
  }

  Future<void> run({
    required DeviceBackupScope scope,
    required DeviceBackupUpload upload,
    required void Function(DeviceBackupProgress progress) onProgress,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      throw UnsupportedError('Back-up apenas disponível em Android.');
    }

    final doContacts =
        scope == DeviceBackupScope.contacts || scope == DeviceBackupScope.both;
    final doApps =
        scope == DeviceBackupScope.apps || scope == DeviceBackupScope.both;

    var step = 0;
    final totalSteps = (doContacts ? 1 : 0) + (doApps ? 1 : 0);
    if (totalSteps == 0) return;

    void report(String label, double part) {
      onProgress(
        DeviceBackupProgress(
          fraction: ((step + part) / totalSteps).clamp(0.0, 1.0),
          label: label,
        ),
      );
    }

    File? contactsFile;
    File? appsZipFile;

    try {
      if (doContacts) {
        report('A exportar contactos…', 0.1);
        contactsFile = await _exportContactsVcfToFile(
          onSubProgress: (p) => report('A exportar contactos…', p * 0.9),
        );
        report('A enviar contactos…', 0.92);
        final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
        await upload(
          'kiami-backup-contacts-$stamp.vcf',
          contactsFile,
          'text/vcard',
        );
        step += 1;
        report('Contactos concluídos', 1.0);
      }

      if (doApps) {
        report('A preparar lista de apps…', 0.05);
        appsZipFile = await _exportAppsZipToFile(
          onSubProgress: (p) => report('A empacotar apps…', p * 0.85),
        );
        report('A enviar apps…', 0.92);
        final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
        await upload(
          'kiami-backup-apps-$stamp.zip',
          appsZipFile,
          'application/zip',
        );
        step += 1;
        onProgress(
          const DeviceBackupProgress(fraction: 1.0, label: 'Back-up concluído'),
        );
      }
    } finally {
      await _deleteTempFile(contactsFile);
      await _deleteTempFile(appsZipFile);
    }
  }

  Future<void> _deleteTempFile(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignora falha ao limpar ficheiro temporário.
    }
  }

  Future<File> _exportContactsVcfToFile({
    required void Function(double) onSubProgress,
  }) async {
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );
    final tmp = await getTemporaryDirectory();
    final out = File(
      p.join(
        tmp.path,
        'kiami_backup_contacts_${DateTime.now().millisecondsSinceEpoch}.vcf',
      ),
    );
    final sink = out.openWrite(encoding: utf8);
    final total = contacts.length;
    for (var i = 0; i < total; i++) {
      sink.writeln(contacts[i].toVCard());
      if (total > 0 && (i % 10 == 0 || i == total - 1)) {
        onSubProgress((i + 1) / total);
      }
    }
    await sink.flush();
    await sink.close();
    onSubProgress(1.0);
    return out;
  }

  Future<File> _exportAppsZipToFile({
    required void Function(double) onSubProgress,
  }) async {
    final apps = await DeviceBackupChannel.listUserApps();
    final tmp = await getTemporaryDirectory();
    final zipPath = p.join(
      tmp.path,
      'kiami_backup_apps_${DateTime.now().millisecondsSinceEpoch}.zip',
    );

    final manifest = <Map<String, dynamic>>[];
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);

    final total = apps.length;
    for (var i = 0; i < total; i++) {
      final app = apps[i];
      manifest.add({
        'packageName': app['packageName'],
        'appName': app['appName'],
        'versionName': app['versionName'],
        'versionCode': app['versionCode'],
        'systemApp': app['systemApp'] ?? false,
        'installTimeMillis': app['installTimeMillis'],
        'updateTimeMillis': app['updateTimeMillis'],
      });

      final apkPath = app['apkPath'] as String?;
      if (apkPath != null && apkPath.isNotEmpty) {
        final file = File(apkPath);
        if (await file.exists()) {
          final packageName = app['packageName'] as String? ?? 'app';
          final safeName = packageName.replaceAll('.', '_');
          await encoder.addFile(file, 'apks/$safeName.apk');
        }
      }

      if (total > 0) {
        onSubProgress((i + 1) / total);
      }
    }

    final manifestBytes = utf8.encode(jsonEncode(manifest));
    encoder.addArchiveFile(
      ArchiveFile('apps.json', manifestBytes.length, manifestBytes),
    );
    await encoder.close();

    final zipFile = File(zipPath);
    if (!await zipFile.exists() || await zipFile.length() == 0) {
      throw StateError('Falha ao criar ficheiro ZIP de apps.');
    }
    return zipFile;
  }

  Future<DeviceRestoreResult> restore({
    required DeviceBackupScope scope,
    List<int>? contactsBytes,
    File? appsZipFile,
    required void Function(DeviceBackupProgress progress) onProgress,
    Future<void> Function(int current, int total)? onBeforeApkInstall,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      throw UnsupportedError('Restore apenas disponível em Android.');
    }

    final doContacts =
        (scope == DeviceBackupScope.contacts || scope == DeviceBackupScope.both) &&
            contactsBytes != null;
    final doApps =
        (scope == DeviceBackupScope.apps || scope == DeviceBackupScope.both) &&
            appsZipFile != null;

    var step = 0;
    final totalSteps = (doContacts ? 1 : 0) + (doApps ? 1 : 0);
    if (totalSteps == 0) {
      throw StateError('Nenhum ficheiro de back-up seleccionado.');
    }

    void report(String label, double part) {
      onProgress(
        DeviceBackupProgress(
          fraction: ((step + part) / totalSteps).clamp(0.0, 1.0),
          label: label,
        ),
      );
    }

    var contactsRestored = 0;
    var apksQueued = 0;

    if (doContacts) {
      final bytes = contactsBytes;
      report('A restaurar contactos…', 0.1);
      contactsRestored = await _importContactsVcf(
        bytes,
        onSubProgress: (p) => report('A restaurar contactos…', p * 0.9),
      );
      step += 1;
      report('Contactos restaurados', 1.0);
    }

    if (doApps) {
      final zipFile = appsZipFile;
      report('A preparar apps…', 0.05);
      apksQueued = await _restoreAppsZipFromFile(
        zipFile,
        onSubProgress: (p) => report('A preparar apps…', p * 0.4),
        onBeforeInstall: onBeforeApkInstall,
        onInstallProgress: (current, total) {
          final part = total == 0 ? 1.0 : current / total;
          report('A instalar apps ($current/$total)…', 0.4 + part * 0.55);
        },
      );
      step += 1;
      onProgress(
        const DeviceBackupProgress(
          fraction: 1.0,
          label: 'Restore concluído',
        ),
      );
    }

    return DeviceRestoreResult(
      contactsRestored: contactsRestored,
      apksQueued: apksQueued,
    );
  }

  Future<int> _importContactsVcf(
    List<int> bytes, {
    required void Function(double) onSubProgress,
  }) async {
    final vcf = utf8.decode(bytes);
    final contacts = _parseVcfContacts(vcf);
    if (contacts.isEmpty) {
      throw StateError('Nenhum contacto encontrado no ficheiro VCF.');
    }

    final total = contacts.length;
    for (var i = 0; i < total; i++) {
      await contacts[i].insert();
      if (total > 0 && (i % 5 == 0 || i == total - 1)) {
        onSubProgress((i + 1) / total);
      }
    }
    onSubProgress(1.0);
    return total;
  }

  List<Contact> _parseVcfContacts(String vcf) {
    final chunks = vcf.split(RegExp(r'(?=BEGIN:VCARD)', multiLine: true));
    final contacts = <Contact>[];
    for (final chunk in chunks) {
      final trimmed = chunk.trim();
      if (trimmed.isEmpty) continue;
      try {
        contacts.add(Contact.fromVCard(trimmed));
      } catch (_) {
        // Ignora cartões inválidos.
      }
    }
    return contacts;
  }

  Future<int> _restoreAppsZipFromFile(
    File zipFile, {
    required void Function(double) onSubProgress,
    required void Function(int current, int total) onInstallProgress,
    Future<void> Function(int current, int total)? onBeforeInstall,
  }) async {
    if (!await zipFile.exists()) {
      throw StateError('Ficheiro ZIP de apps não encontrado.');
    }

    final tmp = await getTemporaryDirectory();
    final installDir = Directory(p.join(tmp.path, 'apk_install'));
    if (await installDir.exists()) {
      await installDir.delete(recursive: true);
    }
    await installDir.create(recursive: true);

    onSubProgress(0.1);
    await extractFileToDisk(zipFile.path, installDir.path);
    onSubProgress(1.0);

    final apksDir = Directory(p.join(installDir.path, 'apks'));
    if (!await apksDir.exists()) {
      throw StateError('Nenhum APK encontrado no ficheiro de back-up.');
    }

    final apkFiles = <File>[];
    await for (final entity in apksDir.list(followLinks: false)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.apk')) {
        apkFiles.add(entity);
      }
    }
    apkFiles.sort((a, b) => a.path.compareTo(b.path));

    if (apkFiles.isEmpty) {
      throw StateError('Nenhum APK encontrado no ficheiro de back-up.');
    }

    for (var i = 0; i < apkFiles.length; i++) {
      onInstallProgress(i + 1, apkFiles.length);
      if (onBeforeInstall != null) {
        await onBeforeInstall(i + 1, apkFiles.length);
      }
      await DeviceBackupChannel.installApk(apkFiles[i].path);
    }

    return apkFiles.length;
  }
}
