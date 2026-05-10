import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/app_strings.dart';
import '../features/accompaniment/screens/emergency_contacts_screen.dart';
import '../features/accompaniment/screens/transport_requests_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/community/screens/community_contacts_route_screen.dart';
import '../features/community/screens/community_locations_screen.dart';
import '../features/community/screens/community_main_screen.dart';
import '../features/community/screens/community_nearby_places_screen.dart';
import '../features/community/screens/create_help_request_screen.dart';
import '../features/accessibility/accessibility_post_handoff.dart';
import '../features/accessibility/head_gesture_post_screen.dart';
import '../features/accessibility/vibration_coded_post_screen.dart';
import '../features/accessibility/voice_vibration_post_screen.dart';
import '../features/community/screens/create_post_screen.dart';
import '../features/community/services/post_detail_assistance/post_detail_assistance_models.dart';
import '../data/models/help_request_model.dart';
import '../features/community/screens/help_request_detail_screen.dart';
import '../features/community/screens/help_requests_screen.dart';
import '../features/community/screens/haptic_help_screen.dart';
import '../features/community/screens/location_detail_screen.dart';
import '../features/community/screens/post_detail_screen.dart';
import '../features/community/screens/submit_location_screen.dart';
import '../features/sos/screens/sos_alerts_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/home/screens/main_shell.dart';
import '../features/m3ak/m3ak_inclusion_page.dart';
import '../features/profile/screens/profile_screen.dart';
import '../m3ak_assist/m3ak_nav_key.dart';
import '../m3ak_assist/m3ak_create_post_launch.dart';
import '../core/config/app_config.dart';
import '../providers/auth_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRefresh = ValueNotifier<int>(0);
  ref.onDispose(authRefresh.dispose);
  ref.listen(authStateProvider, (_, _) {
    authRefresh.value++;
  });

  final auth = ref.watch(authStateProvider);
  final user = auth.valueOrNull;

  return GoRouter(
    navigatorKey: m3akRootNavigatorKey,
    initialLocation: '/',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final loc = state.uri.path;

      const publicPaths = <String>{'/', '/login', '/register'};
      final isPublic = publicPaths.contains(loc);

      if (auth.isLoading) {
        return isPublic ? null : '/';
      }

      if (AppConfig.allowGuest) {
        if (loc == '/' || loc == '/login' || loc == '/register') {
          return '/home';
        }
        return null;
      }

      if (user == null) {
        return isPublic ? null : '/login';
      }

      if (loc == '/login' || loc == '/register' || loc == '/') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (c, state) {
          final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
          final communityTab =
              int.tryParse(state.uri.queryParameters['communityTab'] ?? '') ?? 0;
          return MainShell(
            initialIndex: tab.clamp(0, 4),
            communityTabIndex: communityTab.clamp(0, 3),
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const MainShell(initialIndex: 4),
      ),
      GoRoute(
        path: '/profile-edit',
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/accompagnants',
        builder: (_, _) => const EmergencyContactsScreen(),
      ),
      GoRoute(
        path: '/beneficiaires',
        builder: (_, _) => const TransportRequestsScreen(),
      ),
      GoRoute(
        path: '/sos-alerts',
        builder: (_, _) => const SosAlertsScreen(),
      ),
      GoRoute(
        path: '/community-locations',
        builder: (_, _) => const CommunityLocationsScreen(),
      ),
      GoRoute(
        path: '/community-nearby',
        builder: (_, _) =>
            const CommunityNearbyPlacesScreen(embedded: false),
      ),
      GoRoute(
        path: '/community-contacts',
        builder: (_, _) => const CommunityContactsRouteScreen(),
      ),
      GoRoute(
        path: '/location-detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return LocationDetailScreen(locationId: id);
        },
      ),
      GoRoute(
        path: '/submit-location',
        builder: (_, _) => const SubmitLocationScreen(),
      ),
      GoRoute(
        path: '/community-posts',
        builder: (_, _) => const CommunityMainScreen(initialTabIndex: 1),
      ),
      GoRoute(
        path: '/create-post',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is M3akCreatePostLaunch) {
            return CreatePostScreen(
              initialContent: extra.initialContent,
              autoOpenCamera: extra.autoOpenCamera,
              autoPublishAfterCamera: extra.autoPublishAfterCamera,
            );
          }
          if (extra is AccessibilityPostHandoff) {
            return CreatePostScreen(initialAccessibilityHandoff: extra);
          }
          final initial = extra is String ? extra : null;
          return CreatePostScreen(initialContent: initial);
        },
      ),
      GoRoute(
        path: '/create-post-head-gesture',
        builder: (_, _) => const HeadGesturePostScreen(),
      ),
      GoRoute(
        path: '/create-post-vibration',
        builder: (_, _) => const VibrationCodedPostScreen(),
      ),
      GoRoute(
        path: '/create-post-voice-vibration',
        builder: (_, _) => const VoiceVibrationPostScreen(),
      ),
      GoRoute(
        path: '/post-detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PostDetailScreen(postId: id);
        },
      ),
      GoRoute(
        path: '/help-requests',
        builder: (_, _) => const HelpRequestsScreen(),
      ),
      GoRoute(
        path: '/help-request-detail',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is HelpRequestModel) {
            return HelpRequestDetailScreen(request: extra);
          }
          return Scaffold(
            appBar: AppBar(title: Text(AppStrings.fr().helpRequestDetailTitle)),
            body: Center(child: Text(AppStrings.fr().errorGeneric)),
          );
        },
      ),
      GoRoute(
        path: '/create-help-request',
        builder: (_, state) {
          final extra = state.extra;
          return CreateHelpRequestScreen(
            initialPrefill:
                extra is HelpRequestFromPostPrefill ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/haptic-help',
        builder: (_, _) => const HapticHelpScreen(),
      ),
      GoRoute(
        path: '/m3ak-inclusion',
        builder: (_, _) => const M3akInclusionPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page non trouvée: ${state.uri}'),
      ),
    ),
  );
});
