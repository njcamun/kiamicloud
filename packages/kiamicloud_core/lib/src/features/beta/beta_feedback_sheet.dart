import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/kiami_api_config.dart';
import '../../config/kiami_environment.dart';
import '../../constants/kiami_strings.dart';
import '../activity/providers/account_activity_providers.dart';
import '../../features/files/providers/files_providers.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;

class BetaFeedbackSheet extends ConsumerStatefulWidget {
  const BetaFeedbackSheet({super.key});

  @override
  ConsumerState<BetaFeedbackSheet> createState() => _BetaFeedbackSheetState();
}

class _BetaFeedbackSheetState extends ConsumerState<BetaFeedbackSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  String get _platformLabel {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.length < 5) return;
    setState(() => _sending = true);
    try {
      await ref.read(kiamiApiClientProvider).sendBetaFeedback(
            message: text,
            appVersion: KiamiEnvironment.appVersion,
            platform: _platformLabel,
            apiBaseUrl: KiamiApiConfig.baseUrl,
          );
      if (!mounted) return;
      ref.invalidate(accountActivityProvider);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(KiamiStrings.betaFeedbackThanks)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kiamiApiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.paddingOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            KiamiStrings.betaFeedbackTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            KiamiStrings.betaFeedbackHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: KiamiStrings.betaFeedbackPlaceholder,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _sending ? null : _submit,
            child: _sending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(KiamiStrings.betaFeedbackSend),
          ),
        ],
      ),
    );
  }
}
