import 'package:flutter/material.dart';

import '../constants/kiami_strings.dart';
import '../features/files/providers/files_providers.dart';
import 'kiami_button.dart';
import 'kiami_card.dart';

/// Estado amigável quando a API não responde (rede, servidor parado, etc.).
class KiamiApiUnavailableCard extends StatelessWidget {
  const KiamiApiUnavailableCard({
    super.key,
    required this.error,
    this.onRetry,
    this.compact = false,
  });

  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isConnection = kiamiApiErrorIsConnection(error);

    return KiamiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isConnection
                    ? Icons.cloud_off_outlined
                    : Icons.error_outline_rounded,
                color: scheme.error,
                size: compact ? 22 : 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnection
                          ? KiamiStrings.apiUnavailableTitle
                          : KiamiStrings.apiErrorTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      kiamiApiErrorMessage(error),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            SizedBox(height: compact ? 12 : 16),
            KiamiButton(
              label: KiamiStrings.apiUnavailableRetry,
              icon: Icons.refresh_rounded,
              expand: !compact,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
