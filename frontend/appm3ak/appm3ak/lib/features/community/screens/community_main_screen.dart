import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../providers/auth_providers.dart';
import 'community_posts_screen.dart';

/// Écran principal du module Communauté — variante posts-only.
class CommunityMainScreen extends ConsumerStatefulWidget {
  const CommunityMainScreen({super.key, this.initialTabIndex = 0});

  /// Conservé pour compatibilité d'API, non utilisé en mode posts-only.
  final int initialTabIndex;

  @override
  ConsumerState<CommunityMainScreen> createState() => _CommunityMainScreenState();
}

class _CommunityMainScreenState extends ConsumerState<CommunityMainScreen> {

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(strings.community),
        actions: [
          IconButton(
            tooltip: strings.communityCircleOfTrust,
            onPressed: () => context.push('/community-contacts'),
            icon: const Icon(Icons.group_outlined),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mode posts-only: sections lieux / proximité / demandes masquées.
          const Expanded(child: CommunityPostsScreen()),
        ],
      ),
    );
  }
}

