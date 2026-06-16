import 'package:url_launcher/url_launcher.dart';

import '../constants/kiami_constants.dart';
import '../constants/kiami_strings.dart';

/// Abre o WhatsApp de suporte (wa.me). Devolve false se o número não estiver configurado.
Future<bool> launchSupportWhatsApp({String? message}) async {
  final digits = KiamiConstants.supportWhatsAppDigits;
  if (digits.isEmpty) return false;

  final text = Uri.encodeComponent(
    message ?? KiamiStrings.supportWhatsAppDefaultMessage,
  );
  final uri = Uri.parse('https://wa.me/$digits?text=$text');
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

bool get isSupportWhatsAppConfigured =>
    KiamiConstants.supportWhatsAppDigits.isNotEmpty;
