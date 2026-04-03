class ArtikelFoto {
  final String id;
  final String userId;
  final String artikelId;
  final String storagePath;
  final String dateiName;
  final int sortierung;
  final bool istHauptbild;
  final DateTime? createdAt;

  ArtikelFoto({
    required this.id,
    required this.userId,
    required this.artikelId,
    required this.storagePath,
    required this.dateiName,
    this.sortierung = 0,
    this.istHauptbild = false,
    this.createdAt,
  });

  factory ArtikelFoto.fromJson(Map<String, dynamic> json) {
    return ArtikelFoto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      artikelId: json['artikel_id'] as String,
      storagePath: json['storage_path'] as String,
      dateiName: json['datei_name'] as String,
      sortierung: json['sortierung'] as int? ?? 0,
      istHauptbild: json['ist_hauptbild'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'artikel_id': artikelId,
      'storage_path': storagePath,
      'datei_name': dateiName,
      'sortierung': sortierung,
      'ist_hauptbild': istHauptbild,
    };
  }
}
