import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/auftrag_datei.dart';
import 'package:kmu_tool_app/data/repositories/auftrag_datei_repository.dart';
import 'package:kmu_tool_app/presentation/providers/auftrag_dashboard_provider.dart';
import 'package:kmu_tool_app/services/storage/file_storage_service.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';
import 'package:file_picker/file_picker.dart';

class DateienTab extends ConsumerStatefulWidget {
  final String auftragId;

  const DateienTab({super.key, required this.auftragId});

  @override
  ConsumerState<DateienTab> createState() => _DateienTabState();
}

class _DateienTabState extends ConsumerState<DateienTab> {
  bool _isUploading = false;

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _isUploading = true);
    try {
      final userId = SupabaseService.client.auth.currentUser!.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageName = '${timestamp}_${file.name}';

      final path = await FileStorageService.uploadAuftragDatei(
        auftragId: widget.auftragId,
        fileName: storageName,
        bytes: file.bytes!,
      );

      await AuftragDateiRepository.create(AuftragDatei(
        id: '',
        auftragId: widget.auftragId,
        userId: userId,
        dateiPfad: path,
        dateiName: file.name,
        dateiTyp: file.extension,
        dateiGroesse: file.size,
      ));

      ref.invalidate(auftragDateienProvider(widget.auftragId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload fehlgeschlagen: $e'),
            backgroundColor: AppStatusColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _fileIcon(String? typ) {
    switch (typ?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'heic':
        return Icons.photo_outlined;
      case 'doc':
      case 'docx':
        return Icons.article_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateienAsync =
        ref.watch(auftragDateienProvider(widget.auftragId));
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Column(
      children: [
        // Upload-Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _isUploading ? null : _uploadFile,
            icon: _isUploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            label: Text(_isUploading ? 'Wird hochgeladen...' : 'Datei hochladen'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ),
        const Divider(height: 1),

        // Dateien-Liste
        Expanded(
          child: dateienAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Fehler: $e')),
            data: (dateien) {
              if (dateien.isEmpty) {
                return const Center(
                  child: Text('Keine Dateien vorhanden'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: dateien.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final datei = dateien[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _fileIcon(datei.dateiTyp),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      datei.dateiName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${datei.kategorieLabel} · ${_formatSize(datei.dateiGroesse)}'
                      '${datei.createdAt != null ? ' · ${dateFormat.format(datei.createdAt!)}' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (datei.fuerKundeSichtbar)
                          Tooltip(
                            message: 'Fuer Kunden sichtbar',
                            child: Icon(
                              Icons.visibility,
                              size: 18,
                              color: AppStatusColors.info,
                            ),
                          ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 20, color: AppStatusColors.error),
                          onPressed: () async {
                            await AuftragDateiRepository.delete(datei.id);
                            ref.invalidate(
                                auftragDateienProvider(widget.auftragId));
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
