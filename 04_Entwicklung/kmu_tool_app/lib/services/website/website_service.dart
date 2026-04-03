import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/data/models/website_config.dart';
import 'package:kmu_tool_app/data/models/website_section.dart';
import 'package:kmu_tool_app/data/models/website_gallery_image.dart';
import 'package:kmu_tool_app/data/models/user_profile.dart';
import 'package:kmu_tool_app/data/repositories/website_config_repository.dart';
import 'package:kmu_tool_app/data/repositories/website_section_repository.dart';
import 'package:kmu_tool_app/data/repositories/website_gallery_repository.dart';
import 'package:kmu_tool_app/services/storage/file_storage_service.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';
import '../auth/betrieb_service.dart';

class WebsiteService {
  static const _uuid = Uuid();
  static const _supabaseProjectId = 'eeapkhlzrujzgjqfvgfc';

  /// Erstellt eine neue Website-Konfiguration aus dem UserProfile.
  static Future<WebsiteConfig> initializeWebsite(UserProfile profile) async {
    final userId = await BetriebService.getDataOwnerId();
    final slug = await generateSlug(profile.firmaName);
    final configId = _uuid.v4();

    final config = WebsiteConfig(
      id: configId,
      userId: userId,
      slug: slug,
      firmenName: profile.firmaName,
      untertitel: null,
      kontaktEmail: profile.email,
      kontaktTelefon: profile.telefon,
      adresseStrasse: profile.strasse,
      adressePlz: profile.plz,
      adresseOrt: profile.ort,
      impressumUid: profile.uidNummer,
    );

    final saved = await WebsiteConfigRepository.save(config);

    // Default-Sektionen erstellen
    final defaultSections = _defaultSections(configId);
    for (final section in defaultSections) {
      await WebsiteSectionRepository.save(section);
    }

    return saved;
  }

  /// Generiert einen URL-Slug aus dem Firmennamen.
  static Future<String> generateSlug(String firmaName) async {
    var slug = firmaName.toLowerCase().trim();

    // Umlaute normalisieren
    slug = slug
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss');

    // GmbH, AG etc. entfernen
    slug = slug.replaceAll(RegExp(r'\s*(gmbh|ag|sa|sarl)\s*', caseSensitive: false), '');

    // Nur Buchstaben, Zahlen und Bindestriche
    slug = slug.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    slug = slug.replaceAll(RegExp(r'-+'), '-');
    slug = slug.replaceAll(RegExp(r'^-|-$'), '');

    if (slug.isEmpty) slug = 'meine-firma';

    // Uniqueness-Check
    var candidate = slug;
    var counter = 1;
    while (!await WebsiteConfigRepository.isSlugAvailable(candidate)) {
      candidate = '$slug-$counter';
      counter++;
    }

    return candidate;
  }

  static Future<void> publishWebsite(String configId) async {
    await WebsiteConfigRepository.updatePublished(configId, true);
  }

  static Future<void> unpublishWebsite(String configId) async {
    await WebsiteConfigRepository.updatePublished(configId, false);
  }

  /// Gibt die oeffentliche URL der Website zurueck.
  static String getPublicUrl(String slug) {
    return 'https://$_supabaseProjectId.supabase.co/functions/v1/website/$slug';
  }

  /// Upload eines Logos.
  static Future<String> uploadLogo({
    required String configId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final path = await FileStorageService.uploadWebsiteAsset(
      entityId: configId,
      fileName: 'logo_$fileName',
      bytes: bytes,
    );
    return path;
  }

  /// Upload eines Galerie-Bildes.
  static Future<WebsiteGalleryImage> uploadGalleryImage({
    required String configId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final storagePath = await FileStorageService.uploadWebsiteAsset(
      entityId: configId,
      fileName: 'gallery_${DateTime.now().millisecondsSinceEpoch}_$fileName',
      bytes: bytes,
    );

    final image = WebsiteGalleryImage(
      id: _uuid.v4(),
      configId: configId,
      storagePath: storagePath,
      dateiName: fileName,
    );

    return WebsiteGalleryRepository.create(image);
  }

  /// Loescht ein Galerie-Bild (Storage + DB).
  static Future<void> deleteGalleryImage(String imageId) async {
    await WebsiteGalleryRepository.delete(imageId);
  }

  /// Gibt die public URL fuer ein Asset zurueck.
  static String getAssetPublicUrl(String storagePath) {
    return SupabaseService.client.storage
        .from(FileStorageService.websiteAssetsBucket)
        .getPublicUrl(storagePath);
  }

  /// Erstellt die 12 Default-Sektionen.
  static List<WebsiteSection> _defaultSections(String configId) {
    final sections = <WebsiteSection>[];
    var sort = 0;

    // Sichtbare Sektionen
    sections.add(WebsiteSection(
      id: _uuid.v4(),
      configId: configId,
      typ: 'hero',
      titel: 'Willkommen',
      content: {
        'headline': '',
        'subline': '',
        'cta_text': 'Offerte anfragen',
        'cta_link': '#offertanfrage',
      },
      sortierung: sort++,
      isVisible: true,
    ));

    sections.add(WebsiteSection(
      id: _uuid.v4(),
      configId: configId,
      typ: 'beschreibung',
      titel: 'Ueber uns',
      content: {'text': ''},
      sortierung: sort++,
      isVisible: true,
    ));

    sections.add(WebsiteSection(
      id: _uuid.v4(),
      configId: configId,
      typ: 'leistungen',
      titel: 'Unsere Leistungen',
      content: {'items': []},
      sortierung: sort++,
      isVisible: true,
    ));

    sections.add(WebsiteSection(
      id: _uuid.v4(),
      configId: configId,
      typ: 'kontakt',
      titel: 'Kontakt',
      content: {'zeige_karte': true, 'zeige_formular': true},
      sortierung: sort++,
      isVisible: true,
    ));

    sections.add(WebsiteSection(
      id: _uuid.v4(),
      configId: configId,
      typ: 'offertanfrage',
      titel: 'Offerte anfragen',
      content: {'leistungen': [], 'zeige_wunschtermin': true},
      sortierung: sort++,
      isVisible: true,
    ));

    // Versteckte Sektionen
    sections.add(WebsiteSection(
      id: _uuid.v4(),
      configId: configId,
      typ: 'ueber_uns',
      titel: 'Ueber uns',
      content: {'text': ''},
      sortierung: sort++,
      isVisible: false,
    ));

    sections.add(WebsiteSection(
      id: _uuid.v4(),
      configId: configId,
      typ: 'team',
      titel: 'Unser Team',
      content: {'mitglieder': []},
      sortierung: sort++,
      isVisible: false,
    ));

    sections.add(WebsiteSection(
      id: _uuid.v4(),
      configId: configId,
      typ: 'referenzen',
      titel: 'Referenzen',
      content: {'projekte': []},
      sortierung: sort++,
      isVisible: false,
    ));

    sections.add(WebsiteSection(
      id: _uuid.v4(),
      configId: configId,
      typ: 'kundenstimmen',
      titel: 'Das sagen unsere Kunden',
      content: {'testimonials': []},
      sortierung: sort++,
      isVisible: false,
    ));

    sections.add(WebsiteSection(
      id: _uuid.v4(),
      configId: configId,
      typ: 'galerie',
      titel: 'Galerie',
      content: {},
      sortierung: sort++,
      isVisible: false,
    ));

    sections.add(WebsiteSection(
      id: _uuid.v4(),
      configId: configId,
      typ: 'faq',
      titel: 'Haeufige Fragen',
      content: {'fragen': []},
      sortierung: sort++,
      isVisible: false,
    ));

    sections.add(WebsiteSection(
      id: _uuid.v4(),
      configId: configId,
      typ: 'notfalldienst',
      titel: 'Notfalldienst',
      content: {'text': '', 'telefon': '', 'zeiten': ''},
      sortierung: sort++,
      isVisible: false,
    ));

    return sections;
  }
}
