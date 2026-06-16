import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/kiami_api_config.dart';
import '../../constants/kiami_strings.dart';
import '../../routing/kiami_routes.dart';
import '../../utils/format_date.dart';
import '../../utils/kiami_layout.dart';
import '../../widgets/kiami_card.dart';
import '../../widgets/kiami_page_header.dart';
import '../files/providers/files_providers.dart';
import 'shares_providers.dart';

class SharesPage extends ConsumerWidget {
  const SharesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharesAsync = ref.watch(fileSharesProvider);
    final showBack = kiamiShowsShellBackButton(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KiamiPageHeader(
          title: KiamiStrings.sharesTitle,
          leading: showBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.go(KiamiRoutes.home),
                )
              : null,
        ),
        Expanded(
          child: sharesAsync.when(
            data: (shares) {
              if (shares.isEmpty) {
                return Center(
                  child: Text(
                    KiamiStrings.sharesEmpty,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(fileSharesProvider);
                  await ref.read(fileSharesProvider.future);
                },
                child: ListView(
                  padding: kiamiScrollPadding(context, left: 20, right: 20),
                  children: [
                    for (final share in shares)
                      KiamiCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(
                            share.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${share.active ? KiamiStrings.sharesActive : KiamiStrings.sharesExpired}'
                            ' · ${formatFileDate(share.expiresAt)}'
                            ' · ${share.accessCount} ${KiamiStrings.sharesAccessCount}',
                          ),
                          trailing: share.active
                              ? IconButton(
                                  tooltip: KiamiStrings.sharesRevoke,
                                  icon: const Icon(Icons.link_off_outlined),
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(kiamiApiClientProvider)
                                          .revokeFileShare(share.id);
                                      ref.invalidate(fileSharesProvider);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              KiamiStrings.sharesRevoked,
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              kiamiApiErrorMessage(e),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                )
                              : null,
                          onTap: share.active
                              ? () async {
                                  final url =
                                      '${KiamiApiConfig.baseUrl}/public/share/${share.token}';
                                  await Clipboard.setData(
                                    ClipboardData(text: url),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          KiamiStrings.fileShareCreated,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              : null,
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(kiamiApiErrorMessage(e))),
          ),
        ),
      ],
    );
  }
}
