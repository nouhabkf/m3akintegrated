import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/app_strings.dart';
import '../features/accompaniment/screens/emergency_contacts_screen.dart';
import '../features/accompaniment/screens/transport_requests_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/community/screens/community_contacts_route_screen.dart';
import '../features/community/screens/community_ai_entry_screen.dart';
import '../features/community/screens/community_locations_screen.dart';
import '../features/community/screens/community_live_screen.dart';
import '../features/community/screens/messages_screen.dart';
import '../features/community/screens/chat_screen.dart';
import '../features/community/screens/community_nearby_places_screen.dart';
import '../features/community/screens/create_help_request_screen.dart';
import '../features/accessibility/accessibility_post_handoff.dart';
import '../features/accessibility/screens/reservation_screen.dart';
import '../features/accessibility/screens/reservations_history_screen.dart';
import '../features/accessibility/head_gesture_post_screen.dart';
import '../features/accessibility/vibration_coded_post_screen.dart';
import '../features/accessibility/voice_vibration_post_screen.dart';
import '../features/community/screens/create_post_screen.dart';
import '../features/community/services/post_detail_assistance/post_detail_assistance_models.dart';
import '../data/models/help_request_model.dart';
import '../data/models/community_action_plan_result.dart';
import '../features/community/screens/help_request_detail_screen.dart';
import '../features/community/screens/help_requests_screen.dart';
import '../features/community/screens/haptic_help_screen.dart';
import '../features/community/screens/location_detail_screen.dart';
import '../features/community/screens/post_detail_screen.dart';
import '../features/community/screens/submit_location_screen.dart';
import '../features/medical/screens/medical_record_screen.dart';
import '../features/sos/screens/sos_alerts_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/home/screens/main_shell.dart';
import '../features/health/models/health_chat_launch.dart';
import '../features/health/screens/health_ai_chat_screen.dart';
import '../features/medical/screens/activity_posture_detection_screen.dart';
import '../features/m3ak/m3ak_inclusion_page.dart';
import '../features/profile/screens/profile_screen.dart';
import '../m3ak_assist/m3ak_nav_key.dart';
import '../m3ak_assist/m3ak_create_post_launch.dart';
import '../core/config/app_config.dart';
import '../providers/auth_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Force GoRouter to reevaluate redirects on auth changes.
  final authRefresh = ValueNotifier<int>(0);
  ref.onDispose(authRefresh.dispose);
  ref.listen(authStateProvider, (_, _) {
    authRefresh.value++;
  });

  // Ne pas `watch` l’auth ici : ça recréait GoRouter à chaque transition (loading→data),
  // ce qui peut laisser l’écran vide. On lit l’état à la demande dans `redirect` uniquement.
  return GoRouter(
    navigatorKey: m3akRootNavigatorKey,
    initialLocation: '/',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final user = auth.valueOrNull;
      final loc = state.uri.path;

      // Public routes
      const publicPaths = <String>{'/', '/login', '/register'};
      final isPublic = publicPaths.contains(loc);

      // While auth is loading, stay on splash (or allow current if public).
      if (auth.isLoading) {
        return isPublic ? null : '/';
      }

      // Demo/Device mode: allow navigating without auth.
      if (AppConfig.allowGuest) {
        // Avoid staying stuck on splash/login when guest mode is enabled.
        if (loc == '/' || loc == '/login' || loc == '/register') {
          return '/home';
        }
        return null;
      }

      // Not logged in → block all private routes.
      if (user == null) {
        return isPublic ? null : '/login';
      }

      // Logged in → prevent going back to login/register.
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
        path: '/sante',
        redirect: (_, _) => '/home?tab=1',
      ),
      GoRoute(
        path: '/home',
        builder: (c, state) {
          final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
          final communityTab =
              int.tryParse(state.uri.queryParameters['communityTab'] ?? '') ?? 0;
          return MainShell(
            initialIndex: tab.clamp(0, 5),
            communityTabIndex: communityTab.clamp(0, 3),
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const MainShell(initialIndex: 5),
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
        path: '/medical-record',
        builder: (_, _) => const MedicalRecordScreen(),
      ),
      GoRoute(
        path: '/activity-posture-detection',
        builder: (_, _) => const ActivityPostureDetectionScreen(),
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
        path: '/community-ai-entry',
        builder: (_, _) => const CommunityAiEntryScreen(),
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
      // Routes pour Posts
      GoRoute(
        path: '/community-posts',
        redirect: (_, _) => '/home?tab=4',
      ),
      GoRoute(
        path: '/community-live',
        builder: (_, state) {
          final q = state.uri.queryParameters;
          final postId = q['postId'];
          final isHost = q['host'] == '1';
          return CommunityLiveScreen(postId: postId, isHost: isHost);
        },
      ),
      GoRoute(
        path: '/messages',
        builder: (_, _) => const MessagesScreen(),
      ),
      GoRoute(
        path: '/chat/:userId',
        builder: (_, state) {
          final userId = state.pathParameters['userId'] ?? '';
          final name = state.uri.queryParameters['name'];
          return ChatScreen(userId: userId, userName: name);
        },
      ),
      GoRoute(
        path: '/create-post',
        builder: (_, state) {
          final hintParam = state.uri.queryParameters['accessibilityContentHint'];
          final hint = (hintParam != null && hintParam.trim().isNotEmpty)
              ? hintParam.trim()
              : null;
          final extra = state.extra;
          if (extra is M3akCreatePostLaunch) {
            return CreatePostScreen(
              initialContent: extra.initialContent,
              autoOpenCamera: extra.autoOpenCamera,
              autoPublishAfterCamera: extra.autoPublishAfterCamera,
              accessibilityAnnounceGalleryVolumeOrCameraFallback:
                  extra.accessibilityAnnounceGalleryVolumeOrCameraFallback,
              contentHintOverride: hint,
            );
          }
          if (extra is AccessibilityPostHandoff) {
            return CreatePostScreen(
              initialAccessibilityHandoff: extra,
              contentHintOverride: hint,
            );
          }
          if (extra is CommunityActionPlanResult) {
            return CreatePostScreen(
              initialAiPlan: extra,
              contentHintOverride: hint,
            );
          }
          final initial = extra is String ? extra : null;
          return CreatePostScreen(
            initialContent: initial,
            contentHintOverride: hint,
          );
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
          final q = state.uri.queryParameters;
          final autoReadPost = q['autoReadPost'] == '1';
          final autoReadComments = q['autoReadComments'] == '1';
          final autoReadSummary = q['autoReadSummary'] == '1';
          final mode = q['mode'];
          final audioSelectionMode =
              (mode == 'readPost' || mode == 'readComments' || mode == 'voiceComment')
              ? mode
              : null;
          return PostDetailScreen(
            postId: id,
            autoReadPost: autoReadPost,
            autoReadComments: autoReadComments,
            autoReadSummary: autoReadSummary,
            audioSelectionMode: audioSelectionMode,
          );
        },
      ),
      /// Alias module Accessibilité (`community_post_source.routePath`).
      GoRoute(
        path: '/community/post-detail/:postId',
        redirect: (_, state) {
          final id = state.pathParameters['postId'] ?? '';
          return '/post-detail/$id';
        },
      ),
      // Routes pour Help Requests
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
            initialAiPlan:
                extra is CommunityActionPlanResult ? extra : null,
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
      GoRoute(
        path: '/reserve-access',
        builder: (context, state) {
          final extra = state.extra;
          final name =
              extra is String && extra.trim().isNotEmpty ? extra.trim() : '';
          return ReservationScreen(placeName: name);
        },
      ),
      GoRoute(
        path: '/reservations-history',
        builder: (_, _) => const ReservationsHistoryScreen(),
      ),
      GoRoute(
        path: '/health-chat',
        builder: (context, state) {
          final extra = state.extra;
          String? initial;
          if (extra is HealthChatLaunch) {
            initial = extra.initialMessage;
          } else if (extra is String) {
            initial = extra;
          }
          return Consumer(
            builder: (context, ref, _) {
              final auth = ref.watch(authStateProvider);
              return auth.when(
                data: (user) {
                  if (user == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) context.go('/login');
                    });
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final strings = AppStrings.fromPreferredLanguage(
                    user.preferredLanguage?.name,
                  );
                  final launchUser =
                      extra is HealthChatLaunch ? extra.user : null;
                  return HealthAiChatScreen(
                    strings: strings,
                    initialUserMessage: initial,
                    userProfile: launchUser ?? user,
                  );
                },
                loading: () => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Scaffold(
                  body: Center(child: Text(AppStrings.fr().errorGeneric)),
                ),
              );
            },
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page non trouvée: ${state.uri}'),
      ),
    ),
  );
});
