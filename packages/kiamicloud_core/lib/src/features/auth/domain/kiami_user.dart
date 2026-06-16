/// Utilizador autenticado (domínio — independente do Firebase).
class KiamiUser {
  const KiamiUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;

  String get initials {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    final mail = email?.trim();
    if (mail != null && mail.isNotEmpty) {
      return mail[0].toUpperCase();
    }
    return '?';
  }
}
