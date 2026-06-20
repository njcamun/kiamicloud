import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/kiami_strings.dart';
import '../../utils/kiami_support_contact.dart';
import '../files/providers/files_providers.dart';

/// Planos com back-up / restore do dispositivo (Plus e superiores).
const kiamiDeviceBackupPlanCodes = <String>{
  'plus',
  'start',
  'premium',
  'pro',
  'ultra',
};

bool kiamiPlanIncludesDeviceBackup(String planCode) =>
    kiamiDeviceBackupPlanCodes.contains(planCode);

/// Bloqueia o fluxo se o plano activo não incluir back-up do dispositivo.
Future<bool> ensureDeviceBackupPlanAccess(
  BuildContext context,
  WidgetRef ref,
) async {
  var profile = ref.read(kiamiProfileProvider).valueOrNull;
  if (profile == null) {
    try {
      profile = await ref.read(kiamiProfileProvider.future);
    } catch (_) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(KiamiStrings.deviceBackupPlanProfileError)),
      );
      return false;
    }
  }

  if (profile == null) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(KiamiStrings.deviceBackupPlanProfileError)),
    );
    return false;
  }

  if (kiamiPlanIncludesDeviceBackup(profile.plan.code)) return true;
  if (!context.mounted) return false;

  await showSupportContactDialog(
    context,
    title: KiamiStrings.deviceBackupPlanRequiredTitle,
    body: KiamiStrings.deviceBackupPlanRequiredBody,
    whatsAppMessage: KiamiStrings.deviceBackupPlanSupportWhatsApp,
    emailSubject: KiamiStrings.planChangeSupportEmailSubject,
    emailBody: KiamiStrings.deviceBackupPlanSupportWhatsApp,
  );
  return false;
}
