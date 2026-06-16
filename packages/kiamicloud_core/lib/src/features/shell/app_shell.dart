import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/kiami_constants.dart';
import '../activity/providers/account_activity_providers.dart';
import '../activity/providers/profile_quota_sync_provider.dart';
import '../files/providers/files_providers.dart';
import '../../widgets/beta_banner.dart';
import '../../widgets/kiami_sidebar.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/upload_completion_listener.dart';

/// Shell responsivo: sidebar navy (desktop) / conteudo integral (mobile).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(offlineMutationSyncProvider);
    ref.watch(profileQuotaSyncProvider);
    ref.watch(accountActivityProvider);

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= KiamiConstants.breakpointTablet;

    if (isDesktop) {
      return UploadCompletionListener(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Row(
            children: [
              KiamiSidebar(),
              Expanded(
                child: BetaBanner(
                  child: OfflineBanner(
                    child: ColoredBox(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return UploadCompletionListener(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: BetaBanner(child: OfflineBanner(child: child)),
      ),
    );
  }
}
