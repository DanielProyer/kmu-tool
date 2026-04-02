import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'widgets/notizen_tab.dart';
import 'widgets/dateien_tab.dart';
import 'widgets/zugriff_tab.dart';

class AuftragDashboardScreen extends ConsumerWidget {
  final String auftragId;

  const AuftragDashboardScreen({super.key, required this.auftragId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.canPop(context)
                ? context.pop()
                : context.go('/auftraege'),
          ),
          title: const Text('Auftrag-Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.note_outlined), text: 'Notizen'),
              Tab(icon: Icon(Icons.folder_outlined), text: 'Dateien'),
              Tab(icon: Icon(Icons.group_outlined), text: 'Zugriff'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            NotizenTab(auftragId: auftragId),
            DateienTab(auftragId: auftragId),
            ZugriffTab(auftragId: auftragId),
          ],
        ),
      ),
    );
  }
}
