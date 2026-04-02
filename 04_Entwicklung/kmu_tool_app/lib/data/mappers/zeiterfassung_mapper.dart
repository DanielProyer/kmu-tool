import 'package:kmu_tool_app/data/local/zeiterfassung_local_export.dart';
import 'package:kmu_tool_app/data/models/zeiterfassung.dart';

class ZeiterfassungMapper {
  static ZeiterfassungLocal fromDto(Zeiterfassung dto,
      {ZeiterfassungLocal? existing}) {
    final local = existing ?? ZeiterfassungLocal();
    local.serverId = dto.id;
    local.userId = dto.userId;
    local.auftragId = dto.auftragId;
    local.datum = dto.datum;
    local.startZeit = dto.startZeit;
    local.endZeit = dto.endZeit;
    local.pauseMinuten = dto.pauseMinuten;
    local.dauerMinuten = dto.dauerMinuten;
    local.beschreibung = dto.beschreibung;
    local.createdAt = dto.createdAt;
    local.updatedAt = dto.updatedAt;
    local.isSynced = true;
    local.lastModifiedAt = dto.updatedAt ?? dto.createdAt ?? DateTime.now();
    return local;
  }

  static Map<String, dynamic> toJson(ZeiterfassungLocal local) {
    final json = <String, dynamic>{
      'user_id': local.userId,
      'auftrag_id': local.auftragId,
      'datum': local.datum.toIso8601String().split('T').first,
      'start_zeit': local.startZeit,
      'end_zeit': local.endZeit,
      'pause_minuten': local.pauseMinuten,
      'dauer_minuten': local.dauerMinuten,
      'beschreibung': local.beschreibung,
    };
    if (local.serverId != null) json['id'] = local.serverId;
    return json;
  }
}
