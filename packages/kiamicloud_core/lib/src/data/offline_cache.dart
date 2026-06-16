import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/models/kiami_file.dart';
import '../api/models/kiami_profile.dart';
import '../api/models/kiami_quota.dart';

/// Cache local da lista de ficheiros e perfil para modo offline.
class OfflineCache {
  OfflineCache._(this._prefs);

  final SharedPreferences _prefs;

  static const _filesKey = 'offline_files_json';
  static const _profileKey = 'offline_profile_json';
  static const _cachedAtKey = 'offline_cached_at';

  static Future<OfflineCache> load() async {
    final prefs = await SharedPreferences.getInstance();
    return OfflineCache._(prefs);
  }

  Future<void> saveFiles(List<KiamiFile> files) async {
    final json = files.map((f) => _fileToJson(f)).toList();
    await _prefs.setString(_filesKey, jsonEncode(json));
    await _prefs.setString(_cachedAtKey, DateTime.now().toIso8601String());
  }

  List<KiamiFile>? readFiles() {
    final raw = _prefs.getString(_filesKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => KiamiFile.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(KiamiProfile profile) async {
    await _prefs.setString(_profileKey, jsonEncode(_profileToJson(profile)));
    await _prefs.setString(_cachedAtKey, DateTime.now().toIso8601String());
  }

  KiamiProfile? readProfile() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return null;
    try {
      return KiamiProfile.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  DateTime? cachedAt() {
    final raw = _prefs.getString(_cachedAtKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static Map<String, dynamic> _fileToJson(KiamiFile f) => {
        'id': f.id,
        'name': f.name,
        'mimeType': f.mimeType,
        'sizeBytes': f.sizeBytes,
        'status': f.status,
        'folderId': f.folderId,
        'createdAt': f.createdAt,
        'updatedAt': f.updatedAt,
        'hasThumbnail': f.hasThumbnail,
      };

  static Map<String, dynamic> _profileToJson(KiamiProfile p) => {
        'uid': p.uid,
        'email': p.email,
        'emailVerified': p.emailVerified,
        'displayName': p.displayName,
        'quotaBytes': p.plan.quotaBytes,
        'storageUsedBytes': p.storageUsedBytes,
        'storageAvailableBytes': p.storageAvailableBytes,
        'maxFileSizeBytes': p.maxFileSizeBytes,
        'canSwitchApiEndpoint': p.canSwitchApiEndpoint,
        'plan': {
          'code': p.plan.code,
          'name': p.plan.name,
          'quotaBytes': p.plan.quotaBytes,
          'priceKzMonth': p.plan.priceKzMonth,
          'maxFileSizeBytes': p.plan.maxFileSizeBytes,
        },
        'quota': {
          'status': switch (p.quota.status) {
            QuotaStatus.ok => 'ok',
            QuotaStatus.warning => 'warning',
            QuotaStatus.critical => 'critical',
            QuotaStatus.full => 'full',
          },
          'usagePercent': p.quota.usagePercent,
          'canUpload': p.quota.canUpload,
          'warningAtPercent': p.quota.warningAtPercent,
          'criticalAtPercent': p.quota.criticalAtPercent,
          'message': p.quota.message,
        },
      };
}

final offlineCacheProvider = FutureProvider<OfflineCache>((ref) {
  return OfflineCache.load();
});
