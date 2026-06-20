import 'dart:ui';

import 'package:flutter/material.dart';

import '../api/kiami_api_exception.dart';
import '../assets/kiami_assets.dart';
import '../constants/kiami_strings.dart';
import '../theme/kiami_decorations.dart';

/// Problema de ligação (internet / cloud).
bool kiamiErrorIsConnectionIssue(Object error) {
  return error is KiamiApiException && error.errorCode == 'connection_failed';
}

/// Pré-visualização / reprodução — inclui falhas de rede sem código HTTP.
bool kiamiPreviewConnectionIssue(Object error) {
  if (kiamiErrorIsConnectionIssue(error)) return true;
  return error is KiamiApiException && error.statusCode == null;
}

double kiamiIllustrationWidth(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width <= 0) return 240;
  return (width * 0.55).clamp(180.0, 320.0);
}

/// Ilustração para problemas de ligação (NoConnect.png).
class KiamiNoConnectIllustration extends StatelessWidget {
  const KiamiNoConnectIllustration({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      KiamiAssets.noConnectPng,
      package: KiamiAssets.package,
      width: width,
      height: height,
      fit: fit,
      semanticLabel: KiamiStrings.noConnectTitle,
      alignment: Alignment.center,
    );
  }
}

/// Card com apenas NoConnect — padrão dashboard/admin sem ligação.
class KiamiNoConnectCard extends StatelessWidget {
  const KiamiNoConnectCard({
    super.key,
    this.height = 168,
    this.compact = false,
  });

  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cardHeight = compact ? 120.0 : height;

    return ClipRRect(
      borderRadius: BorderRadius.circular(KiamiDecorations.radiusLg),
      child: SizedBox(
        width: double.infinity,
        height: cardHeight,
        child: const KiamiNoConnectIllustration(fit: BoxFit.cover),
      ),
    );
  }
}

/// Ilustração quando a ligação ao servidor foi confirmada (Connect.png).
class KiamiConnectIllustration extends StatelessWidget {
  const KiamiConnectIllustration({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      KiamiAssets.connectPng,
      package: KiamiAssets.package,
      width: width,
      height: height,
      fit: fit,
      semanticLabel: KiamiStrings.connectTitle,
      alignment: Alignment.center,
    );
  }
}

/// Card com apenas Connect — teste de servidor bem-sucedido.
class KiamiConnectCard extends StatelessWidget {
  const KiamiConnectCard({
    super.key,
    this.height = 168,
    this.compact = false,
  });

  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cardHeight = compact ? 120.0 : height;

    return ClipRRect(
      borderRadius: BorderRadius.circular(KiamiDecorations.radiusLg),
      child: SizedBox(
        width: double.infinity,
        height: cardHeight,
        child: const KiamiConnectIllustration(fit: BoxFit.cover),
      ),
    );
  }
}

/// Card com apenas unavailable — erros de API com rede OK.
class KiamiUnavailableCard extends StatelessWidget {
  const KiamiUnavailableCard({
    super.key,
    this.height = 168,
    this.compact = false,
  });

  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cardHeight = compact ? 120.0 : height;

    return ClipRRect(
      borderRadius: BorderRadius.circular(KiamiDecorations.radiusLg),
      child: SizedBox(
        width: double.infinity,
        height: cardHeight,
        child: const KiamiUnavailableIllustration(fit: BoxFit.cover),
      ),
    );
  }
}

/// Ilustração quando um ficheiro específico não está acessível (unavailable.png).
class KiamiUnavailableIllustration extends StatelessWidget {
  const KiamiUnavailableIllustration({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      KiamiAssets.unavailablePng,
      package: KiamiAssets.package,
      width: width,
      height: height,
      fit: fit,
      semanticLabel: KiamiStrings.fileUnavailableTitle,
    );
  }
}

double kiamiPreviewIssueImageWidth(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width <= 0) return 320;
  return width * 0.9;
}

double kiamiPreviewIssueImageHeight(BuildContext context) {
  final height = MediaQuery.sizeOf(context).height;
  if (height <= 0) return 420;
  return height * 0.68;
}

/// Overlay de pré-visualização — bloqueia o fundo e mostra ilustração grande.
class KiamiPreviewIssueOverlay extends StatelessWidget {
  const KiamiPreviewIssueOverlay({
    super.key,
    required this.connectionError,
    this.onDismiss,
    this.barrierDismissible = true,
  });

  final bool connectionError;
  final VoidCallback? onDismiss;
  final bool barrierDismissible;

  @override
  Widget build(BuildContext context) {
    void dismiss() {
      if (onDismiss != null) {
        onDismiss!();
      } else if (barrierDismissible) {
        Navigator.maybePop(context);
      }
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: ModalBarrier(
              dismissible: barrierDismissible,
              onDismiss: barrierDismissible ? dismiss : null,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: SizedBox(
                width: kiamiPreviewIssueImageWidth(context),
                height: kiamiPreviewIssueImageHeight(context),
                child: connectionError
                    ? const KiamiNoConnectIllustration(fit: BoxFit.contain)
                    : const KiamiUnavailableIllustration(fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Apenas a imagem NoConnect centrada.
class KiamiNoConnectScreen extends StatelessWidget {
  const KiamiNoConnectScreen({super.key, this.imageWidth});

  final double? imageWidth;

  @override
  Widget build(BuildContext context) {
    final width = imageWidth ?? kiamiIllustrationWidth(context);
    return Center(
      child: KiamiNoConnectIllustration(width: width),
    );
  }
}

/// Apenas a imagem unavailable centrada.
class KiamiFileUnavailableScreen extends StatelessWidget {
  const KiamiFileUnavailableScreen({super.key, this.imageWidth});

  final double? imageWidth;

  @override
  Widget build(BuildContext context) {
    final width = imageWidth ?? kiamiIllustrationWidth(context);
    return Center(
      child: KiamiUnavailableIllustration(width: width),
    );
  }
}

/// SnackBar com NoConnect — falhas de ligação.
class KiamiNoConnectSnackContent extends StatelessWidget {
  const KiamiNoConnectSnackContent({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const KiamiNoConnectIllustration(width: 48, height: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  height: 1.35,
                ),
          ),
        ),
      ],
    );
  }
}

/// SnackBar com unavailable — ficheiro inacessível com rede OK.
class KiamiUnavailableSnackContent extends StatelessWidget {
  const KiamiUnavailableSnackContent({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const KiamiUnavailableIllustration(width: 48, height: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  height: 1.35,
                ),
          ),
        ),
      ],
    );
  }
}

/// Diálogo minimalista — apenas NoConnect (ex.: upload sem rede).
Future<void> showKiamiNoConnectDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: KiamiNoConnectScreen(
          imageWidth: kiamiIllustrationWidth(ctx),
        ),
      ),
    ),
  );
}

@Deprecated('Use showKiamiNoConnectDialog')
Future<void> showKiamiUnavailableDialog(
  BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onRetry,
}) =>
    showKiamiNoConnectDialog(context);
