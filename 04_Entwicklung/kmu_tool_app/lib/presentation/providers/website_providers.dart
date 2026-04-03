import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmu_tool_app/data/models/website_config.dart';
import 'package:kmu_tool_app/data/models/website_section.dart';
import 'package:kmu_tool_app/data/models/website_gallery_image.dart';
import 'package:kmu_tool_app/data/models/website_anfrage.dart';
import 'package:kmu_tool_app/data/repositories/website_config_repository.dart';
import 'package:kmu_tool_app/data/repositories/website_section_repository.dart';
import 'package:kmu_tool_app/data/repositories/website_gallery_repository.dart';
import 'package:kmu_tool_app/data/repositories/website_anfrage_repository.dart';

// ─── Website Config ───

final websiteConfigProvider =
    AsyncNotifierProvider<WebsiteConfigNotifier, WebsiteConfig?>(
  WebsiteConfigNotifier.new,
);

class WebsiteConfigNotifier extends AsyncNotifier<WebsiteConfig?> {
  @override
  Future<WebsiteConfig?> build() async {
    return WebsiteConfigRepository.getByCurrentUser();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => WebsiteConfigRepository.getByCurrentUser());
  }
}

// ─── Website Sections ───

final websiteSectionsProvider =
    FutureProvider.family<List<WebsiteSection>, String>(
  (ref, configId) => WebsiteSectionRepository.getByConfig(configId),
);

// ─── Website Gallery ───

final websiteGalleryProvider =
    FutureProvider.family<List<WebsiteGalleryImage>, String>(
  (ref, configId) => WebsiteGalleryRepository.getByConfig(configId),
);

// ─── Website Anfragen ───

final websiteAnfragenProvider =
    FutureProvider.family<List<WebsiteAnfrage>, String>(
  (ref, configId) => WebsiteAnfrageRepository.getByConfig(configId),
);

final websiteUnreadCountProvider =
    FutureProvider.family<int, String>(
  (ref, configId) => WebsiteAnfrageRepository.getUnreadCount(configId),
);
