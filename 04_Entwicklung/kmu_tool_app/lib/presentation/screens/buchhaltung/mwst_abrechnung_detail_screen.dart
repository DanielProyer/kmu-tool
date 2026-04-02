import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/mwst_abrechnung.dart';
import 'package:kmu_tool_app/data/repositories/mwst_repository.dart';

final _abrechnungProvider =
    FutureProvider.family<MwstAbrechnung?, String>((ref, id) async {
  return MwstRepository().getAbrechnung(id);
});

class MwstAbrechnungDetailScreen extends ConsumerWidget {
  final String abrechnungId;

  const MwstAbrechnungDetailScreen({
    super.key,
    required this.abrechnungId,
  });

  static final _chf = NumberFormat.currency(
    locale: 'de_CH',
    symbol: 'CHF',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abrechnungAsync = ref.watch(_abrechnungProvider(abrechnungId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/'),
        ),
        title: const Text('MWST-Abrechnung'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (action) =>
                _handleAction(context, ref, action),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'eingereicht',
                child: ListTile(
                  leading: Icon(Icons.send),
                  title: Text('Als eingereicht markieren'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'bezahlt',
                child: ListTile(
                  leading: Icon(Icons.check_circle),
                  title: Text('Als bezahlt markieren'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: AppStatusColors.error),
                  title: Text('Loeschen',
                      style: TextStyle(color: AppStatusColors.error)),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: abrechnungAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (abrechnung) {
          if (abrechnung == null) {
            return const Center(child: Text('Abrechnung nicht gefunden'));
          }
          return _buildContent(context, abrechnung);
        },
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, String action) async {
    if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Abrechnung loeschen?'),
          content: const Text('Diese Aktion kann nicht rueckgaengig gemacht werden.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                  backgroundColor: AppStatusColors.error),
              child: const Text('Loeschen'),
            ),
          ],
        ),
      );
      if (confirm != true || !context.mounted) return;
      await MwstRepository().deleteAbrechnung(abrechnungId);
      if (context.mounted) context.pop();
    } else {
      await MwstRepository()
          .updateAbrechnungStatus(abrechnungId, action);
      ref.invalidate(_abrechnungProvider(abrechnungId));
    }
  }

  Widget _buildContent(BuildContext context, MwstAbrechnung a) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Header ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.periodeLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _StatusChip(status: a.status, label: a.statusLabel),
                    const SizedBox(width: 8),
                    Text(
                      a.isEffektiv
                          ? 'Effektive Methode'
                          : 'Saldosteuersatz',
                      style: TextStyle(
                          fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Teil I: Umsatz ──
        _SectionTitle('Teil I: Umsatz'),
        _FormRow('200', 'Total Entgelte', a.ziff200),
        _FormRow('220', 'Steuerbefreit', a.ziff220, indent: true),
        _FormRow('225', 'Ausgenommen', a.ziff225, indent: true),
        _FormRow('235', 'Entgeltsminderungen', a.ziff235, indent: true),
        _FormRow('280', 'Diverses', a.ziff280, indent: true),
        _FormRow('289', 'Total Abzuege', a.ziff289, isBold: true),
        _FormRow('299', 'Steuerbarer Umsatz', a.ziff299,
            isBold: true, highlight: true),
        const SizedBox(height: 16),

        // ── Teil II: Steuerberechnung ──
        _SectionTitle('Teil II: Steuerberechnung'),
        if (a.isEffektiv) ...[
          _FormRowDouble('302', 'Normalsatz 8.1%',
              a.ziff302Umsatz, a.ziff302Steuer),
          if (a.ziff312Steuer > 0)
            _FormRowDouble('312', 'Reduziert 2.6%',
                a.ziff312Umsatz, a.ziff312Steuer),
          if (a.ziff342Steuer > 0)
            _FormRowDouble('342', 'Beherbergung 3.8%',
                a.ziff342Umsatz, a.ziff342Steuer),
        ] else ...[
          _FormRowDouble('322', 'SSS 1',
              a.ziff322Umsatz, a.ziff322Steuer),
          if (a.ziff332Steuer > 0)
            _FormRowDouble('332', 'SSS 2',
                a.ziff332Umsatz, a.ziff332Steuer),
        ],
        if (a.ziff382 > 0)
          _FormRow('382', 'Bezugsteuer', a.ziff382),
        _FormRow('399', 'Total geschuldete Steuer', a.ziff399,
            isBold: true, highlight: true),
        const SizedBox(height: 16),

        // ── Teil III: Vorsteuer ──
        _SectionTitle('Teil III: Vorsteuer'),
        if (a.isEffektiv)
          _FormRow('400', 'Vorsteuer Material/DL', a.ziff400),
        _FormRow('405', 'Vorsteuer Investitionen', a.ziff405),
        _FormRow('479', 'Total Vorsteuer', a.ziff479,
            isBold: true, highlight: true),
        const SizedBox(height: 16),

        // ── Teil IV: Zahllast ──
        _SectionTitle('Teil IV: Zahllast'),
        if (a.istZahllast)
          _FormRow('500', 'An ESTV zu zahlen', a.ziff500,
              isBold: true, highlight: true, isNegative: true),
        if (a.istGuthaben)
          _FormRow('510', 'Guthaben', a.ziff510,
              isBold: true, highlight: true, isPositive: true),
        if (!a.istZahllast && !a.istGuthaben)
          _FormRow('500', 'Zahllast', 0,
              isBold: true, highlight: true),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final String label;

  const _StatusChip({required this.status, required this.label});

  Color _color(BuildContext context) {
    switch (status) {
      case 'entwurf':
        return AppStatusColors.warning;
      case 'eingereicht':
        return AppStatusColors.info;
      case 'bezahlt':
        return AppStatusColors.success;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  final String ziffer;
  final String label;
  final double betrag;
  final bool isBold;
  final bool indent;
  final bool highlight;
  final bool isNegative;
  final bool isPositive;

  static final _chf = NumberFormat.currency(
    locale: 'de_CH',
    symbol: 'CHF',
    decimalDigits: 2,
  );

  const _FormRow(
    this.ziffer,
    this.label,
    this.betrag, {
    this.isBold = false,
    this.indent = false,
    this.highlight = false,
    this.isNegative = false,
    this.isPositive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: indent ? 16 : 0,
        top: 6,
        bottom: 6,
      ),
      decoration: highlight
          ? BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              ziffer,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            _chf.format(betrag),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isNegative
                  ? AppStatusColors.error
                  : isPositive
                      ? AppStatusColors.success
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormRowDouble extends StatelessWidget {
  final String ziffer;
  final String label;
  final double umsatz;
  final double steuer;

  static final _chf = NumberFormat.currency(
    locale: 'de_CH',
    symbol: 'CHF',
    decimalDigits: 2,
  );

  const _FormRowDouble(
    this.ziffer,
    this.label,
    this.umsatz,
    this.steuer,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              ziffer,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _chf.format(umsatz),
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              Text(
                _chf.format(steuer),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
