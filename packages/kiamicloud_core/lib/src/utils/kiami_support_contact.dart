import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/kiami_constants.dart';
import '../constants/kiami_strings.dart';
import 'kiami_support_whatsapp.dart';

export 'kiami_support_whatsapp.dart' show launchSupportWhatsApp, isSupportWhatsAppConfigured;

/// Abre o cliente de e-mail para o suporte KiamiCloud.
Future<bool> launchSupportEmail({
  String? subject,
  String? body,
}) async {
  final params = <String, String>{};
  if (subject != null && subject.isNotEmpty) {
    params['subject'] = subject;
  }
  if (body != null && body.isNotEmpty) {
    params['body'] = body;
  }
  final uri = Uri(
    scheme: 'mailto',
    path: KiamiConstants.supportEmail,
    queryParameters: params.isEmpty ? null : params,
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Diálogo: WhatsApp ou e-mail.
Future<void> showSupportContactDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.support_agent_outlined,
            color: Theme.of(ctx).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text(KiamiStrings.supportContactTitle)),
        ],
      ),
      content: Text(
        KiamiStrings.supportContactBody,
        style: Theme.of(ctx).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(KiamiStrings.closeButton),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            Navigator.pop(ctx);
            if (!isSupportWhatsAppConfigured) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(KiamiStrings.supportWhatsAppUnavailable),
                ),
              );
              return;
            }
            final ok = await launchSupportWhatsApp();
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(KiamiStrings.supportWhatsAppUnavailable),
                ),
              );
            }
          },
          icon: const Icon(Icons.chat_outlined, size: 20),
          label: const Text(KiamiStrings.supportContactWhatsApp),
        ),
        FilledButton.icon(
          onPressed: () async {
            Navigator.pop(ctx);
            final ok = await launchSupportEmail(
              subject: KiamiStrings.supportEmailSubject,
              body: KiamiStrings.supportWhatsAppDefaultMessage,
            );
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(KiamiStrings.supportEmailUnavailable),
                ),
              );
            }
          },
          icon: const Icon(Icons.email_outlined, size: 20),
          label: const Text(KiamiStrings.supportContactEmail),
        ),
      ],
    ),
  );
}
