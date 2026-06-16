class KiamiPaymentInstructions {
  const KiamiPaymentInstructions({
    required this.holderName,
    required this.iban,
    required this.mbWay,
    required this.note,
    required this.reviewSlaHours,
  });

  final String holderName;
  final String iban;
  final String mbWay;
  final String note;
  final int reviewSlaHours;

  factory KiamiPaymentInstructions.fromJson(Map<String, dynamic> json) {
    return KiamiPaymentInstructions(
      holderName: json['holderName'] as String? ?? 'KiamiCloud',
      iban: json['iban'] as String? ?? '',
      mbWay: json['mbWay'] as String? ?? '',
      note: json['note'] as String? ?? '',
      reviewSlaHours: (json['reviewSlaHours'] as num?)?.toInt() ?? 6,
    );
  }
}
