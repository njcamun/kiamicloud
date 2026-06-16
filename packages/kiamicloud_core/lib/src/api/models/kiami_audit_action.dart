class KiamiAuditAction {
  const KiamiAuditAction({
    required this.id,
    required this.action,
    this.fileId,
    this.metadata,
    required this.createdAt,
  });

  final int id;
  final String action;
  final String? fileId;
  final Map<String, dynamic>? metadata;
  final String createdAt;

  factory KiamiAuditAction.fromJson(Map<String, dynamic> json) {
    final meta = json['metadata'];
    return KiamiAuditAction(
      id: (json['id'] as num).toInt(),
      action: json['action'] as String,
      fileId: json['fileId'] as String?,
      metadata: meta is Map<String, dynamic> ? meta : null,
      createdAt: json['createdAt'] as String,
    );
  }

  String get actionLabel => switch (action) {
        'upload' => 'Envio',
        'download' => 'Download',
        'rename' => 'Renomear',
        'delete' => 'Apagar',
        'restore' => 'Restaurar',
        _ => action,
      };
}
