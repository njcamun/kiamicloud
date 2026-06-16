class FileThumbnailUrl {
  const FileThumbnailUrl({
    required this.url,
    required this.localDev,
    this.headers = const {},
    this.expiresAt,
  });

  final String url;
  final bool localDev;
  final Map<String, String> headers;
  final DateTime? expiresAt;

  bool get isExpired {
    final at = expiresAt;
    if (at == null) return false;
    return DateTime.now().isAfter(at.subtract(const Duration(seconds: 30)));
  }
}
