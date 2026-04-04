import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/beleg_scan_result.dart';
import 'package:kmu_tool_app/services/spesen/beleg_scan_service.dart';
import 'package:kmu_tool_app/services/spesen/spesen_import_service.dart';

/// 3-Schritt Spesen-Scanner: Foto → Prüfen → Fertig
class SpesenScannerScreen extends StatefulWidget {
  const SpesenScannerScreen({super.key});

  @override
  State<SpesenScannerScreen> createState() => _SpesenScannerScreenState();
}

class _SpesenScannerScreenState extends State<SpesenScannerScreen> {
  int _step = 0; // 0=Foto, 1=Prüfen, 2=Fertig
  bool _isLoading = false;
  String? _errorMessage;

  // Foto
  Uint8List? _imageBytes;
  String? _imageName;
  String? _imageMimeType;

  // OCR-Ergebnis
  BelegScanResult? _scanResult;
  String _zahlungsmethode = 'karte'; // bar, karte, kreditkarte

  // Ergebnis
  List<String>? _buchungIds;

  @override
  void initState() {
    super.initState();
    // Kamera direkt öffnen beim Start
    WidgetsBinding.instance.addPostFrameCallback((_) => _takePicture());
  }

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 60,
    );
    if (photo == null) {
      if (mounted && _imageBytes == null) {
        // Kein Foto und noch kein vorheriges → zurück
        context.pop();
      }
      return;
    }
    await _processImage(photo);
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 60,
    );
    if (image == null) return;
    await _processImage(image);
  }

  Future<void> _processImage(XFile image) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bytes = await image.readAsBytes();
      final mimeType = image.mimeType ?? 'image/jpeg';

      setState(() {
        _imageBytes = bytes;
        _imageName = image.name;
        _imageMimeType = mimeType;
      });

      // OCR starten
      final base64 = base64Encode(bytes);
      final result = await BelegScanService.scanBeleg(
        imageBase64: base64,
        mimeType: mimeType,
      );

      // Zahlungsmethode aus OCR ableiten
      String methode = 'karte';
      switch (result.zahlungsmethode) {
        case 'bar':
          methode = 'bar';
        case 'twint':
        case 'karte':
          methode = 'karte';
        default:
          methode = 'karte';
      }

      setState(() {
        _scanResult = result;
        _zahlungsmethode = methode;
        _step = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _importieren() async {
    if (_scanResult == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ids = await SpesenImportService.importBeleg(
        scanResult: _scanResult!,
        zahlungsmethode: _zahlungsmethode,
        belegBild: _imageBytes,
        belegDateiname: _imageName,
        belegDateityp: _imageMimeType,
      );

      setState(() {
        _buchungIds = ids;
        _step = 2;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_step == 0
            ? 'Beleg scannen'
            : _step == 1
                ? 'Beleg prüfen'
                : 'Fertig'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _step == 0
                        ? 'Beleg wird analysiert...'
                        : 'Buchungen werden erstellt...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            )
          : switch (_step) {
              0 => _buildStep0Foto(context),
              1 => _buildStep1Review(context),
              2 => _buildStep2Success(context),
              _ => const SizedBox(),
            },
    );
  }

  // ─── Step 0: Foto aufnehmen ───

  Widget _buildStep0Foto(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMessage != null) ...[
              Icon(Icons.error_outline, size: 48, color: AppStatusColors.error),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppStatusColors.error,
                    ),
              ),
              const SizedBox(height: 24),
            ],
            Icon(
              Icons.receipt_long,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Beleg fotografieren',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Fotografiere deinen Kassenbon oder wähle ein Bild aus der Galerie.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _takePicture,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Foto aufnehmen'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Aus Galerie wählen'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 1: OCR-Ergebnis prüfen ───

  Widget _buildStep1Review(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final result = _scanResult!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Konfidenz-Badge
        _buildKonfidenzBadge(context, result.konfidenz),
        const SizedBox(height: 16),

        // Geschäft & Datum
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.geschaeft,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${result.datum.day}.${result.datum.month.toString().padLeft(2, '0')}.${result.datum.year}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Positionen
        Text(
          'Positionen',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ...result.positionen.map((pos) => Card(
              child: ListTile(
                leading: Icon(
                  pos.istBenzin ? Icons.local_gas_station : Icons.restaurant,
                  color: pos.istBenzin
                      ? const Color(0xFFD97706)
                      : colorScheme.primary,
                ),
                title: Text(pos.beschreibung),
                subtitle: Text(
                  '${pos.kategorie == 'benzin' ? 'Benzin' : 'Essen'} · MWST ${pos.mwstSatz}%',
                ),
                trailing: Text(
                  'CHF ${pos.betragBrutto.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            )),
        const SizedBox(height: 12),

        // Total
        Card(
          color: colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'CHF ${result.totalBrutto.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Mischkauf-Info
        if (result.istMischkauf)
          Card(
            color: AppStatusColors.info.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppStatusColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mischkauf erkannt: Verschiedene MWST-Sätze werden separat verbucht.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (result.istMischkauf) const SizedBox(height: 16),

        // Zahlungsmethode
        Text(
          'Zahlungsmethode',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildChoiceChip(context, 'Bar', 'bar', Icons.payments),
            _buildChoiceChip(context, 'Karte/Bank', 'karte', Icons.credit_card),
            _buildChoiceChip(
                context, 'Kreditkarte', 'kreditkarte', Icons.credit_score),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _zahlungsKontoLabel(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppStatusColors.error,
                ),
          ),
        ],

        const SizedBox(height: 24),

        // Aktions-Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _step = 0;
                    _scanResult = null;
                    _imageBytes = null;
                  });
                  _takePicture();
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Neu scannen'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _importieren,
                icon: const Icon(Icons.check),
                label: const Text('Buchen'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildChoiceChip(
      BuildContext context, String label, String value, IconData icon) {
    final isSelected = _zahlungsmethode == value;
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      selected: isSelected,
      onSelected: (_) => setState(() => _zahlungsmethode = value),
      avatar: Icon(icon,
          size: 18,
          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface),
      label: Text(label),
      selectedColor: colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
      ),
      checkmarkColor: colorScheme.onPrimary,
    );
  }

  String _zahlungsKontoLabel() {
    switch (_zahlungsmethode) {
      case 'bar':
        return 'Konto 1000 (Kasse)';
      case 'kreditkarte':
        return 'Konto 2030 (Kreditkarte)';
      default:
        return 'Konto 1020 (Bank/Post)';
    }
  }

  Widget _buildKonfidenzBadge(BuildContext context, double konfidenz) {
    final prozent = (konfidenz * 100).round();
    Color badgeColor;
    String label;

    if (konfidenz >= 0.85) {
      badgeColor = AppStatusColors.success;
      label = 'Hohe Erkennung';
    } else if (konfidenz >= 0.70) {
      badgeColor = AppStatusColors.warning;
      label = 'Mittlere Erkennung';
    } else {
      badgeColor = AppStatusColors.error;
      label = 'Niedrige Erkennung';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 16, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            '$label ($prozent%)',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Erfolg ───

  Widget _buildStep2Success(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final anzahlBuchungen = _buchungIds?.length ?? 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppStatusColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 48,
                color: AppStatusColors.success,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Beleg verbucht!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '$anzahlBuchungen Buchung${anzahlBuchungen != 1 ? 'en' : ''} erstellt',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            if (_scanResult != null) ...[
              const SizedBox(height: 4),
              Text(
                '${_scanResult!.geschaeft} · CHF ${_scanResult!.totalBrutto.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                // Reset für nächsten Scan
                setState(() {
                  _step = 0;
                  _scanResult = null;
                  _imageBytes = null;
                  _buchungIds = null;
                  _errorMessage = null;
                });
                _takePicture();
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Nächsten Beleg scannen'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/buchhaltung/buchungen'),
              icon: const Icon(Icons.list),
              label: const Text('Zu den Buchungen'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Schliessen'),
            ),
          ],
        ),
      ),
    );
  }
}
