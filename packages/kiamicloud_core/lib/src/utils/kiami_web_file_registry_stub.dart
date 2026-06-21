/// Referência a ficheiro Web em memória (apenas Web usa implementação real).
bool isWebFileRegistryRef(String? ref) => false;

String registerWebFile(Object file) => '';

Future<List<int>?> readWebFileRegistryBytes(
  String ref, {
  required int maxBytes,
}) async =>
    null;

void discardWebFileRegistryRef(String ref) {}

void consumeWebFileRegistryRef(String ref) {}
