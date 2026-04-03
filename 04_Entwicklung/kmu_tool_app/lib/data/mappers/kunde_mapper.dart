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
    local.hausnummer = dto.hausnummer;
    local.plz = dto.plz;
    local.ort = dto.ort;
    local.telefon = dto.telefon;
    local.email = dto.email;
    local.notizen = dto.notizen;
    local.reAbweichend = dto.reAbweichend;
    local.reFirma = dto.reFirma;
    local.reVorname = dto.reVorname;
    local.reNachname = dto.reNachname;
    local.reStrasse = dto.reStrasse;
    local.reHausnummer = dto.reHausnummer;
    local.rePlz = dto.rePlz;
    local.reOrt = dto.reOrt;
    local.reEmail = dto.reEmail;
    local.rechnungsstellung = dto.rechnungsstellung;
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
      'hausnummer': local.hausnummer,
      'plz': local.plz,
      'ort': local.ort,
      'telefon': local.telefon,
      'email': local.email,
      'notizen': local.notizen,
      'is_deleted': local.isDeleted,
      // Migration 012 Spalten - erst senden wenn Migration ausgefuehrt:
      // 're_abweichend': local.reAbweichend,
      // 're_firma': local.reFirma,
      // 're_vorname': local.reVorname,
      // 're_nachname': local.reNachname,
      // 're_strasse': local.reStrasse,
      // 're_plz': local.rePlz,
      // 're_ort': local.reOrt,
      // 're_email': local.reEmail,
      // 'rechnungsstellung': local.rechnungsstellung,
    };
    if (local.serverId != null) json['id'] = local.serverId;
    return json;
  }
}
