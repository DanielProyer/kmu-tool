import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kmu_tool_app/data/models/website_section.dart';
import 'package:kmu_tool_app/presentation/providers/website_providers.dart';
import 'package:kmu_tool_app/services/storage/file_storage_service.dart';
import 'package:kmu_tool_app/services/website/website_service.dart';

class GalerieEditor extends ConsumerStatefulWidget {
  final WebsiteSection section;
  final String configId;
  const GalerieEditor(
      {super.key, required this.section, required this.configId});

  @override
  ConsumerState<GalerieEditor> createState() => _GalerieEditorState();
}

class _GalerieEditorState extends ConsumerState<GalerieEditor> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    setState(() => _uploading = true);
    try {
      for (final file in result.files) {
        if (file.bytes == null) continue;
        await WebsiteService.uploadGalleryImage(
          configId: widget.configId,
          bytes: file.bytes!,
          fileName: file.name,
        );
      }
      ref.invalidate(websiteGalleryProvider(widget.configId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final galleryAsync =
        ref.watch(websiteGalleryProvider(widget.configId));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Galerie',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _uploading ? null : _pickAndUpload,
            icon: _uploading
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add_photo_alternate),
            label: Text(_uploading ? 'Wird hochgeladen...' : 'Bilder hinzufuegen'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: galleryAsync.when(
              data: (images) {
                if (images.isEmpty) {
                  return const Center(
                      child: Text('Noch keine Bilder hochgeladen'));
                }
                return GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final img = images[index];
                    final url = FileStorageService.getWebsiteAssetPublicUrl(
                        img.storagePath);
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(url, fit: BoxFit.cover,
                              errorBuilder: (_, e, st) {
                            return Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: const Icon(Icons.broken_image),
                            );
                          }),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () async {
                              await WebsiteService.deleteGalleryImage(
                                  img.id);
                              ref.invalidate(websiteGalleryProvider(
                                  widget.configId));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Fehler: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
