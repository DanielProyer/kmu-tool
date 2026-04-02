import 'package:kmu_tool_app/data/local/offerte_local_export.dart';
import 'package:kmu_tool_app/data/models/offerte.dart';

class OfferteMapper {
  static OfferteLocal fromDto(Offerte dto, {OfferteLocal? existing}) {
    final local = existing ?? OfferteLocal();
    local.serverId = dto.id;
    local.userId = dto.userId;
    local.kundeId = dto.kundeId;
    local.offertNr = dto.offertNr;
    local.datum = dto.datum;
    local.gueltigBis = dto.gueltigBis;
    local.status = dto.status;
    local.totalNetto = dto.totalNetto;
    local.mwstSatz = dto.mwstSatz;
    local.mwstBetrag = dto.mwstBetrag;
    local.totalBrutto = dto.totalBrutto;
    local.bemerkung = dto.bemerkung;
    local.isDeleted = dto.isDeleted;
    local.createdAt = dto.createdAt;
    local.updatedAt = dto.updatedAt;
    local.isSynced = true;
    local.lastModifiedAt = dto.updatedAt ?? dto.createdAt ?? DateTime.now();
    return local;
  }

  static Map<String, dynamic> toJson(OfferteLocal local) {
    final json = <String, dynamic>{
      'user_id': local.userId,
      'kunde_id': local.kundeId,
      'offert_nr': local.offertNr,
      'datum': local.datum.toIso8601String().split('T').first,
      'gueltig_bis': local.gueltigBis?.toIso8601String().split('T').first,
      'status': local.status,
      'total_netto': local.totalNetto,
      'mwst_satz': local.mwstSatz,
      'mwst_betrag': local.mwstBetrag,
      'total_brutto': local.totalBrutto,
      'bemerkung': local.bemerkung,
      'is_deleted': local.isDeleted,
    };
    if (local.serverId != null) json['id'] = local.serverId;
    return json;
  }
}
