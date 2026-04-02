import 'package:kmu_tool_app/data/local/rapport_local_export.dart';
import 'package:kmu_tool_app/data/models/rapport.dart';

class RapportMapper {
  static RapportLocal fromDto(Rapport dto, {RapportLocal? existing}) {
    final local = existing ?? RapportLocal();
    local.serverId = dto.id;
    local.auftragId = dto.auftragId;
    local.userId = dto.userId;
    local.datum = dto.datum;
    local.beschreibung = dto.beschreibung;
    local.status = dto.status;
    local.createdAt = dto.createdAt;
    local.updatedAt = dto.updatedAt;
    local.isSynced = true;
    local.lastModifiedAt = dto.updatedAt ?? dto.createdAt ?? DateTime.now();
    return local;
  }

  static Map<String, dynamic> toJson(RapportLocal local) {
    final json = <String, dynamic>{
      'auftrag_id': local.auftragId,
      'user_id': local.userId,
      'datum': local.datum.toIso8601String().split('T').first,
      'beschreibung': local.beschreibung,
      'status': local.status,
    };
    if (local.serverId != null) json['id'] = local.serverId;
    return json;
  }
}
