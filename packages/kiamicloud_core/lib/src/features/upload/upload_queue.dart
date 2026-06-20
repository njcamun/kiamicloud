import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/kiami_api_client.dart';
import '../../api/kiami_api_exception.dart';
import '../../utils/kiami_api_limits.dart';
import '../../utils/guess_mime.dart';
import '../../utils/path_file_bytes.dart';
import '../files/providers/files_providers.dart';

enum UploadQueueItemStatus {
  pending,
  uploading,
  completed,
  failed,
}

class UploadQueueItem {
  const UploadQueueItem({
    required this.id,
    required this.name,
    required this.sizeBytes,
    this.path,
    this.bytes,
    required this.status,
    this.errorMessage,
    this.attempts = 0,
    this.progress = 0,
  });

  final String id;
  final String name;
  final int sizeBytes;
  /// Caminho local (Android/desktop) — bytes carregados só no upload.
  final String? path;
  /// Bytes em memória (web ou fallback); libertados após envio.
  final List<int>? bytes;
  final UploadQueueItemStatus status;
  final String? errorMessage;
  final int attempts;
  /// Progresso do envio (0.0 – 1.0).
  final double progress;

  UploadQueueItem copyWith({
    UploadQueueItemStatus? status,
    String? errorMessage,
    int? attempts,
    List<int>? bytes,
    double? progress,
    bool clearBytes = false,
  }) {
    return UploadQueueItem(
      id: id,
      name: name,
      sizeBytes: sizeBytes,
      path: path,
      bytes: clearBytes ? null : bytes ?? this.bytes,
      status: status ?? this.status,
      errorMessage: errorMessage,
      attempts: attempts ?? this.attempts,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sizeBytes': sizeBytes,
        'status': status.name,
        'errorMessage': errorMessage,
        'attempts': attempts,
      };

  static UploadQueueItem? fromJson(Map<String, dynamic> json) {
    // Bytes/path não são persistidos — ignorar fila guardada após reinício.
    return null;
  }
}

class UploadQueueState {
  const UploadQueueState({
    this.items = const [],
    this.isProcessing = false,
  });

  final List<UploadQueueItem> items;
  final bool isProcessing;

  int get activeCount => items.where((i) {
        return i.status == UploadQueueItemStatus.pending ||
            i.status == UploadQueueItemStatus.uploading ||
            i.status == UploadQueueItemStatus.failed;
      }).length;

  UploadQueueState copyWith({
    List<UploadQueueItem>? items,
    bool? isProcessing,
  }) {
    return UploadQueueState(
      items: items ?? this.items,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

/// Pedido para a fila — preferir [path] em vez de [bytes] quando disponível.
typedef UploadQueueRequest = ({
  String name,
  int sizeBytes,
  String? path,
  List<int>? bytes,
});

class UploadQueueNotifier extends StateNotifier<UploadQueueState> {
  UploadQueueNotifier(this._ref) : super(const UploadQueueState()) {
    _restore();
  }

  final Ref _ref;
  static const _storageKey = 'upload_queue_v1';
  static const _maxAttempts = 3;
  bool _drainAgain = false;
  int _lastProgressEmitMs = 0;
  int _lastProgressPercent = -1;

  bool _shouldEmitProgress(double pct) {
    final percent = (pct * 100).round().clamp(0, 100);
    if (percent >= 100 || percent == 0) return true;
    if (percent != _lastProgressPercent) {
      _lastProgressPercent = percent;
      _lastProgressEmitMs = DateTime.now().millisecondsSinceEpoch;
      return true;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastProgressEmitMs >= 250) {
      _lastProgressEmitMs = now;
      return true;
    }
    return false;
  }

  void _resetProgressThrottle() {
    _lastProgressPercent = -1;
    _lastProgressEmitMs = 0;
  }

  int _maxFileBytes() {
    final profile = _ref.read(kiamiProfileProvider).valueOrNull;
    return KiamiApiLimits.maxUploadFileBytes(
      profileMax: profile?.maxFileSizeBytes,
    );
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final items = <UploadQueueItem>[];
      for (final e in list) {
        final item =
            UploadQueueItem.fromJson(e as Map<String, dynamic>);
        if (item != null) items.add(item);
      }
      if (items.isNotEmpty) {
        state = state.copyWith(items: items);
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final toSave = state.items
        .where((i) => i.status != UploadQueueItemStatus.completed)
        .map((i) => i.toJson())
        .toList();
    if (toSave.isEmpty) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setString(_storageKey, jsonEncode(toSave));
    }
  }

  void enqueueAll(List<UploadQueueRequest> files) {
    if (files.isEmpty) return;
    final base = DateTime.now().microsecondsSinceEpoch;
    final newItems = <UploadQueueItem>[];
    for (var i = 0; i < files.length; i++) {
      final f = files[i];
      newItems.add(
        UploadQueueItem(
          id: '${base}_${i}_${f.name.hashCode}',
          name: f.name,
          sizeBytes: f.sizeBytes,
          path: f.path,
          bytes: f.bytes,
          status: UploadQueueItemStatus.pending,
        ),
      );
    }
    state = state.copyWith(items: [...state.items, ...newItems]);
    _persist();
    processQueue();
  }

  void remove(String id) {
    state = state.copyWith(
      items: state.items.where((i) => i.id != id).toList(),
    );
    _persist();
  }

  void retry(String id) {
    final items = state.items.map((i) {
      if (i.id != id) return i;
      return i.copyWith(
        status: UploadQueueItemStatus.pending,
        errorMessage: null,
        clearBytes: !kIsWeb,
      );
    }).toList();
    state = state.copyWith(items: items);
    _persist();
    processQueue();
  }

  Future<List<int>> _loadBytes(UploadQueueItem item) async {
    if (item.bytes != null && item.bytes!.isNotEmpty) {
      return item.bytes!;
    }
    if (item.path != null && item.path!.isNotEmpty && !kIsWeb) {
      final maxBytes = _maxFileBytes();
      final bytes = await readPathFileBytes(item.path!, maxBytes);
      if (bytes == null || bytes.isEmpty) {
        throw KiamiApiException('Não foi possível ler ${item.name}.');
      }
      return bytes;
    }
    throw KiamiApiException('Ficheiro ${item.name} já não está disponível.');
  }

  Future<void> waitUntilIdle() async {
    final deadline = DateTime.now().add(const Duration(minutes: 30));
    while (DateTime.now().isBefore(deadline)) {
      if (!state.isProcessing &&
          !state.items.any(
            (i) =>
                i.status == UploadQueueItemStatus.pending ||
                i.status == UploadQueueItemStatus.uploading,
          )) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }

  bool _hasPendingWork() {
    return state.items.any(
      (i) =>
          i.status == UploadQueueItemStatus.pending ||
          (i.status == UploadQueueItemStatus.failed &&
              i.attempts < _maxAttempts),
    );
  }

  Future<void> processQueue() async {
    if (state.isProcessing) {
      _drainAgain = true;
      return;
    }

    do {
      _drainAgain = false;
      state = state.copyWith(isProcessing: true);

      var sessionSucceeded = 0;
      var sessionFailed = 0;

      try {
        while (true) {
        final index = state.items.indexWhere(
          (i) =>
              i.status == UploadQueueItemStatus.pending ||
              (i.status == UploadQueueItemStatus.failed &&
                  i.attempts < _maxAttempts),
        );
        if (index < 0) break;

        var item = state.items[index];
        final itemId = item.id;
        if (item.status == UploadQueueItemStatus.failed) {
          item = item.copyWith(attempts: item.attempts + 1);
        }

        item = item.copyWith(
          status: UploadQueueItemStatus.uploading,
          progress: 0,
        );
        _resetProgressThrottle();
        _updateById(itemId, item);

        try {
          final bytes = await _loadBytes(item);
          await _ref.read(kiamiApiClientProvider).uploadFile(
                name: item.name,
                bytes: bytes,
                mimeType: guessMimeType(item.name),
                onProgress: (sent, total) {
                  if (total <= 0) return;
                  final pct = (sent / total).clamp(0.0, 1.0);
                  if (!_shouldEmitProgress(pct)) return;
                  final current = _findById(itemId);
                  if (current == null ||
                      current.status != UploadQueueItemStatus.uploading) {
                    return;
                  }
                  _updateById(itemId, current.copyWith(progress: pct));
                },
              );
          sessionSucceeded += 1;
          _updateById(
            itemId,
            item.copyWith(
              status: UploadQueueItemStatus.completed,
              progress: 1,
              clearBytes: true,
            ),
          );
          state = state.copyWith(
            items: state.items.where((i) => i.id != itemId).toList(),
          );
        } catch (e) {
          sessionFailed += 1;
          final msg = e is KiamiApiException
              ? e.message
              : KiamiApiClient.connectionError().message;
          final failedAttempts = item.attempts + 1;
          _updateById(
            itemId,
            item.copyWith(
              status: UploadQueueItemStatus.failed,
              errorMessage: msg,
              attempts: failedAttempts,
              clearBytes: !kIsWeb,
            ),
          );
          if (e is KiamiApiException &&
              (e.errorCode == 'quota_exceeded' ||
                  e.errorCode == 'file_too_large' ||
                  e.errorCode == 'subscription_restricted' ||
                  e.errorCode == 'subscription_suspended' ||
                  e.errorCode == 'subscription_inactive' ||
                  e.errorCode == 'subscription_blocked' ||
                  e.errorCode == 'storage_over_quota')) {
            continue;
          }
          await Future<void>.delayed(
            Duration(milliseconds: 800 * failedAttempts),
          );
        }
        await _persist();
        }
      } finally {
        state = state.copyWith(isProcessing: false);
        await _persist();
        if (sessionSucceeded > 0) {
          _ref.invalidate(kiamiProfileProvider);
          _ref.invalidate(kiamiFilesProvider);
        } else if (sessionFailed > 0) {
          _ref.invalidate(kiamiFilesProvider);
        }
        if (sessionSucceeded > 0 || sessionFailed > 0) {
          _ref.read(uploadBatchResultProvider.notifier).state =
              UploadBatchResult(
            succeeded: sessionSucceeded,
            failed: sessionFailed,
          );
        }
      }
    } while (_drainAgain || _hasPendingWork());
  }

  UploadQueueItem? _findById(String id) {
    for (final item in state.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _updateById(String id, UploadQueueItem item) {
    final index = state.items.indexWhere((i) => i.id == id);
    if (index >= 0) _updateAt(index, item);
  }

  void _updateAt(int index, UploadQueueItem item) {
    final items = [...state.items];
    if (index >= 0 && index < items.length) {
      items[index] = item;
      state = state.copyWith(items: items);
    }
  }

  void clearCompleted() {
    state = state.copyWith(
      items: state.items
          .where((i) => i.status != UploadQueueItemStatus.completed)
          .toList(),
    );
    _persist();
  }
}

/// Resultado de um ciclo de processamento da fila (para notificação).
class UploadBatchResult {
  const UploadBatchResult({required this.succeeded, required this.failed});

  final int succeeded;
  final int failed;
}

final uploadBatchResultProvider =
    StateProvider<UploadBatchResult?>((ref) => null);

final uploadQueueProvider =
    StateNotifierProvider<UploadQueueNotifier, UploadQueueState>((ref) {
  return UploadQueueNotifier(ref);
});

int uploadMaxFileBytesFromProfile(int? profileMax) {
  return KiamiApiLimits.maxUploadFileBytes(profileMax: profileMax);
}
