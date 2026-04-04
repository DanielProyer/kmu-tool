import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/lohnabrechnung.dart';
import 'package:kmu_tool_app/data/models/mitarbeiter.dart';
import 'package:kmu_tool_app/data/repositories/lohnabrechnung_repository.dart';
import 'package:kmu_tool_app/data/repositories/mitarbeiter_repository.dart';
import 'package:kmu_tool_app/data/repositories/user_profile_repository.dart';
import 'package:kmu_tool_app/presentation/providers/betriebsverwaltung_provider.dart';
import 'package:kmu_tool_app/services/pdf/lohnabrechnung_pdf_service.dart';

class LohnDetailScreen extends ConsumerStatefulWidget {
  final String lohnabrechnungId;

  const LohnDetailScreen({super.key, required this.lohnabrechnungId});

  @override
  ConsumerState<LohnDetailScreen> createState() => _LohnDetailScreenState();
}

class _LohnDetailScreenState extends ConsumerState<LohnDetailScreen> {
  Lohnabrechnung? _abrechnung;
  Mitarbeiter? _mitarbeiter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final a = await LohnabrechnungRepository.getById(widget.lohnabrechnungId);
      if (a != null && mounted) {
        _abrechnung = a;
        _mitarbeiter = await MitarbeiterRepository.getById(a.mitarbeiterId);
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

  Future<void> _updateStatus(String newStatus) async {
    if (_abrechnung == null) return;
    setState(() => _isLoading = true);
    try {
      final updated = Lohnabrechnung(
        id: _abrechnung!.id,
        userId: _abrechnung!.userId,
        mitarbeiterId: _abrechnung!.mitarbeiterId,
        monat: _abrechnung!.monat,
        jahr: _abrechnung!.jahr,
        bruttolohn: _abrechnung!.bruttolohn,
        pensum: _abrechnung!.pensum,
        ahvAn: _abrechnung!.ahvAn,
        alvAn: _abrechnung!.alvAn,
        uvgNbuAn: _abrechnung!.uvgNbuAn,
        ktgAn: _abrechnung!.ktgAn,
        bvgAn: _abrechnung!.bvgAn,
        quellensteuer: _abrechnung!.quellensteuer,
        kinderzulagen: _abrechnung!.kinderzulagen,
        nettolohn: _abrechnung!.nettolohn,
        ahvAg: _abrechnung!.ahvAg,
        alvAg: _abrechnung!.alvAg,
        uvgBuAg: _abrechnung!.uvgBuAg,
        ktgAg: _abrechnung!.ktgAg,
        bvgAg: _abrechnung!.bvgAg,
        fakAg: _abrechnung!.fakAg,
        totalAgKosten: _abrechnung!.totalAgKosten,
        status: newStatus,
      );
      await LohnabrechnungRepository.save(updated);
      if (mounted) {
        _abrechnung = updated;
        ref.invalidate(lohnabrechnungDetailProvider(widget.lohnabrechnungId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status: ${updated.statusLabel}'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        setState(() {});
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

  Future<void> _exportPdf() async {
    if (_abrechnung == null || _mitarbeiter == null) return;
    try {
      final profile = await UserProfileRepository.getCurrentProfile();
      if (profile == null) return;

      await LohnabrechnungPdfService.generateAndPreview(
        abrechnung: _abrechnung!,
        mitarbeiter: _mitarbeiter!,
        profile: profile,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF-Fehler: $e'), backgroundColor: AppStatusColors.error),
        );
      }
    }
  }

  String _formatCHF(double amount) {
    return 'CHF ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading && _abrechnung == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lohnabrechnung')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_abrechnung == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lohnabrechnung')),
        body: const Center(child: Text('Nicht gefunden')),
      );
    }

    final a = _abrechnung!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_mitarbeiter?.displayName ?? 'Lohnabrechnung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'PDF exportieren',
            onPressed: _exportPdf,
          ),
          if (a.status == 'entwurf')
            TextButton(
              onPressed: () => _updateStatus('freigegeben'),
              child: const Text('Freigeben'),
            ),
          if (a.status == 'freigegeben')
            TextButton(
              onPressed: () => _updateStatus('ausbezahlt'),
              child: const Text('Ausbezahlt'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.periodeLabel,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text('Pensum: ${(a.pensum * 100).round()}%',
                            style: TextStyle(
                                color: colorScheme.onPrimaryContainer)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCHF(a.nettolohn),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onPrimaryContainer,
                              ),
                        ),
                        Text('Nettolohn',
                            style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bruttolohn
            _sectionHeader('BRUTTOLOHN'),
            _detailRow('Bruttolohn', _formatCHF(a.bruttolohn)),

            const SizedBox(height: 16),

            // AN-Abzuege
            _sectionHeader('ARBEITNEHMER-ABZUEGE'),
            if (a.ahvAn > 0) _detailRow('AHV/IV/EO', '- ${_formatCHF(a.ahvAn)}'),
            if (a.alvAn > 0) _detailRow('ALV', '- ${_formatCHF(a.alvAn)}'),
            if (a.uvgNbuAn > 0) _detailRow('UVG-NBU', '- ${_formatCHF(a.uvgNbuAn)}'),
            if (a.ktgAn > 0) _detailRow('KTG', '- ${_formatCHF(a.ktgAn)}'),
            if (a.bvgAn > 0) _detailRow('BVG', '- ${_formatCHF(a.bvgAn)}'),
            if (a.quellensteuer > 0)
              _detailRow('Quellensteuer', '- ${_formatCHF(a.quellensteuer)}'),
            _detailRow('Total Abzuege', '- ${_formatCHF(a.totalAnAbzuege)}',
                bold: true),

            if (a.kinderzulagen > 0) ...[
              const SizedBox(height: 16),
              _sectionHeader('ZULAGEN'),
              _detailRow('Kinderzulagen', '+ ${_formatCHF(a.kinderzulagen)}'),
            ],

            const SizedBox(height: 16),
            const Divider(),
            _detailRow('NETTOLOHN', _formatCHF(a.nettolohn), bold: true),
            const Divider(),

            const SizedBox(height: 24),

            // AG-Kosten
            _sectionHeader('ARBEITGEBER-KOSTEN'),
            if (a.ahvAg > 0) _detailRow('AHV/IV/EO', _formatCHF(a.ahvAg)),
            if (a.alvAg > 0) _detailRow('ALV', _formatCHF(a.alvAg)),
            if (a.uvgBuAg > 0) _detailRow('UVG-BU', _formatCHF(a.uvgBuAg)),
            if (a.ktgAg > 0) _detailRow('KTG', _formatCHF(a.ktgAg)),
            if (a.bvgAg > 0) _detailRow('BVG', _formatCHF(a.bvgAg)),
            if (a.fakAg > 0) _detailRow('FAK', _formatCHF(a.fakAg)),
            _detailRow('Total AG-Kosten', _formatCHF(a.totalAgKosten),
                bold: true),

            const SizedBox(height: 16),
            _detailRow('Gesamtkosten Arbeitgeber',
                _formatCHF(a.bruttolohn + a.totalAgKosten),
                bold: true),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                fontSize: bold ? 15 : 14,
              )),
          Text(value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                fontSize: bold ? 15 : 14,
              )),
        ],
      ),
    );
  }
}
