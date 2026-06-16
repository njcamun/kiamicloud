import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/kiami_api_client.dart';

enum OfflineMutationType { delete, rename }

class OfflineMutation {
  const OfflineMutation({
    required this.type,
    required this.fileId,
    this.newName,
    required this.createdAt,
  });

  final OfflineMutationType type;
  final String fileId;
  final String? newName;
  final String createdAt;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'fileId': fileId,
        if (newName != null) 'newName': newName,
        'createdAt': createdAt,
      };

  static OfflineMutation? fromJson(Map<String, dynamic> json) {
    try {
      final type = OfflineMutationType.values.firstWhere(
        (t) => t.name == json['type'],
      );
      return OfflineMutation(
        type: type,
        fileId: json['fileId'] as String,
        newName: json['newName'] as String?,
        createdAt: json['createdAt'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}

/// Fila de apagar/renomear para sincronizar quando a rede voltar.
class OfflineMutationQueue {
  OfflineMutationQueue._(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'offline_mutations_v1';

  static Future<OfflineMutationQueue> load() async {
    final prefs = await SharedPreferences.getInstance();
    return OfflineMutationQueue._(prefs);
  }

  List<OfflineMutation> readAll() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => OfflineMutation.fromJson(e as Map<String, dynamic>))
          .whereType<OfflineMutation>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<OfflineMutation> items) async {
    await _prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> enqueueDelete(String fileId) async {
    final items = readAll()
      ..removeWhere((m) => m.fileId == fileId)
      ..add(
        OfflineMutation(
          type: OfflineMutationType.delete,
          fileId: fileId,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    await _save(items);
  }

  Future<void> enqueueRename(String fileId, String newName) async {
    final items = readAll()
      ..removeWhere((m) => m.fileId == fileId)
      ..add(
        OfflineMutation(
          type: OfflineMutationType.rename,
          fileId: fileId,
          newName: newName,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    await _save(items);
  }

  Future<int> flush(KiamiApiClient api) async {
    final pending = readAll();
    if (pending.isEmpty) return 0;

    var done = 0;
    final remaining = <OfflineMutation>[];

    for (final mutation in pending) {
      try {
        switch (mutation.type) {
          case OfflineMutationType.delete:
            await api.deleteFile(mutation.fileId);
          case OfflineMutationType.rename:
            if (mutation.newName != null) {
              await api.renameFile(
                fileId: mutation.fileId,
                newName: mutation.newName!,
              );
            }
        }
        done++;
      } catch (_) {
        remaining.add(mutation);
      }
    }

    await _save(remaining);
    return done;
  }
}

final offlineMutationQueueProvider =
    FutureProvider<OfflineMutationQueue>((ref) {
  return OfflineMutationQueue.load();
});
