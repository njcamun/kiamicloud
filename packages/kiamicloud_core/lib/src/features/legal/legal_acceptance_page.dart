import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/kiami_strings.dart';
import '../../routing/kiami_routes.dart';
import '../../theme/kiami_decorations.dart';
import '../../widgets/kiami_button.dart';
import '../../widgets/kiami_card.dart';
import '../../widgets/kiami_logo_bar.dart';
import '../auth/providers/auth_providers.dart';
import 'legal_pdf_viewer_page.dart';
import 'providers/legal_acceptance_providers.dart';

/// Ecrã obrigatório no primeiro acesso — leitura e aceitação dos termos legais.
class LegalAcceptancePage extends ConsumerStatefulWidget {
  const LegalAcceptancePage({super.key});

  @override
  ConsumerState<LegalAcceptancePage> createState() =>
      _LegalAcceptancePageState();
}

class _LegalAcceptancePageState extends ConsumerState<LegalAcceptancePage> {
  bool _documentOpened = false;
  bool _agreed = false;
  bool _saving = false;

  Future<void> _openDocument() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const LegalPdfViewerPage(
          title: KiamiStrings.legalDocumentTitle,
        ),
      ),
    );
    if (mounted) setState(() => _documentOpened = true);
  }

  Future<void> _accept() async {
    if (!_documentOpened || !_agreed || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(legalAcceptanceGateProvider.notifier).acceptForCurrentUser();
      if (!mounted) return;
      context.go(KiamiRoutes.home);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    context.go(KiamiRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _documentOpened && _agreed && !_saving;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: KiamiDecorations.authBackgroundFor(
            Theme.of(context).brightness,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: KiamiCard(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: KiamiLogoBar(height: 56)),
                      const SizedBox(height: 24),
                      Text(
                        KiamiStrings.legalAcceptanceTitle,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        KiamiStrings.legalAcceptanceBody,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: _openDocument,
                        icon: Icon(
                          _documentOpened
                              ? Icons.check_circle_outline
                              : Icons.menu_book_outlined,
                        ),
                        label: Text(
                          _documentOpened
                              ? KiamiStrings.legalAcceptanceReadAgain
                              : KiamiStrings.legalAcceptanceReadButton,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _agreed,
                        onChanged: _documentOpened
                            ? (v) => setState(() => _agreed = v ?? false)
                            : null,
                        title: Text(
                          KiamiStrings.legalAcceptanceCheckbox,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (!_documentOpened)
                        Text(
                          KiamiStrings.legalAcceptanceOpenFirst,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      const SizedBox(height: 20),
                      KiamiButton(
                        label: KiamiStrings.legalAcceptanceContinue,
                        icon: Icons.check_rounded,
                        isLoading: _saving,
                        onPressed: canContinue ? _accept : null,
                      ),
                      TextButton(
                        onPressed: _saving ? null : _signOut,
                        child: const Text(KiamiStrings.settingsLogout),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
