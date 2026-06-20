/// Álbum local de fotos (persistido no dispositivo).
class PhotoAlbum {
  const PhotoAlbum({
    required this.id,
    required this.name,
    required this.fileIds,
    required this.createdAt,
  });

  final String id;
  final String name;
  final List<String> fileIds;
  final String createdAt;

  PhotoAlbum copyWith({
    String? id,
    String? name,
    List<String>? fileIds,
    String? createdAt,
  }) {
    return PhotoAlbum(
      id: id ?? this.id,
      name: name ?? this.name,
      fileIds: fileIds ?? this.fileIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fileIds': fileIds,
        'createdAt': createdAt,
      };

  factory PhotoAlbum.fromJson(Map<String, dynamic> json) {
    return PhotoAlbum(
      id: json['id'] as String,
      name: json['name'] as String,
      fileIds: (json['fileIds'] as List<dynamic>).cast<String>(),
      createdAt: json['createdAt'] as String,
    );
  }
}
