/// Normaliza URL base da API local (dart-define no Windows pode truncar `http://...`).
String normalizeLocalApiBaseUrl({
  required String defaultUrl,
  String fromUrlDefine = '',
  String fromHostDefine = '',
}) {
  final host = fromHostDefine.trim();
  if (host.isNotEmpty) {
    final stripped = host
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'/+$'), '');
    if (_isValidHostPort(stripped)) {
      return 'http://$stripped';
    }
  }

  final raw = fromUrlDefine.trim();
  if (raw.isNotEmpty) {
    var url = raw;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    url = url.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(url);
    if (uri != null &&
        uri.host.isNotEmpty &&
        uri.host != 'http' &&
        uri.host != 'https') {
      return url;
    }
  }

  return defaultUrl.replaceAll(RegExp(r'/+$'), '');
}

bool _isValidHostPort(String hostPort) {
  if (hostPort.isEmpty || hostPort.contains(' ')) return false;
  final uri = Uri.tryParse('http://$hostPort');
  return uri != null && uri.host.isNotEmpty;
}

/// Constrói URL da API local a partir de IP ou host:porta.
String buildLocalApiUrlFromHost(String input, {int defaultPort = 8787}) {
  var trimmed = input.trim().replaceFirst(RegExp(r'^https?://'), '');
  trimmed = trimmed.replaceAll(RegExp(r'/+$'), '');
  if (trimmed.isEmpty) {
    throw ArgumentError('Endereço vazio');
  }
  if (!trimmed.contains(':')) {
    trimmed = '$trimmed:$defaultPort';
  }
  return normalizeLocalApiBaseUrl(
    defaultUrl: 'http://$trimmed',
    fromHostDefine: trimmed,
  );
}
