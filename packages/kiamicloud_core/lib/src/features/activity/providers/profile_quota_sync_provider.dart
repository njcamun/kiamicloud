import 'dart:async';



import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../../api/models/kiami_profile.dart';

import '../../../utils/kiami_quota_normalize.dart';

import '../../billing/providers/billing_providers.dart';

import '../../files/providers/files_providers.dart';

import 'account_activity_providers.dart';



/// Último evento «quota_updated» já processado (evita refresh em loop).

final _lastQuotaEventIdProvider = StateProvider<int?>((ref) => null);



int _effectiveQuotaFromEvent(int bytes) => parseEffectiveQuotaBytes(bytes);



bool _profileDiffersFromQuotaEvent(

  KiamiProfile profile,

  Map<String, dynamic> meta,

) {

  final quota = (meta['quotaBytes'] as num?)?.toInt();

  final maxFile = (meta['maxFileSizeBytes'] as num?)?.toInt();

  if (quota != null &&

      _effectiveQuotaFromEvent(quota) != profile.plan.quotaBytes) {

    return true;

  }

  if (maxFile != null &&

      profile.maxFileSizeBytes > 0 &&

      maxFile != profile.maxFileSizeBytes) {

    return true;

  }

  return false;

}



void _refreshQuotaConsumers(dynamic ref) {

  refreshKiamiProfile(ref);

  ref.invalidate(billingStatusProvider);

}



/// Sincroniza limites do utilizador com a API quando o admin altera quotas.

final profileQuotaSyncProvider = Provider<void>((ref) {

  final timer = Timer.periodic(const Duration(seconds: 60), (_) {

    ref.invalidate(accountActivityProvider);

  });

  ref.onDispose(timer.cancel);



  ref.listen(accountActivityProvider, (previous, next) {

    next.whenData((activity) {

      final quotaEvents = activity.events

          .where((e) => e.kind == 'quota_updated')

          .toList();

      if (quotaEvents.isEmpty) return;



      final latest = quotaEvents.first;

      final profile = ref.read(kiamiProfileProvider).valueOrNull;

      final meta = latest.metadata;

      final lastId = ref.read(_lastQuotaEventIdProvider);



      if (lastId == latest.id) {

        if (profile != null &&

            meta != null &&

            !_profileDiffersFromQuotaEvent(profile, meta)) {

          return;

        }

      }



      final shouldRefresh = latest.isUnread ||

          profile == null ||

          meta == null ||

          _profileDiffersFromQuotaEvent(profile, meta);



      if (shouldRefresh) {

        ref.read(_lastQuotaEventIdProvider.notifier).state = latest.id;

        _refreshQuotaConsumers(ref);

      }

    });

  });

});

