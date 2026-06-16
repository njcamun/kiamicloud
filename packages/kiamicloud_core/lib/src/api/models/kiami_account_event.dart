class KiamiAccountEvent {
  const KiamiAccountEvent({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.metadata,
    this.readAt,
    required this.createdAt,
    required this.isNotification,
    required this.isUnread,
    this.firebaseUid,
    this.userEmail,
    this.userDisplayName,
  });

  final int id;
  final String kind;
  final String title;
  final String body;
  final Map<String, dynamic>? metadata;
  final String? readAt;
  final String createdAt;
  final bool isNotification;
  final bool isUnread;
  final String? firebaseUid;
  final String? userEmail;
  final String? userDisplayName;

  bool get isBilling => kind.startsWith('billing_');
  bool get isSupport => kind.startsWith('support_');

  factory KiamiAccountEvent.fromJson(Map<String, dynamic> json) {
    final meta = json['metadata'];
    return KiamiAccountEvent(
      id: (json['id'] as num).toInt(),
      kind: json['kind'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      metadata: meta is Map<String, dynamic> ? meta : null,
      readAt: json['readAt'] as String?,
      createdAt: json['createdAt'] as String,
      isNotification: json['isNotification'] as bool? ?? false,
      isUnread: json['isUnread'] as bool? ?? false,
      firebaseUid: json['firebaseUid'] as String?,
      userEmail: json['userEmail'] as String?,
      userDisplayName: json['userDisplayName'] as String?,
    );
  }

  String get kindLabel => switch (kind) {
        'billing_checkout_created' => 'Pedido de upgrade',
        'billing_proof_submitted' => 'Comprovativo',
        'billing_paid' => 'Plano activado',
        'billing_rejected' => 'Pagamento rejeitado',
        'support_sent' => 'Suporte',
        'support_reviewed' => 'Suporte tratado',
        'quota_updated' => 'Limites actualizados',
        _ => kind,
      };
}

class KiamiAccountActivity {
  const KiamiAccountActivity({
    required this.events,
    required this.unreadCount,
  });

  final List<KiamiAccountEvent> events;
  final int unreadCount;
}
