import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BetriebsverwaltungScreen extends StatelessWidget {
  const BetriebsverwaltungScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/'),
        ),
        title: const Text('Betriebsverwaltung'),
      ),
      body: ListView(
        children: [
          // --- Firmenprofil ---
          _SectionHeader(title: 'FIRMENPROFIL'),
          ListTile(
            leading: Icon(Icons.business_outlined,
                color: theme.colorScheme.onSurfaceVariant),
            title: const Text('Firmenprofil bearbeiten'),
            subtitle: const Text('Name, Adresse, UID-Nummer'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/betrieb/firmenprofil'),
          ),
          ListTile(
            leading: Icon(Icons.account_balance_outlined,
                color: theme.colorScheme.onSurfaceVariant),
            title: const Text('Bankverbindungen'),
            subtitle: const Text('IBAN, Hauptkonto verwalten'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/betrieb/bankverbindungen'),
          ),
          ListTile(
            leading: Icon(Icons.image_outlined,
                color: theme.colorScheme.onSurfaceVariant),
            title: const Text('Firmenlogo'),
            subtitle: const Text('Logo hochladen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/betrieb/logo'),
          ),

          const Divider(height: 1),

          // --- Personal ---
          _SectionHeader(title: 'PERSONAL'),
          ListTile(
            leading: Icon(Icons.people_outline,
                color: theme.colorScheme.onSurfaceVariant),
            title: const Text('Mitarbeiter'),
            subtitle: const Text('Verwalten & einladen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/einstellungen/mitarbeiter'),
          ),
          ListTile(
            leading: Icon(Icons.security_outlined,
                color: theme.colorScheme.onSurfaceVariant),
            title: const Text('Berechtigungen'),
            subtitle: const Text('Modul-Zugriff pro Mitarbeiter'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/betrieb/berechtigungen'),
          ),
          ListTile(
            leading: Icon(Icons.payments_outlined,
                color: theme.colorScheme.onSurfaceVariant),
            title: const Text('Lohnabrechnung'),
            subtitle: const Text('Monatliche Loehne berechnen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/betrieb/lohn'),
          ),

          const Divider(height: 1),

          // --- Betrieb ---
          _SectionHeader(title: 'BETRIEB'),
          ListTile(
            leading: Icon(Icons.directions_car_outlined,
                color: theme.colorScheme.onSurfaceVariant),
            title: const Text('Fahrzeuge'),
            subtitle: const Text('Fuhrpark verwalten'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/einstellungen/fahrzeuge'),
          ),
          ListTile(
            leading: Icon(Icons.receipt_long_outlined,
                color: theme.colorScheme.onSurfaceVariant),
            title: const Text('MWST-Einstellungen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/buchhaltung/mwst/einstellungen'),
          ),
          ListTile(
            leading: Icon(Icons.health_and_safety_outlined,
                color: theme.colorScheme.onSurfaceVariant),
            title: const Text('Sozialversicherungen'),
            subtitle: const Text('AHV, ALV, BVG, UVG, KTG'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/betrieb/sozialversicherungen'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
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
}
