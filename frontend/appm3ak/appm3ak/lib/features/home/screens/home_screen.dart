import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../providers/auth_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final strings =
            AppStrings.fromPreferredLanguage(user.preferredLanguage?.name);
        return Scaffold(
          appBar: AppBar(
            title: Text(strings.appTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () => context.push('/profile'),
                tooltip: strings.profile,
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                tooltip: strings.logout,
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  '${strings.home}, ${user.displayName}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                if (user.isBeneficiary) ...[
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: Text(strings.myAccompagnants),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => context.push('/accompagnants'),
                    minVerticalPadding: 16,
                  ),
                ],
                if (user.isCompanion) ...[
                  ListTile(
                    leading: const Icon(Icons.accessible),
                    title: Text(strings.myBeneficiaires),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => context.push('/beneficiaires'),
                    minVerticalPadding: 16,
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(AppStrings.fr().errorGeneric),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: Text(AppStrings.fr().login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
