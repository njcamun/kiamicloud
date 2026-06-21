import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/kiami_api_client.dart';
import '../../../api/kiami_api_config.dart';
import '../../../api/kiami_api_exception.dart';
import '../../../api/models/kiami_file.dart';
import '../../../api/models/kiami_profile.dart';
import '../../../constants/kiami_strings.dart';
import '../../../data/offline_cache.dart';
import '../../../data/offline_mutation_queue.dart';
import '../../../utils/format_bytes.dart';
import '../../../utils/kiami_api_limits.dart';
import '../../connectivity/connectivity_provider.dart';
import '../../activity/providers/account_activity_providers.dart';
import 'kiami_api_provider.dart';

export 'kiami_api_provider.dart';

/// Incrementa para forçar novo GET /me (ex.: após admin alterar limites).
final profileRefreshSignalProvider = StateProvider<int>((ref) => 0);

void refreshKiamiProfile(dynamic ref) {
  ref.read(profileRefreshSignalProvider.notifier).update((int n) => n + 1);
  ref.invalidate(kiamiProfileProvider);
  ref.invalidate(accountActivityProvider);
}

/// Sincroniza fila offline quando a rede volta.
final offlineMutationSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<bool>>(isOnlineProvider, (prev, next) async {
    final wasOffline = prev?.valueOrNull == false;
    final isOnline = next.valueOrNull ?? false;
    if (!wasOffline || !isOnline) return;

    final queue = await ref.read(offlineMutationQueueProvider.future);
    final api = ref.read(kiamiApiClientProvider);
    final synced = await queue.flush(api);
    if (synced > 0) {
      ref.invalidate(kiamiFilesProvider);
      ref.invalidate(kiamiProfileProvider);
    }
  });
});

Future<KiamiProfile> _loadProfileWithCache(Ref ref) async {
  ref.watch(profileRefreshSignalProvider);
  final api = ref.read(kiamiApiClientProvider);
  final online = ref.read(isOnlineProvider).valueOrNull ?? true;

  try {
    final profile = KiamiApiLimits.relaxForCurrentApi(await api.getMe());
    final cache = await ref.read(offlineCacheProvider.future);
    await cache.saveProfile(profile);
    return profile;
  } catch (e) {
    if (!online) {
      final cache = await ref.read(offlineCacheProvider.future);
      final cached = cache.readProfile();
      if (cached != null) {
        return KiamiApiLimits.relaxForCurrentApi(cached);
      }
    }

    Error.throwWithStackTrace(
      e is KiamiApiException ? e : KiamiApiClient.connectionError(),
      StackTrace.current,
    );
  }
}

Future<List<KiamiFile>> _loadFilesWithCache(Ref ref) async {
  await ref.watch(kiamiProfileProvider.future);

  final api = ref.read(kiamiApiClientProvider);
  final online = ref.read(isOnlineProvider).valueOrNull ?? true;

  try {
    final files = await api.listFiles();
    final cache = await ref.read(offlineCacheProvider.future);
    await cache.saveFiles(files);
    return files;
  } catch (e) {
    if (!online) {
      final cache = await ref.read(offlineCacheProvider.future);
      final cached = cache.readFiles();
      if (cached != null) return cached;
    }

    Error.throwWithStackTrace(
      e is KiamiApiException ? e : KiamiApiClient.connectionError(),
      StackTrace.current,
    );
  }
}

final kiamiProfileProvider = FutureProvider<KiamiProfile>((ref) async {
  ref.watch(profileRefreshSignalProvider);
  return _loadProfileWithCache(ref);
});

final kiamiFilesProvider = FutureProvider<List<KiamiFile>>((ref) async {
  ref.watch(kiamiProfileProvider);
  return _loadFilesWithCache(ref);
});

/// Última lista de ficheiros com sucesso — evita skeleton durante refresh.
final kiamiFilesSnapshotProvider = StateProvider<List<KiamiFile>?>((ref) => null);

/// Mantém snapshot actualizado quando [kiamiFilesProvider] devolve dados.
final kiamiFilesSnapshotSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<List<KiamiFile>>>(kiamiFilesProvider, (_, next) {
    next.whenData((files) {
      ref.read(kiamiFilesSnapshotProvider.notifier).state = files;
    });
  });
});

/// Lista de ficheiros para UI — usa cache enquanto a API recarrega.
final kiamiFilesViewProvider = Provider<AsyncValue<List<KiamiFile>>>((ref) {
  ref.watch(kiamiFilesSnapshotSyncProvider);
  final async = ref.watch(kiamiFilesProvider);
  if (async.hasValue) return async;
  final cached = ref.watch(kiamiFilesSnapshotProvider);
  if (cached != null && async.isLoading) {
    return AsyncData(cached);
  }
  return async;
});

String kiamiApiErrorMessage(Object error) {
  if (error is KiamiApiException) {
    return switch (error.errorCode) {
      'connection_failed' => error.message.isNotEmpty
          ? error.message
          : KiamiStrings.apiUnavailableBody(KiamiApiConfig.baseUrl),
      'quota_exceeded' => 'Quota de armazenamento cheia.',
      'file_too_large' => error.maxFileSizeBytes != null
          ? KiamiStrings.uploadTooLarge(formatBytes(error.maxFileSizeBytes!))
          : (error.message.isNotEmpty
              ? error.message
              : 'Ficheiro demasiado grande para o teu plano.'),
      'subscription_restricted' => KiamiStrings.subscriptionRestricted,
      'subscription_suspended' => KiamiStrings.subscriptionSuspended,
      'storage_over_quota' => KiamiStrings.subscriptionStorageOverQuota,
      'invalid_token' || 'unauthorized' =>
        'Sessão inválida. Inicie sessão novamente.',
      'email_not_verified' => KiamiStrings.emailVerificationRequired,
      'internal_error' => error.message.isNotEmpty
          ? error.message
          : 'Erro interno do servidor. Tente novamente.',
      'duplicate_name' => 'Já existe um ficheiro com este nome.',
      _ => error.message.isNotEmpty
          ? error.message
          : KiamiStrings.apiErrorTitle,
    };
  }

  return KiamiStrings.apiUnavailableBody(KiamiApiConfig.baseUrl);
}

bool kiamiApiErrorIsConnection(Object error) {
  if (error is KiamiApiException) {
    return error.errorCode == 'connection_failed';
  }
  return true;
}
