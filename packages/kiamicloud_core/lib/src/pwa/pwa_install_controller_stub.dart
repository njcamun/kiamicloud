import 'pwa_install_state.dart';

/// Controlador PWA (stub fora da Web).
abstract final class PwaInstallController {
  static PwaInstallState get initial => const PwaInstallState();

  static void attach(void Function(PwaInstallState) onChanged) {}

  static void detach() {}

  static Future<void> promptInstall() async {}

  static void dismiss() {}
}
