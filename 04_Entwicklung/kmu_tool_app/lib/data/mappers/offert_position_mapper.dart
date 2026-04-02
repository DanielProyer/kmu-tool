import 'package:kmu_tool_app/data/local/offert_position_local_export.dart';
import 'package:kmu_tool_app/data/models/offert_position.dart';

class OffertPositionMapper {
  static OffertPositionLocal fromDto(OffertPosition dto,
      {OffertPositionLocal? existing}) {
    final local = existing ?? OffertPositionLocal();
    local.serverId = dto.id;
    local.offerteId = dto.offerteId;
    local.positionNr = dto.positionNr;
    local.bezeichnung = dto.bezeichnung;
    local.menge = dto.menge;
    local.einheit = dto.einheit;
    local.einheitspreis = dto.einheitspreis;
    local.betrag = dto.betrag;
    local.typ = dto.typ;
    local.artikelId = dto.artikelId;
    local.createdAt = dto.createdAt;
    local.updatedAt = dto.updatedAt;
    local.isSynced = true;
    local.lastModifiedAt = dto.updatedAt ?? dto.createdAt ?? DateTime.now();
    return local;
  }

  static Map<String, dynamic> toJson(OffertPositionLocal local) {
    final json = <String, dynamic>{
      'offerte_id': local.offerteId,
      'position_nr': local.positionNr,
      'bezeichnung': local.bezeichnung,
      'menge': local.menge,
      'einheit': local.einheit,
      'einheitspreis': local.einheitspreis,
      'betrag': local.betrag,
      // Migration 013 Spalten - erst senden wenn Migration ausgefuehrt:
      // 'typ': local.typ,
      // 'artikel_id': local.artikelId,
    };
    if (local.serverId != null) json['id'] = local.serverId;
    return json;
  }
}
