import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/kiami_strings.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/files/providers/files_providers.dart';

/// Aviso quando o e-mail Firebase ainda não foi confirmado (bloqueia /files na API).
class EmailVerificationBanner extends ConsumerStatefulWidget {
  const EmailVerificationBanner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends ConsumerState<EmailVerificationBanner> {
  bool _busy = false;

  Future<void> _resend() async {
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(KiamiStrings.emailVerificationSent)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kiamiApiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).reloadCurrentUser();
      refreshKiamiProfile(ref);
      ref.invalidate(kiamiFilesProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(kiamiProfileProvider).valueOrNull;
    if (profile == null || profile.emailVerified) {
      return widget.child;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MaterialBanner(
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          content: Text(
            KiamiStrings.emailVerificationRequired,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _busy ? null : _refresh,
              child: const Text(KiamiStrings.emailVerificationRefresh),
            ),
            TextButton(
              onPressed: _busy ? null : _resend,
              child: const Text(KiamiStrings.emailVerificationResend),
            ),
          ],
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
