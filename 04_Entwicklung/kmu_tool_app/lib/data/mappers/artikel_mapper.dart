import 'package:kmu_tool_app/data/local/artikel_local_export.dart';
import 'package:kmu_tool_app/data/models/artikel.dart';

class ArtikelMapper {
  static ArtikelLocal fromDto(Artikel dto, {ArtikelLocal? existing}) {
    final local = existing ?? ArtikelLocal();
    local.serverId = dto.id;
    local.userId = dto.userId;
    local.artikelNr = dto.artikelNr;
    local.bezeichnung = dto.bezeichnung;
    local.kategorie = dto.kategorie;
    local.einheit = dto.einheit;
    local.einkaufspreis = dto.einkaufspreis;
    local.verkaufspreis = dto.verkaufspreis;
    local.lagerbestand = dto.lagerbestand;
    local.mindestbestand = dto.mindestbestand;
    local.lieferant = dto.lieferant;
    local.notizen = dto.notizen;
    local.materialTyp = dto.materialTyp;
    local.aufwandkonto = dto.aufwandkonto;
    local.mwstCode = dto.mwstCode;
    local.isDeleted = dto.isDeleted;
    local.createdAt = dto.createdAt;
    local.updatedAt = dto.updatedAt;
    local.isSynced = true;
    local.lastModifiedAt = dto.updatedAt ?? dto.createdAt ?? DateTime.now();
    return local;
  }

  static Map<String, dynamic> toJson(ArtikelLocal local) {
    final json = <String, dynamic>{
      'user_id': local.userId,
      'artikel_nr': local.artikelNr,
      'bezeichnung': local.bezeichnung,
      'kategorie': local.kategorie,
      'einheit': local.einheit,
      'einkaufspreis': local.einkaufspreis,
      'verkaufspreis': local.verkaufspreis,
      'lagerbestand': local.lagerbestand,
      'mindestbestand': local.mindestbestand,
      'lieferant': local.lieferant,
      'notizen': local.notizen,
      'material_typ': local.materialTyp,
      'aufwandkonto': local.aufwandkonto,
      'mwst_code': local.mwstCode,
      'is_deleted': local.isDeleted,
    };
    if (local.serverId != null) json['id'] = local.serverId;
    return json;
  }
}
