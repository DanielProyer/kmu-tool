import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/buchungs_beleg.dart';
import 'package:kmu_tool_app/data/repositories/buchungs_beleg_repository.dart';
import 'package:kmu_tool_app/presentation/providers/buchhaltung_provider.dart';

/// Widget zum Anzeigen und Hochladen von Belegen zu einer Buchung.
class BelegUploadWidget extends ConsumerStatefulWidget {
  final String buchungId;

  const BelegUploadWidget({super.key, required this.buchungId});

  @override
  ConsumerState<BelegUploadWidget> createState() => _BelegUploadWidgetState();
}

class _BelegUploadWidgetState extends ConsumerState<BelegUploadWidget> {
  final _belegRepo = BuchungsBelegRepository();
  bool _isUploading = false;

  Future<void> _uploadFromCamera() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (photo == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await photo.readAsBytes();
      await _belegRepo.upload(
        buchungId: widget.buchungId,
        dateiname: photo.name,
        dateityp: photo.mimeType ?? 'image/jpeg',
        bytes: bytes,
        belegQuelle: 'manuell',
      );
      ref.invalidate(belegeByBuchungProvider(widget.buchungId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload fehlgeschlagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _uploadFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await image.readAsBytes();
      await _belegRepo.upload(
        buchungId: widget.buchungId,
        dateiname: image.name,
        dateityp: image.mimeType ?? 'image/jpeg',
        bytes: bytes,
        belegQuelle: 'manuell',
      );
      ref.invalidate(belegeByBuchungProvider(widget.buchungId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload fehlgeschlagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _uploadPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _isUploading = true);
    try {
      await _belegRepo.upload(
        buchungId: widget.buchungId,
        dateiname: file.name,
        dateityp: 'application/pdf',
        bytes: file.bytes!,
        belegQuelle: 'manuell',
      );
      ref.invalidate(belegeByBuchungProvider(widget.buchungId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload fehlgeschlagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteBeleg(BuchungsBeleg beleg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Beleg löschen?'),
        content: Text('${beleg.dateiname} wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppStatusColors.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _belegRepo.delete(beleg.id);
      ref.invalidate(belegeByBuchungProvider(widget.buchungId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Löschen fehlgeschlagen: $e')),
        );
      }
    }
  }

  Future<void> _openBeleg(BuchungsBeleg beleg) async {
    try {
      final url = await _belegRepo.getSignedUrl(beleg.storagePfad);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Öffnen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final belegeAsync = ref.watch(belegeByBuchungProvider(widget.buchungId));
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Belege',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (_isUploading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              PopupMenuButton<String>(
                icon: const Icon(Icons.add, size: 20),
                tooltip: 'Beleg hinzufügen',
                onSelected: (value) {
                  switch (value) {
                    case 'camera':
                      _uploadFromCamera();
                    case 'gallery':
                      _uploadFromGallery();
                    case 'pdf':
                      _uploadPdf();
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'camera',
                    child: ListTile(
                      leading: Icon(Icons.camera_alt),
                      title: Text('Foto aufnehmen'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'gallery',
                    child: ListTile(
                      leading: Icon(Icons.photo_library),
                      title: Text('Aus Galerie'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'pdf',
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf),
                      title: Text('PDF hochladen'),
                      dense: true,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 4),

        belegeAsync.when(
          data: (belege) {
            if (belege.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Keine Belege vorhanden',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              );
            }

            return Column(
              children: belege
                  .map((beleg) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          beleg.dateityp == 'application/pdf'
                              ? Icons.picture_as_pdf
                              : Icons.image,
                          color: colorScheme.primary,
                        ),
                        title: Text(
                          beleg.dateiname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(beleg.quelleLabel),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: AppStatusColors.error, size: 20),
                          onPressed: () => _deleteBeleg(beleg),
                        ),
                        onTap: () => _openBeleg(beleg),
                      ))
                  .toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => Text(
            'Fehler: $e',
            style: TextStyle(color: AppStatusColors.error),
          ),
        ),
      ],
    );
  }
}
