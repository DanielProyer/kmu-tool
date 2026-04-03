class WebsiteGalleryImage {
  final String id;
  final String configId;
  final String storagePath;
  final String? dateiName;
  final String? beschreibung;
  final int sortierung;
  final DateTime? createdAt;

  WebsiteGalleryImage({
    required this.id,
    required this.configId,
    required this.storagePath,
    this.dateiName,
    this.beschreibung,
    this.sortierung = 0,
    this.createdAt,
  });

  factory WebsiteGalleryImage.fromJson(Map<String, dynamic> json) {
    return WebsiteGalleryImage(
      id: json['id'],
      configId: json['config_id'],
      storagePath: json['storage_path'],
      dateiName: json['datei_name'],
      beschreibung: json['beschreibung'],
      sortierung: json['sortierung'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'config_id': configId,
      'storage_path': storagePath,
      'datei_name': dateiName,
      'beschreibung': beschreibung,
      'sortierung': sortierung,
    };
  }
}
