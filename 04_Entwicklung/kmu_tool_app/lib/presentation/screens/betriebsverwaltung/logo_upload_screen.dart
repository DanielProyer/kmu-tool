import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/repositories/user_profile_repository.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:image_picker/image_picker.dart';

class LogoUploadScreen extends ConsumerStatefulWidget {
  const LogoUploadScreen({super.key});

  @override
  ConsumerState<LogoUploadScreen> createState() => _LogoUploadScreenState();
}

class _LogoUploadScreenState extends ConsumerState<LogoUploadScreen> {
  String? _logoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLogo();
  }

  Future<void> _loadLogo() async {
    setState(() => _isLoading = true);
    try {
      final profile = await UserProfileRepository.getCurrentProfile();
      if (profile != null && mounted) {
        setState(() => _logoUrl = profile.logoUrl);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() => _isLoading = true);

      final userId = SupabaseService.currentUser!.id;
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last;
      final path = '$userId/logo.$ext';

      await SupabaseService.client.storage
          .from('firmen-logos')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = SupabaseService.client.storage
          .from('firmen-logos')
          .getPublicUrl(path);

      await UserProfileRepository.updateFields({'logo_url': url});

      if (mounted) {
        setState(() => _logoUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logo hochgeladen'),
            backgroundColor: AppStatusColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: AppStatusColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeLogo() async {
    setState(() => _isLoading = true);
    try {
      await UserProfileRepository.updateFields({'logo_url': null});
      if (mounted) {
        setState(() => _logoUrl = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logo entfernt'),
            backgroundColor: AppStatusColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppStatusColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firmenlogo'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outline),
                      ),
                      child: _logoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                _logoUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, e, s) => Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.image_outlined,
                              size: 64,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _pickAndUpload,
                      icon: const Icon(Icons.upload),
                      label: Text(
                          _logoUrl != null ? 'Logo ersetzen' : 'Logo hochladen'),
                    ),
                    if (_logoUrl != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _removeLogo,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Logo entfernen'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Empfohlen: Quadratisch, max. 512x512px\nWird auf Rechnungen und PDFs angezeigt',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
