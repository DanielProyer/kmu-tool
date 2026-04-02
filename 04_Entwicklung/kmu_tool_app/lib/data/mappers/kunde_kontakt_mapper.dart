import 'package:kmu_tool_app/data/local/kunde_kontakt_local_export.dart';
import 'package:kmu_tool_app/data/models/kunde_kontakt.dart';

class KundeKontaktMapper {
  static KundeKontaktLocal fromDto(KundeKontakt dto,
      {KundeKontaktLocal? existing}) {
    final local = existing ?? KundeKontaktLocal();
    local.serverId = dto.id;
    local.kundeId = dto.kundeId;
    local.vorname = dto.vorname;
    local.nachname = dto.nachname;
    local.funktion = dto.funktion;
    local.telefon = dto.telefon;
    local.email = dto.email;
    local.createdAt = dto.createdAt;
    local.updatedAt = dto.updatedAt;
    local.isSynced = true;
    local.lastModifiedAt = dto.updatedAt ?? dto.createdAt ?? DateTime.now();
    return local;
  }

  static Map<String, dynamic> toJson(KundeKontaktLocal local) {
    final json = <String, dynamic>{
      'kunde_id': local.kundeId,
      'vorname': local.vorname,
      'nachname': local.nachname,
      'funktion': local.funktion,
      'telefon': local.telefon,
      'email': local.email,
    };
    if (local.serverId != null) json['id'] = local.serverId;
    return json;
  }
}
