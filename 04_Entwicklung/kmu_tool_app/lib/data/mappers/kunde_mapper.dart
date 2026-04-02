import 'package:kmu_tool_app/data/local/kunde_local_export.dart';
import 'package:kmu_tool_app/data/models/kunde.dart';

class KundeMapper {
  static KundeLocal fromDto(Kunde dto, {KundeLocal? existing}) {
    final local = existing ?? KundeLocal();
    local.serverId = dto.id;
    local.userId = dto.userId;
    local.firma = dto.firma;
    local.vorname = dto.vorname;
    local.nachname = dto.nachname;
    local.strasse = dto.strasse;
    local.plz = dto.plz;
    local.ort = dto.ort;
    local.telefon = dto.telefon;
    local.email = dto.email;
    local.notizen = dto.notizen;
    local.isDeleted = dto.isDeleted;
    local.createdAt = dto.createdAt;
    local.updatedAt = dto.updatedAt;
    local.isSynced = true;
    local.lastModifiedAt = dto.updatedAt ?? dto.createdAt ?? DateTime.now();
    return local;
  }

  static Map<String, dynamic> toJson(KundeLocal local) {
    final json = <String, dynamic>{
      'user_id': local.userId,
      'firma': local.firma,
      'vorname': local.vorname,
      'nachname': local.nachname,
      'strasse': local.strasse,
      'plz': local.plz,
      'ort': local.ort,
      'telefon': local.telefon,
      'email': local.email,
      'notizen': local.notizen,
      'is_deleted': local.isDeleted,
    };
    if (local.serverId != null) json['id'] = local.serverId;
    return json;
  }
}
