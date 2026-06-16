class KiamiPlan {
  const KiamiPlan({
    required this.code,
    required this.name,
    required this.quotaBytes,
    required this.priceKzMonth,
    required this.maxFileSizeBytes,
  });

  final String code;
  final String name;
  final int quotaBytes;
  final int priceKzMonth;
  final int maxFileSizeBytes;

  /// Preço de tabela antes do desconto de 15% (cobrado ÷ 0,85).
  int get listPriceKzMonth {
    if (priceKzMonth <= 0) return 0;
    return (priceKzMonth / 0.85).round();
  }

  factory KiamiPlan.fromJson(Map<String, dynamic> json) {
    return KiamiPlan(
      code: json['code'] as String,
      name: json['name'] as String,
      quotaBytes: (json['quotaBytes'] as num).toInt(),
      priceKzMonth: (json['priceKzMonth'] as num).toInt(),
      maxFileSizeBytes: (json['maxFileSizeBytes'] as num?)?.toInt() ??
          _legacyMaxFileBytes((json['code'] as String?) ?? ''),
    );
  }

  static int _legacyMaxFileBytes(String code) {
    return switch (code) {
      'basico' || 'free' => 15 * 1024 * 1024,
      'basico_plus' => 75 * 1024 * 1024,
      _ => 150 * 1024 * 1024,
    };
  }
}