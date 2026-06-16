class KiamiCheckout {
  const KiamiCheckout({
    required this.id,
    required this.planCode,
    required this.amountKz,
    required this.reference,
    required this.status,
    required this.provider,
    required this.expiresAt,
    this.paidAt,
    this.proofSubmittedAt,
    this.rejectionReason,
    this.rejectedAt,
    this.hasProof = false,
    required this.createdAt,
  });

  final String id;
  final String planCode;
  final int amountKz;
  final String reference;
  final String status;
  final String provider;
  final String expiresAt;
  final String? paidAt;
  final String? proofSubmittedAt;
  final String? rejectionReason;
  final String? rejectedAt;
  final bool hasProof;
  final String createdAt;

  bool get isPending => status == 'pending';
  bool get isAwaitingReview => status == 'awaiting_review';
  bool get isPaid => status == 'paid';
  bool get isRejected => status == 'rejected';
  bool get isActive => isPending || isAwaitingReview;

  factory KiamiCheckout.fromJson(Map<String, dynamic> json) {
    return KiamiCheckout(
      id: json['id'] as String,
      planCode: json['planCode'] as String,
      amountKz: (json['amountKz'] as num).toInt(),
      reference: json['reference'] as String,
      status: json['status'] as String,
      provider: json['provider'] as String? ?? 'manual',
      expiresAt: json['expiresAt'] as String,
      paidAt: json['paidAt'] as String?,
      proofSubmittedAt: json['proofSubmittedAt'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      rejectedAt: json['rejectedAt'] as String?,
      hasProof: json['hasProof'] as bool? ?? false,
      createdAt: json['createdAt'] as String,
    );
  }
}
