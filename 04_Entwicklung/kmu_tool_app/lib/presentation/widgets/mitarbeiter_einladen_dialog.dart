import 'package:flutter/material.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/services/admin/user_creation_service.dart';
import 'package:kmu_tool_app/services/auth/betrieb_service.dart';

class MitarbeiterEinladenDialog extends StatefulWidget {
  const MitarbeiterEinladenDialog({super.key});

  /// Zeigt den Dialog und gibt true zurueck wenn ein User erstellt wurde.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (context) => const MitarbeiterEinladenDialog(),
    );
  }

  @override
  State<MitarbeiterEinladenDialog> createState() =>
      _MitarbeiterEinladenDialogState();
}

class _MitarbeiterEinladenDialogState
    extends State<MitarbeiterEinladenDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _rolle = 'mitarbeiter';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final ownerId = await BetriebService.getDataOwnerId();
      final password = _passwordController.text.trim().isEmpty
          ? null
          : _passwordController.text.trim();

      final result = await UserCreationService.createUser(
        email: _emailController.text.trim(),
        password: password,
        rolle: _rolle,
        betriebOwnerId: ownerId,
        sendResetEmail: password == null,
      );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppStatusColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppStatusColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: AppStatusColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mitarbeiter einladen'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Erstelle einen App-Zugang fuer einen Mitarbeiter. '
                'Der Mitarbeiter erhaelt eine E-Mail mit Zugangslink.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-Mail *',
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'mitarbeiter@firma.ch',
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'E-Mail ist erforderlich';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Ungueltige E-Mail-Adresse';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _rolle,
                decoration: const InputDecoration(
                  labelText: 'Rolle',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'vorarbeiter',
                    child: Text('Vorarbeiter'),
                  ),
                  DropdownMenuItem(
                    value: 'mitarbeiter',
                    child: Text('Mitarbeiter'),
                  ),
                  DropdownMenuItem(
                    value: 'kunde',
                    child: Text('Kunde'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _rolle = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Passwort (optional)',
                  prefixIcon: Icon(Icons.lock_outline),
                  helperText: 'Leer lassen = Reset-Mail wird gesendet',
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      value.length < 6) {
                    return 'Mindestens 6 Zeichen';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _submit,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.person_add, size: 18),
          label: const Text('Einladen'),
        ),
      ],
    );
  }
}
