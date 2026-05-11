import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_strings.dart';
import '../../providers/auth_providers.dart';
import '../community/screens/community_nearby_places_screen.dart';

/// Onglet **Lieux** : cartographie accessibilité — lieux à proximité et liens rapides.
class AccessibilityTabScreen extends ConsumerWidget {
  const AccessibilityTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(strings.navLieux),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => context.push('/community-locations'),
                  icon: const Icon(Icons.list_alt_outlined),
                  label: Text(strings.communityPlaces),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => context.push('/community-nearby'),
                  icon: const Icon(Icons.near_me_outlined),
                  label: Text(strings.nearbyPlacesNav),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => context.push('/submit-location'),
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: Text(strings.submitNewPlace),
                ),
              ],
            ),
          ),
          const Expanded(
            child: CommunityNearbyPlacesScreen(embedded: true),
          ),
        ],
      ),
    );
  }
}
