import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../providers/auth_providers.dart';
import 'community_proches_screen.dart';

/// Enveloppe avec AppBar pour ouvrir le cercle de confiance hors onglet.
class CommunityContactsRouteScreen extends ConsumerWidget {
  const CommunityContactsRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final nav = Navigator.of(context);
            if (nav.canPop()) {
              nav.pop();
            } else {
              context.go('/home?tab=4');
            }
          },
        ),
        title: Text(strings.communityCircleOfTrust),
      ),
      body: const CommunityProchesScreen(),
    );
  }
}

