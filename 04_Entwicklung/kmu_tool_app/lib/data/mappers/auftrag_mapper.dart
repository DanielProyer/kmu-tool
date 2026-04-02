import 'package:kmu_tool_app/data/local/auftrag_local_export.dart';
import 'package:kmu_tool_app/data/models/auftrag.dart';

class AuftragMapper {
  static AuftragLocal fromDto(Auftrag dto, {AuftragLocal? existing}) {
    final local = existing ?? AuftragLocal();
    local.serverId = dto.id;
    local.userId = dto.userId;
    local.kundeId = dto.kundeId;
    local.offerteId = dto.offerteId;
    local.auftragsNr = dto.auftragsNr;
    local.status = dto.status;
    local.beschreibung = dto.beschreibung;
    local.geplantVon = dto.geplantVon;
    local.geplantBis = dto.geplantBis;
    local.isDeleted = dto.isDeleted;
    local.createdAt = dto.createdAt;
    local.updatedAt = dto.updatedAt;
    local.isSynced = true;
    local.lastModifiedAt = dto.updatedAt ?? dto.createdAt ?? DateTime.now();
    return local;
  }

  static Map<String, dynamic> toJson(AuftragLocal local) {
    final json = <String, dynamic>{
      'user_id': local.userId,
      'kunde_id': local.kundeId,
      'offerte_id': local.offerteId,
      'auftrags_nr': local.auftragsNr,
      'status': local.status,
      'beschreibung': local.beschreibung,
      'geplant_von': local.geplantVon?.toIso8601String().split('T').first,
      'geplant_bis': local.geplantBis?.toIso8601String().split('T').first,
      'is_deleted': local.isDeleted,
    };
    if (local.serverId != null) json['id'] = local.serverId;
    return json;
  }
}
