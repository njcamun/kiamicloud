import 'package:flutter/material.dart';

import '../api/models/kiami_quota.dart';
import '../theme/kiami_colors.dart';

class QuotaUi {
  static Color barColor(QuotaStatus status) {
    return switch (status) {
      QuotaStatus.full => KiamiColors.error,
      QuotaStatus.critical => KiamiColors.error,
      QuotaStatus.warning => KiamiColors.warning,
      QuotaStatus.ok => KiamiColors.primaryBlue,
    };
  }

  static Color bannerBackground(QuotaStatus status) {
    return switch (status) {
      QuotaStatus.full => KiamiColors.error.withValues(alpha: 0.12),
      QuotaStatus.critical => KiamiColors.error.withValues(alpha: 0.1),
      QuotaStatus.warning => KiamiColors.warning.withValues(alpha: 0.15),
      QuotaStatus.ok => Colors.transparent,
    };
  }

  static Color bannerForeground(QuotaStatus status) {
    return switch (status) {
      QuotaStatus.full || QuotaStatus.critical => KiamiColors.error,
      QuotaStatus.warning => const Color(0xFFB45309),
      QuotaStatus.ok => KiamiColors.lightTextSecondary,
    };
  }

  static IconData bannerIcon(QuotaStatus status) {
    return switch (status) {
      QuotaStatus.full => Icons.block,
      QuotaStatus.critical => Icons.warning_amber_rounded,
      QuotaStatus.warning => Icons.info_outline,
      QuotaStatus.ok => Icons.check_circle_outline,
    };
  }

  static bool showBanner(QuotaStatus status) =>
      status != QuotaStatus.ok;
}
