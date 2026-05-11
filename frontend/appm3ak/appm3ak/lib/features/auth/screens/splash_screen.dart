import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  /// Évite de programmer plusieurs redirections si le widget rebuild en AsyncData.
  bool _navigationScheduled = false;

  static const Duration _minSplash = Duration(milliseconds: 500);

  void _scheduleRedirect(Future<void> Function() go) {
    if (_navigationScheduled) return;
    _navigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(_minSplash);
      if (!mounted) return;
      await go();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    auth.when(
      data: (user) {
        _scheduleRedirect(() async {
          if (!mounted) return;
          if (user != null) {
            context.go('/home');
          } else {
            context.go('/login');
          }
        });
      },
      loading: () {},
      error: (_, _) {
        _scheduleRedirect(() async {
          if (mounted) context.go('/login');
        });
      },
    );

    final strings = AppStrings.fr();
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: strings.appTitle,
              child: AppLogo(
                size: 96,
                borderRadius: 20,
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              label: strings.appTitle,
              child: Text(
                strings.appTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 32),
            Semantics(
              label: strings.splashLoading,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
