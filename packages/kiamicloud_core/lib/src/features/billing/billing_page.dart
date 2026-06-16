import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/kiami_billing_status.dart';
import '../../api/models/kiami_checkout.dart';
import '../../api/models/kiami_payment_instructions.dart';
import '../../api/models/kiami_plan.dart';
import '../../config/kiami_environment.dart';
import '../../constants/kiami_strings.dart';
import '../../routing/kiami_routes.dart';
import '../../theme/kiami_colors.dart';
import '../../utils/format_bytes.dart';
import '../../utils/kiami_layout.dart';
import '../../utils/quota_ui.dart';
import '../../utils/upload_file_reader.dart';
import '../../widgets/kiami_api_unavailable_card.dart';
import '../../widgets/kiami_button.dart';
import '../../widgets/kiami_card.dart';
import '../files/providers/files_providers.dart';
import '../activity/providers/account_activity_providers.dart';
import 'providers/billing_providers.dart';

class BillingPage extends ConsumerStatefulWidget {
  const BillingPage({super.key});

  @override
  ConsumerState<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends ConsumerState<BillingPage> {
  static const int _proofMaxBytes = 5 * 1024 * 1024;

  String? _busyPlanCode;
  bool _submittingProof = false;

  Future<void> _upgrade(KiamiPlan plan) async {
    setState(() => _busyPlanCode = plan.code);
    try {
      final api = ref.read(kiamiApiClientProvider);
      final result = await api.createCheckout(plan.code);
      if (!mounted) return;
      if (result.immediate) {
        ref.invalidate(billingStatusProvider);
        ref.invalidate(accountActivityProvider);
        ref.invalidate(kiamiProfileProvider);
        ref.invalidate(kiamiFilesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(KiamiStrings.billingPlanActivated),
            action: SnackBarAction(
              label: KiamiStrings.billingUpgradeSuccessAction,
              onPressed: () => context.go(KiamiRoutes.home),
            ),
          ),
        );
        return;
      }
      ref.invalidate(billingStatusProvider);
      ref.invalidate(accountActivityProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(KiamiStrings.billingCheckoutCreated)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kiamiApiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busyPlanCode = null);
    }
  }

  Future<void> _submitProof(KiamiCheckout checkout) async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
        withData: false,
        withReadStream: true,
      );
      if (!mounted) return;
      if (picked == null || picked.files.isEmpty) return;

      setState(() => _submittingProof = true);

      final file = picked.files.single;
      if (file.size > _proofMaxBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(KiamiStrings.billingProofTooLarge)),
        );
        return;
      }

      final bytes = await readPlatformFileBytes(
        file,
        maxBytes: _proofMaxBytes,
      );
      if (!mounted) return;
      if (bytes == null || bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(KiamiStrings.uploadNoBytes)),
        );
        return;
      }

      final mimeType = _mimeTypeForProof(file.name);
      if (mimeType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(KiamiStrings.billingProofHint)),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(KiamiStrings.billingProofUploading)),
      );

      final api = ref.read(kiamiApiClientProvider);
      await api.submitCheckoutProof(
        checkoutId: checkout.id,
        bytes: bytes,
        mimeType: mimeType,
      );
      ref.invalidate(billingStatusProvider);
      ref.invalidate(accountActivityProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(KiamiStrings.billingProofSubmitted)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kiamiApiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submittingProof = false);
    }
  }

  Future<void> _simulatePay(KiamiCheckout checkout) async {
    setState(() => _busyPlanCode = 'simulate');
    try {
      final api = ref.read(kiamiApiClientProvider);
      await api.simulateCheckoutPayment(checkout.id);
      ref.invalidate(billingStatusProvider);
      ref.invalidate(accountActivityProvider);
      ref.invalidate(kiamiProfileProvider);
      ref.invalidate(kiamiFilesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(KiamiStrings.billingPlanActivated),
          action: SnackBarAction(
            label: KiamiStrings.billingUpgradeSuccessAction,
            onPressed: () => context.go(KiamiRoutes.home),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kiamiApiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busyPlanCode = null);
    }
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingAsync = ref.watch(billingStatusProvider);
    final plansAsync = ref.watch(upgradePlansProvider);
    final showDevSimulate = KiamiEnvironment.isDevelopment;

    return Scaffold(
      appBar: AppBar(title: const Text(KiamiStrings.billingTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(billingStatusProvider);
      ref.invalidate(accountActivityProvider);
          ref.invalidate(upgradePlansProvider);
          await ref.read(billingStatusProvider.future);
        },
        child: ListView(
          padding: kiamiScrollPadding(
            context,
            left: kiamiSettingsListHorizontalPadding,
            top: 20,
            right: kiamiSettingsListHorizontalPadding,
            bottomExtra: 24,
          ),
          children: [
            billingAsync.when(
              data: (b) => _CurrentPlanCard(
                key: ValueKey(b.plan.code),
                status: b,
                listHorizontalPadding: kiamiSettingsListHorizontalPadding,
              ),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => KiamiApiUnavailableCard(
                error: e,
                compact: true,
                onRetry: () => ref.invalidate(billingStatusProvider),
              ),
            ),
            billingAsync.maybeWhen(
              data: (b) {
                final active = b.activeCheckout;
                if (active == null) return const SizedBox.shrink();
                final planName = _planDisplayName(active.planCode, plansAsync);
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    _ActiveCheckoutCard(
                      checkout: active,
                      planName: planName,
                      instructions: b.paymentInstructions,
                      submittingProof: _submittingProof,
                      simulateBusy: _busyPlanCode == 'simulate',
                      showDevSimulate: showDevSimulate,
                      onCopyRef: () => _copy(
                        KiamiStrings.billingRefCopied,
                        active.reference,
                      ),
                      onCopyIban: () => _copy(
                        KiamiStrings.billingIbanCopied,
                        b.paymentInstructions.iban,
                      ),
                      onSubmitProof: () => _submitProof(active),
                      onSimulatePay: () => _simulatePay(active),
                    ),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            billingAsync.maybeWhen(
              data: (b) {
                if (b.recentRejectedCheckouts.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    ...b.recentRejectedCheckouts.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _RejectedCheckoutCard(
                          checkout: c,
                          planName: _planDisplayName(c.planCode, plansAsync),
                        ),
                      ),
                    ),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Text(
              KiamiStrings.billingUpgradeTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              KiamiStrings.billingUpgradeHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            plansAsync.when(
              data: (plans) => billingAsync.maybeWhen(
                data: (current) => Column(
                  children: plans.map((plan) {
                    final isCurrent = plan.code == current.plan.code;
                    final hasActiveCheckout = current.activeCheckout != null;
                    return _PlanTile(
                      plan: plan,
                      isCurrent: isCurrent,
                      enabled: !isCurrent &&
                          current.paymentsEnabled &&
                          !hasActiveCheckout,
                      loading: _busyPlanCode == plan.code,
                      onUpgrade: () => _upgrade(plan),
                    );
                  }).toList(),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => KiamiApiUnavailableCard(
                error: e,
                compact: true,
                onRetry: () {
                  ref.invalidate(upgradePlansProvider);
                  ref.invalidate(billingStatusProvider);
      ref.invalidate(accountActivityProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _planDisplayName(String planCode, AsyncValue<List<KiamiPlan>> plansAsync) {
  return plansAsync.maybeWhen(
    data: (plans) {
      for (final p in plans) {
        if (p.code == planCode) return p.name;
      }
      return planCode;
    },
    orElse: () => planCode,
  );
}

String? _mimeTypeForProof(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  return null;
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({
    super.key,
    required this.status,
    required this.listHorizontalPadding,
  });

  final KiamiBillingStatus status;
  final double listHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    final plan = status.plan;
    final used = status.storageUsedBytes;
    final quota = plan.quotaBytes;
    final fraction = quota > 0 ? (used / quota).clamp(0.0, 1.0) : 0.0;

    final card = KiamiCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              KiamiStrings.billingCurrentPlan,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              plan.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                color: QuotaUi.barColor(status.quota.status),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${formatBytes(used)} / ${formatBytes(quota)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (plan.priceKzMonth > 0) ...[
              const SizedBox(height: 6),
              Text(
                '${_formatKz(plan.priceKzMonth)}${KiamiStrings.billingPerMonth}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              const SizedBox(height: 6),
              Text(
                KiamiStrings.billingFreePlan,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      child: LayoutBuilder(
        key: ValueKey(plan.code),
        builder: (context, constraints) {
          final fullWidth = constraints.maxWidth + 2 * listHorizontalPadding;
          return Transform.translate(
            offset: Offset(-listHorizontalPadding, 0),
            child: SizedBox(
              width: fullWidth,
              child: card,
            ),
          );
        },
      ),
    );
  }
}

class _ActiveCheckoutCard extends StatelessWidget {
  const _ActiveCheckoutCard({
    required this.checkout,
    required this.planName,
    required this.instructions,
    required this.submittingProof,
    required this.simulateBusy,
    required this.showDevSimulate,
    required this.onCopyRef,
    required this.onCopyIban,
    required this.onSubmitProof,
    required this.onSimulatePay,
  });

  final KiamiCheckout checkout;
  final String planName;
  final KiamiPaymentInstructions instructions;
  final bool submittingProof;
  final bool simulateBusy;
  final bool showDevSimulate;
  final VoidCallback onCopyRef;
  final VoidCallback onCopyIban;
  final VoidCallback onSubmitProof;
  final VoidCallback onSimulatePay;

  @override
  Widget build(BuildContext context) {
    final awaiting = checkout.isAwaitingReview;
    final cardColor = awaiting
        ? KiamiColors.primaryBlue.withValues(alpha: 0.06)
        : KiamiColors.warning.withValues(alpha: 0.08);

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              awaiting
                  ? KiamiStrings.billingAwaitingReviewTitle
                  : KiamiStrings.billingPendingTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text('$planName · ${_formatKz(checkout.amountKz)}'),
            const SizedBox(height: 4),
            SelectableText(
              checkout.reference,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            if (awaiting) ...[
              const SizedBox(height: 10),
              Text(
                KiamiStrings.billingAwaitingReviewHint(instructions.reviewSlaHours),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              const SizedBox(height: 16),
              Text(
                KiamiStrings.billingPaymentInstructionsTitle,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              _InstructionRow(
                label: KiamiStrings.billingPaymentHolder,
                value: instructions.holderName,
              ),
              _InstructionRow(
                label: KiamiStrings.billingPaymentIban,
                value: instructions.iban,
                trailing: TextButton.icon(
                  onPressed: onCopyIban,
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  label: const Text(KiamiStrings.billingCopyIban),
                ),
              ),
              if (instructions.mbWay.isNotEmpty)
                _InstructionRow(
                  label: KiamiStrings.billingPaymentMbWay,
                  value: instructions.mbWay,
                ),
              if (instructions.note.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  instructions.note,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                KiamiStrings.billingPaymentSla(instructions.reviewSlaHours),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onCopyRef,
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: const Text(KiamiStrings.billingCopyRef),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                KiamiStrings.billingProofHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              KiamiButton(
                label: KiamiStrings.billingSubmitProof,
                icon: Icons.upload_file_outlined,
                expand: true,
                isLoading: submittingProof,
                onPressed: submittingProof ? null : onSubmitProof,
              ),
              if (showDevSimulate) ...[
                const SizedBox(height: 16),
                Text(
                  KiamiStrings.billingDevSimulateHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                KiamiButton(
                  label: KiamiStrings.billingSimulatePay,
                  icon: Icons.payment,
                  expand: true,
                  isLoading: simulateBusy,
                  onPressed: simulateBusy ? null : onSimulatePay,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  const _InstructionRow({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _RejectedCheckoutCard extends StatelessWidget {
  const _RejectedCheckoutCard({
    required this.checkout,
    required this.planName,
  });

  final KiamiCheckout checkout;
  final String planName;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              KiamiStrings.billingRejectedTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text('$planName · ${_formatKz(checkout.amountKz)}'),
            if (checkout.rejectionReason != null &&
                checkout.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${KiamiStrings.billingRejectedReason}: ${checkout.rejectionReason}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.isCurrent,
    required this.enabled,
    required this.loading,
    required this.onUpgrade,
  });

  final KiamiPlan plan;
  final bool isCurrent;
  final bool enabled;
  final bool loading;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(plan.name),
        subtitle: Text(
          _planSubtitle(plan),
        ),
        trailing: isCurrent
            ? Chip(
                label: const Text(KiamiStrings.billingCurrentBadge),
                backgroundColor: KiamiColors.primaryBlue.withValues(alpha: 0.12),
              )
            : FilledButton(
                onPressed: enabled && !loading ? onUpgrade : null,
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(KiamiStrings.billingUpgradeButton),
              ),
      ),
    );
  }
}

String _planSubtitle(KiamiPlan plan) {
  final storage = formatBytes(plan.quotaBytes);
  final transfer = formatBytes(plan.maxFileSizeBytes);
  final price = _formatKz(plan.priceKzMonth);
  final list = plan.listPriceKzMonth;
  if (list > plan.priceKzMonth) {
    return '$storage · até $transfer/ficheiro\n'
        '$price${KiamiStrings.billingPerMonth} '
        '(tabela ${_formatKz(list)} · −15%)';
  }
  return '$storage · até $transfer/ficheiro · $price${KiamiStrings.billingPerMonth}';
}

String _formatKz(int amount) {
  final s = amount.toString();
  if (s.length <= 3) return '$s Kz';
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '${buf.toString()} Kz';
}
