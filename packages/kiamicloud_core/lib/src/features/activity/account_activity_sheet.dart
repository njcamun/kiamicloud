import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/kiami_strings.dart';
import '../files/providers/files_providers.dart';
import 'providers/account_activity_providers.dart';
import 'widgets/account_notifications_panel.dart';

/// Bottom sheet legado — preferir [showAccountNotificationsPopup].
class AccountActivitySheet extends ConsumerStatefulWidget {
  const AccountActivitySheet({super.key});

  @override
  ConsumerState<AccountActivitySheet> createState() =>
      _AccountActivitySheetState();
}

class _AccountActivitySheetState extends ConsumerState<AccountActivitySheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshKiamiProfile(ref);
      ref.invalidate(accountActivityProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  KiamiStrings.notificationsTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            KiamiStrings.notificationsHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          const Flexible(
            child: AccountNotificationsPanel(),
          ),
        ],
      ),
    );
  }
}
