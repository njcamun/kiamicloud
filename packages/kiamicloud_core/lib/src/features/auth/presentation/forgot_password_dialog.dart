import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/kiami_strings.dart';
import '../../../firebase/kiami_firebase.dart';
import '../data/auth_exception_messages.dart';
import '../providers/auth_providers.dart';

/// Diálogo de recuperação de palavra-passe.
Future<void> showForgotPasswordDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _ForgotPasswordDialog(),
  );
}

class _ForgotPasswordDialog extends ConsumerStatefulWidget {
  const _ForgotPasswordDialog();

  @override
  ConsumerState<_ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<_ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Introduza o e-mail.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(email: email);
      setState(() => _sent = true);
    } catch (e) {
      setState(() => _error = AuthExceptionMessages.fromObject(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(KiamiStrings.forgotPasswordTitle),
      content: _sent
          ? Text(KiamiStrings.forgotPasswordSent)
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!KiamiFirebase.isConfigured)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      KiamiStrings.firebaseNotConfigured,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: KiamiStrings.emailLabel,
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_loading,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text(_sent ? KiamiStrings.closeButton : KiamiStrings.cancelButton),
        ),
        if (!_sent)
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(KiamiStrings.sendButton),
          ),
      ],
    );
  }
}
