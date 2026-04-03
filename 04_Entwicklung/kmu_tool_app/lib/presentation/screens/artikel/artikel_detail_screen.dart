import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';
import 'package:kmu_tool_app/data/repositories/artikel_repository.dart';
import 'package:kmu_tool_app/services/storage/file_storage_service.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ArtikelDetailScreen extends ConsumerWidget {
  final String artikelId;

  const ArtikelDetailScreen({super.key, required this.artikelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final artikelAsync = ref.watch(artikelProvider(artikelId));
    final bestandAsync = ref.watch(lagerbestandByArtikelProvider(artikelId));
    final lieferantenAsync =
        ref.watch(artikelLieferantenProvider(artikelId));
    final fotosAsync = ref.watch(artikelFotosProvider(artikelId));
    final bewegungenAsync =
        ref.watch(lagerbewegungByArtikelProvider(artikelId));

    return artikelAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: AppStatusColors.error),
                const SizedBox(height: 16),
                Text('Fehler beim Laden: $error'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(artikelProvider(artikelId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (artikel) {
        if (artikel == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Artikel nicht gefunden')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.canPop(context)
                  ? context.pop()
                  : context.go('/artikel'),
            ),
            title: Text(artikel.bezeichnung),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await context
                      .push('/artikel/$artikelId/bearbeiten');
                  ref.invalidate(artikelProvider(artikelId));
                  ref.invalidate(artikelListProvider);
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    await _confirmDelete(context, ref);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Loeschen',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Grunddaten ───
                const _SectionHeader(title: 'Grunddaten'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (artikel.artikelNr != null &&
                            artikel.artikelNr!.isNotEmpty)
                          _DetailRow(
                            icon: Icons.tag,
                            label: 'Artikel-Nr',
                            value: artikel.artikelNr!,
                          ),
                        _DetailRow(
                          icon: Icons.inventory_2_outlined,
                          label: 'Bezeichnung',
                          value: artikel.bezeichnung,
                        ),
                        _DetailRow(
                          icon: Icons.category_outlined,
                          label: 'Kategorie',
                          value: _kategorieLabel(artikel.kategorie),
                        ),
                        if (artikel.einheit != null &&
                            artikel.einheit!.isNotEmpty)
                          _DetailRow(
                            icon: Icons.straighten_outlined,
                            label: 'Einheit',
                            value: artikel.einheit!,
                          ),
                        if (artikel.materialTyp != null &&
                            artikel.materialTyp!.isNotEmpty)
                          _DetailRow(
                            icon: Icons.label_outlined,
                            label: 'Materialtyp',
                            value: _materialTypLabel(artikel.materialTyp!),
                          ),
                      ],
                    ),
                  ),
                ),

                // ─── Preise ───
                const _SectionHeader(title: 'Preise'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.shopping_cart_outlined,
                          label: 'EK-Preis',
                          value:
                              'CHF ${artikel.einkaufspreis.toStringAsFixed(2)}',
                        ),
                        _DetailRow(
                          icon: Icons.sell_outlined,
                          label: 'VK-Preis',
                          value:
                              'CHF ${artikel.verkaufspreis.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Fotos ───
                fotosAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (fotos) {
                    if (fotos.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(title: 'Fotos'),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: fotos.length,
                            itemBuilder: (context, index) {
                              final foto = fotos[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _FotoThumbnail(
                                  storagePath: foto.storagePath,
                                  istHauptbild: foto.istHauptbild,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // ─── Bestand nach Lagerort ───
                _SectionHeader(
                  title: 'Bestand nach Lagerort',
                  trailing: TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Warenbewegung erfassen'),
                    onPressed: () async {
                      await context
                          .push('/artikel/$artikelId/bewegungen/neu');
                      ref.invalidate(
                          lagerbestandByArtikelProvider(artikelId));
                      ref.invalidate(
                          lagerbewegungByArtikelProvider(artikelId));
                    },
                  ),
                ),
                bestandAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Fehler: $e'),
                  ),
                  data: (bestaende) {
                    if (bestaende.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          'Kein Lagerbestand vorhanden',
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant),
                        ),
                      );
                    }

                    // Totals berechnen
                    double totalMenge = 0;
                    double totalReserviert = 0;
                    double totalVerfuegbar = 0;
                    for (final b in bestaende) {
                      totalMenge += b.menge;
                      totalReserviert += b.reserviert;
                      totalVerfuegbar += b.verfuegbar;
                    }

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(1),
                            2: FlexColumnWidth(1),
                            3: FlexColumnWidth(1),
                          },
                          children: [
                            // Header
                            TableRow(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      color: colorScheme.outlineVariant),
                                ),
                              ),
                              children: [
                                _tableHeader('Lagerort'),
                                _tableHeader('Menge', align: TextAlign.right),
                                _tableHeader('Reserv.',
                                    align: TextAlign.right),
                                _tableHeader('Verfuegb.',
                                    align: TextAlign.right),
                              ],
                            ),
                            // Rows
                            ...bestaende.map((b) => TableRow(
                                  children: [
                                    _tableCell(
                                        b.lagerortBezeichnung ?? 'Unbekannt'),
                                    _tableCell(
                                        b.menge.toStringAsFixed(0),
                                        align: TextAlign.right),
                                    _tableCell(
                                        b.reserviert.toStringAsFixed(0),
                                        align: TextAlign.right),
                                    _tableCell(
                                        b.verfuegbar.toStringAsFixed(0),
                                        align: TextAlign.right),
                                  ],
                                )),
                            // Total Row
                            TableRow(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                      color: colorScheme.outlineVariant),
                                ),
                              ),
                              children: [
                                _tableCell('Total',
                                    bold: true),
                                _tableCell(
                                    totalMenge.toStringAsFixed(0),
                                    align: TextAlign.right,
                                    bold: true),
                                _tableCell(
                                    totalReserviert.toStringAsFixed(0),
                                    align: TextAlign.right,
                                    bold: true),
                                _tableCell(
                                    totalVerfuegbar.toStringAsFixed(0),
                                    align: TextAlign.right,
                                    bold: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // ─── Lieferanten ───
                const _SectionHeader(title: 'Lieferanten'),
                lieferantenAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Fehler: $e'),
                  ),
                  data: (lieferanten) {
                    if (lieferanten.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          'Keine Lieferanten verknuepft',
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant),
                        ),
                      );
                    }
                    return Column(
                      children: lieferanten
                          .map((l) => _LieferantCard(lieferant: l))
                          .toList(),
                    );
                  },
                ),

                // ─── Letzte Bewegungen ───
                _SectionHeader(
                  title: 'Letzte Bewegungen',
                  trailing: TextButton(
                    onPressed: () =>
                        context.push('/artikel/$artikelId/bewegungen'),
                    child: const Text('Alle anzeigen'),
                  ),
                ),
                bewegungenAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Fehler: $e'),
                  ),
                  data: (bewegungen) {
                    if (bewegungen.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          'Keine Bewegungen vorhanden',
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant),
                        ),
                      );
                    }
                    final recent = bewegungen.take(5).toList();
                    return Column(
                      children: recent
                          .map((b) => _BewegungCard(bewegung: b))
                          .toList(),
                    );
                  },
                ),

                // ─── Notizen ───
                if (artikel.notizen != null &&
                    artikel.notizen!.isNotEmpty) ...[
                  const _SectionHeader(title: 'Notizen'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notes_outlined,
                              size: 20,
                              color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              artikel.notizen!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Artikel loeschen?'),
        content: const Text(
          'Moechtest du diesen Artikel wirklich loeschen? '
          'Diese Aktion kann nicht rueckgaengig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppStatusColors.error,
            ),
            child: const Text('Loeschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ArtikelRepository.delete(artikelId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Artikel geloescht'),
              backgroundColor: AppStatusColors.success,
            ),
          );
          ref.invalidate(artikelListProvider);
          ref.invalidate(artikelProvider(artikelId));
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Loeschen: $e'),
              backgroundColor: AppStatusColors.error,
            ),
          );
        }
      }
    }
  }

  String _kategorieLabel(String kategorie) {
    switch (kategorie) {
      case 'material':
        return 'Material';
      case 'werkzeug':
        return 'Werkzeug';
      case 'verbrauch':
        return 'Verbrauchsmaterial';
      default:
        return kategorie;
    }
  }

  String _materialTypLabel(String typ) {
    switch (typ) {
      case 'material':
        return 'Material';
      case 'werkzeug':
        return 'Werkzeug';
      case 'verbrauch':
        return 'Verbrauchsmaterial';
      case 'dienstleistung':
        return 'Dienstleistung';
      default:
        return typ;
    }
  }

  Widget _tableHeader(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _tableCell(String text,
      {TextAlign align = TextAlign.left, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

// ─── Shared Widgets ───

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _FotoThumbnail extends StatefulWidget {
  final String storagePath;
  final bool istHauptbild;

  const _FotoThumbnail({
    required this.storagePath,
    required this.istHauptbild,
  });

  @override
  State<_FotoThumbnail> createState() => _FotoThumbnailState();
}

class _FotoThumbnailState extends State<_FotoThumbnail> {
  String? _signedUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    try {
      final url = await FileStorageService.getSignedUrl(
        bucket: FileStorageService.artikelFotosBucket,
        path: widget.storagePath,
      );
      if (mounted) {
        setState(() {
          _signedUrl = url;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            color: colorScheme.surfaceContainerHighest,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))
                : _signedUrl != null
                    ? Image.network(
                        _signedUrl!,
                        fit: BoxFit.cover,
                        width: 100,
                        height: 100,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.broken_image_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Icon(
                        Icons.image_not_supported_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
          ),
          if (widget.istHauptbild)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppStatusColors.warning,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.star, size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _LieferantCard extends StatelessWidget {
  final dynamic lieferant;

  const _LieferantCard({required this.lieferant});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  colorScheme.secondary.withValues(alpha: 0.1),
              child: Icon(Icons.local_shipping_outlined,
                  size: 18, color: colorScheme.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lieferant.lieferantFirma ?? 'Unbekannter Lieferant',
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (lieferant.istHauptlieferant)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppStatusColors.success
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Hauptlieferant',
                            style: TextStyle(
                              color: AppStatusColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (lieferant.einkaufspreis != null) ...[
                        Text(
                          'EK: CHF ${lieferant.einkaufspreis!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (lieferant.lieferzeitTage != null)
                        Text(
                          'Lieferzeit: ${lieferant.lieferzeitTage} Tage',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BewegungCard extends StatelessWidget {
  final dynamic bewegung;

  const _BewegungCard({required this.bewegung});

  Color _bewegungColor(String typ) {
    switch (typ) {
      case 'eingang':
        return AppStatusColors.success;
      case 'ausgang':
        return AppStatusColors.error;
      case 'umlagerung':
        return AppStatusColors.info;
      case 'korrektur':
        return AppStatusColors.warning;
      case 'inventur':
        return AppStatusColors.storniert;
      default:
        return AppStatusColors.storniert;
    }
  }

  IconData _bewegungIcon(String typ) {
    switch (typ) {
      case 'eingang':
        return Icons.arrow_downward;
      case 'ausgang':
        return Icons.arrow_upward;
      case 'umlagerung':
        return Icons.swap_horiz;
      case 'korrektur':
        return Icons.edit_outlined;
      case 'inventur':
        return Icons.checklist;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _bewegungColor(bewegung.bewegungstyp);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    String lagerortText = bewegung.lagerortBezeichnung ?? '';
    if (bewegung.zielLagerortBezeichnung != null &&
        bewegung.zielLagerortBezeichnung!.isNotEmpty) {
      lagerortText += ' → ${bewegung.zielLagerortBezeichnung}';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(_bewegungIcon(bewegung.bewegungstyp),
                  size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        bewegung.bewegungstypLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${bewegung.menge > 0 ? '+' : ''}${bewegung.menge.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  if (lagerortText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      lagerortText,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (bewegung.createdAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(bewegung.createdAt!),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
