import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../providers/auth_providers.dart';
import '../../community/screens/community_main_screen.dart';
import '../../profile/screens/profile_tab.dart';
import 'home_companion_tab.dart';
import 'home_tab.dart';

/// Shell principal après connexion (export léger : onglet Santé = placeholder).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({
    super.key,
    this.initialIndex = 0,
    this.communityTabIndex = 0,
  });

  final int initialIndex;
  final int communityTabIndex;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _currentIndex = widget.initialIndex.clamp(0, 4);
    }
  }

  void _goTab(int index) {
    final i = index.clamp(0, 4);
    if (mounted) {
      setState(() => _currentIndex = i);
    }
    if (i == 3) {
      final uri = GoRouterState.of(context).uri;
      final ct = uri.queryParameters['communityTab'];
      final params = <String, String>{'tab': '3'};
      if (ct != null && ct.isNotEmpty) params['communityTab'] = ct;
      context.go(Uri(path: '/home', queryParameters: params).toString());
    } else {
      context.go(
        Uri(path: '/home', queryParameters: {'tab': '$i'}).toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        final theme = Theme.of(context);
        final primary = theme.colorScheme.primary;

        Widget body;
        switch (_currentIndex) {
          case 0:
            body = user.isBeneficiary
                ? const HomeTab()
                : const HomeCompanionTab();
            break;
          case 1:
            body = _PlaceholderTab(
              title: strings.health,
              subtitle:
                  'Module Santé non inclus dans cet export (ZIP < 25 Mo).',
            );
            break;
          case 2:
            body = _PlaceholderTab(title: strings.transport);
            break;
          case 3:
            body = CommunityMainScreen(
              initialTabIndex: widget.communityTabIndex,
            );
            break;
          case 4:
            body = const ProfileTab();
            break;
          default:
            body = const HomeTab();
        }

        return Scaffold(
          body: body,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home,
                      label: strings.home,
                      selected: _currentIndex == 0,
                      primary: primary,
                      onTap: () => _goTab(0),
                    ),
                    _NavItem(
                      icon: Icons.medical_services_outlined,
                      activeIcon: Icons.medical_services,
                      label: strings.health,
                      selected: _currentIndex == 1,
                      primary: primary,
                      onTap: () => _goTab(1),
                    ),
                    _NavItem(
                      icon: Icons.directions_bus_outlined,
                      activeIcon: Icons.directions_bus,
                      label: strings.transport,
                      selected: _currentIndex == 2,
                      primary: primary,
                      onTap: () => _goTab(2),
                    ),
                    _NavItem(
                      icon: Icons.location_city_outlined,
                      activeIcon: Icons.location_city,
                      label: strings.places,
                      selected: _currentIndex == 3,
                      primary: primary,
                      onTap: () => _goTab(3),
                    ),
                    _NavItem(
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: strings.profile,
                      selected: _currentIndex == 4,
                      primary: primary,
                      onTap: () => _goTab(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, err) => Scaffold(
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? activeIcon : icon,
              size: 26,
              color: selected ? primary : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: selected ? primary : Colors.grey,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                subtitle ?? '$title — Bientôt disponible',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
