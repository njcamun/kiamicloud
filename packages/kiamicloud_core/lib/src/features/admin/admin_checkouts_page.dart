import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

import '../../api/models/kiami_admin.dart';
import '../../constants/kiami_strings.dart';
import '../../theme/kiami_colors.dart';
import '../../utils/kiami_layout.dart';
import '../activity/providers/account_activity_providers.dart';
import '../files/providers/files_providers.dart';
import 'providers/admin_providers.dart';

const _checkoutReviewStatus = 'awaiting_review';

class AdminCheckoutsPage extends ConsumerWidget {
  const AdminCheckoutsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutsAsync = ref.watch(adminCheckoutsProvider(_checkoutReviewStatus));

    return Scaffold(
      appBar: AppBar(
        title: const Text(KiamiStrings.adminCheckoutsTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminCheckoutsProvider(_checkoutReviewStatus));
          ref.invalidate(adminStatsProvider);
        },
        child: checkoutsAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text(KiamiStrings.adminCheckoutEmpty)),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: kiamiScrollPadding(context, left: 16, top: 12, right: 16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = items[i];
                return _CheckoutCard(checkout: c);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(kiamiApiErrorMessage(e), textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutCard extends ConsumerStatefulWidget {
  const _CheckoutCard({required this.checkout});

  final KiamiAdminCheckout checkout;

  @override
  ConsumerState<_CheckoutCard> createState() => _CheckoutCardState();
}

class _CheckoutCardState extends ConsumerState<_CheckoutCard> {
  bool _confirming = false;
  bool _rejecting = false;
  bool _loadingProof = false;

  Future<void> _confirm() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(KiamiStrings.adminCheckoutConfirm),
        content: Text(
          '${KiamiStrings.adminCheckoutReference}: ${widget.checkout.reference}\n'
          '${KiamiStrings.adminCheckoutAmount}: ${widget.checkout.amountKz} Kz',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(KiamiStrings.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(KiamiStrings.adminCheckoutConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _confirming = true);
    try {
      await ref
          .read(kiamiApiClientProvider)
          .confirmAdminCheckout(widget.checkout.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(KiamiStrings.adminCheckoutConfirmed)),
      );
      ref.invalidate(adminCheckoutsProvider(_checkoutReviewStatus));
      ref.invalidate(adminStatsProvider);
      ref.invalidate(adminAccountActivityProvider);
      ref.invalidate(adminUserAccountActivityProvider(widget.checkout.firebaseUid));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kiamiApiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _reject() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => const _RejectCheckoutDialog(),
    );
    if (reason == null || reason.length < 5 || !mounted) return;

    setState(() => _rejecting = true);
    try {
      await ref
          .read(kiamiApiClientProvider)
          .rejectAdminCheckout(widget.checkout.id, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(KiamiStrings.adminCheckoutRejected)),
      );
      ref.invalidate(adminCheckoutsProvider(_checkoutReviewStatus));
      ref.invalidate(adminStatsProvider);
      ref.invalidate(adminAccountActivityProvider);
      ref.invalidate(adminUserAccountActivityProvider(widget.checkout.firebaseUid));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kiamiApiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _rejecting = false);
    }
  }

  Future<void> _viewProof() async {
    setState(() => _loadingProof = true);
    try {
      final result = await ref
          .read(kiamiApiClientProvider)
          .fetchAdminCheckoutProof(widget.checkout.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => _ProofPreviewDialog(
          bytes: result.bytes,
          mimeType: result.mimeType,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kiamiApiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _loadingProof = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.checkout;
    final busy = _confirming || _rejecting;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.payment_outlined, color: KiamiColors.primaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.planCode,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  '${c.amountKz} Kz',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _Row(KiamiStrings.adminCheckoutReference, c.reference),
            if (c.userEmail != null && c.userEmail!.isNotEmpty)
              _Row(KiamiStrings.adminCheckoutEmail, c.userEmail!),
            _Row(KiamiStrings.adminCheckoutUser, c.firebaseUid),
            _Row(KiamiStrings.adminCheckoutDate, c.createdAt),
            if (c.proofSubmittedAt != null)
              _Row('Comprovativo', c.proofSubmittedAt!),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: c.hasProof && !_loadingProof ? _viewProof : null,
              icon: _loadingProof
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.receipt_long_outlined),
              label: Text(
                c.hasProof
                    ? KiamiStrings.adminCheckoutViewProof
                    : KiamiStrings.adminCheckoutNoProof,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : _reject,
                    child: _rejecting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(KiamiStrings.adminCheckoutReject),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: busy || !c.hasProof ? null : _confirm,
                    child: _confirming
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(KiamiStrings.adminCheckoutConfirm),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RejectCheckoutDialog extends StatefulWidget {
  const _RejectCheckoutDialog();

  @override
  State<_RejectCheckoutDialog> createState() => _RejectCheckoutDialogState();
}

class _RejectCheckoutDialogState extends State<_RejectCheckoutDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _controller.text.trim();
    if (reason.length < 5) return;
    Navigator.pop(context, reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(KiamiStrings.adminCheckoutRejectTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              KiamiStrings.adminCheckoutRejectHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ex.: valor incorrecto, referência ilegível…',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(KiamiStrings.cancelButton),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text(KiamiStrings.adminCheckoutReject),
        ),
      ],
    );
  }
}

class _ProofPreviewDialog extends StatefulWidget {
  const _ProofPreviewDialog({
    required this.bytes,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String mimeType;

  @override
  State<_ProofPreviewDialog> createState() => _ProofPreviewDialogState();
}

class _ProofPreviewDialogState extends State<_ProofPreviewDialog> {
  PdfControllerPinch? _pdfController;

  @override
  void initState() {
    super.initState();
    if (widget.mimeType == 'application/pdf') {
      _pdfController = PdfControllerPinch(
        document: PdfDocument.openData(widget.bytes),
      );
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(KiamiStrings.adminCheckoutProofTitle),
      content: SizedBox(
        width: 480,
        height: 520,
        child: _buildBody(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(KiamiStrings.closeButton),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (widget.mimeType.startsWith('image/')) {
      return Center(
        child: InteractiveViewer(
          child: Image.memory(widget.bytes, fit: BoxFit.contain),
        ),
      );
    }
    if (widget.mimeType == 'application/pdf' && _pdfController != null) {
      return PdfViewPinch(controller: _pdfController!);
    }
    return Center(
      child: Text(
        'Tipo não suportado: ${widget.mimeType}',
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
