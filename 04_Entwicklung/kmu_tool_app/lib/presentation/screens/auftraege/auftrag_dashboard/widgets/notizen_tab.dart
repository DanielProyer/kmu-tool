import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/auftrag_notiz.dart';
import 'package:kmu_tool_app/data/repositories/auftrag_notiz_repository.dart';
import 'package:kmu_tool_app/presentation/providers/auftrag_dashboard_provider.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

class NotizenTab extends ConsumerStatefulWidget {
  final String auftragId;

  const NotizenTab({super.key, required this.auftragId});

  @override
  ConsumerState<NotizenTab> createState() => _NotizenTabState();
}

class _NotizenTabState extends ConsumerState<NotizenTab> {
  final _controller = TextEditingController();
  bool _isSending = false;

  Future<void> _addNotiz() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final userId = SupabaseService.client.auth.currentUser!.id;
      await AuftragNotizRepository.create(AuftragNotiz(
        id: '',
        auftragId: widget.auftragId,
        userId: userId,
        typ: 'text',
        inhalt: text,
      ));
      _controller.clear();
      ref.invalidate(auftragNotizenProvider(widget.auftragId));
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
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notizenAsync =
        ref.watch(auftragNotizenProvider(widget.auftragId));
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Column(
      children: [
        // Eingabefeld
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Notiz hinzufuegen...',
                    isDense: true,
                  ),
                  maxLines: 2,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _addNotiz(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _isSending ? null : _addNotiz,
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Notizen-Liste
        Expanded(
          child: notizenAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Fehler: $e')),
            data: (notizen) {
              if (notizen.isEmpty) {
                return const Center(
                  child: Text('Keine Notizen vorhanden'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: notizen.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final notiz = notizen[index];
                  return _NotizTile(
                    notiz: notiz,
                    dateFormat: dateFormat,
                    onDelete: () async {
                      await AuftragNotizRepository.delete(notiz.id);
                      ref.invalidate(
                          auftragNotizenProvider(widget.auftragId));
                    },
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

class _NotizTile extends StatelessWidget {
  final AuftragNotiz notiz;
  final DateFormat dateFormat;
  final VoidCallback onDelete;

  const _NotizTile({
    required this.notiz,
    required this.dateFormat,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        notiz.typ == 'foto'
            ? Icons.photo_outlined
            : notiz.typ == 'pdf'
                ? Icons.picture_as_pdf_outlined
                : Icons.note_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        notiz.inhalt ?? notiz.dateiName ?? 'Notiz',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: notiz.createdAt != null
          ? Text(
              dateFormat.format(notiz.createdAt!),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: IconButton(
        icon: Icon(Icons.delete_outline,
            size: 20, color: AppStatusColors.error),
        onPressed: onDelete,
      ),
    );
  }
}
