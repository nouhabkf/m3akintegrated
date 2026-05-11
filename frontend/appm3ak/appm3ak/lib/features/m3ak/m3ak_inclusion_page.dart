import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as pv;

import '../../m3ak_port/m3ak_home_screen.dart';
import '../../m3ak_port/services/user_history_manager.dart';
import '../../providers/auth_providers.dart';

/// Hub M3AK (Braille, LSF, chatbot signes, visage…) avec le même [UserHistoryManager] que l’ancienne app.
class M3akInclusionPage extends ConsumerWidget {
  const M3akInclusionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final historyUserId = (user == null || user.id.isEmpty) ? 1 : user.id.hashCode;

    return pv.MultiProvider(
      providers: [
        pv.Provider<UserHistoryManager>(
          create: (_) => UserHistoryManager(userId: historyUserId),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('M3AK — Inclusion'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const M3akHomeScreen(),
      ),
    );
  }
}
