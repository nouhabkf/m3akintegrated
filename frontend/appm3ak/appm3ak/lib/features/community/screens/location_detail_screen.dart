import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/read_aloud_button.dart';
import '../../../data/models/location_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/location_repository.dart';
import '../../accessibility/accessibility_motor_prefs.dart';
import '../../accessibility/widgets/motor_accessible_action.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/community_providers.dart';

/// Détecte un handicap moteur (libellés API possibles).
bool _isMotorHandicap(String? typeHandicap) {
  if (typeHandicap == null) return false;
  final t = typeHandicap.trim().toUpperCase();
  return t == 'MOTOR' ||
      t == 'MOTEUR' ||
      t == 'HANDICAP_MOTEUR' ||
      t.contains('MOTEUR');
}

/// `null` ou inconnu → saisie assistée par défaut ; moteur → assistée ; autres types → formulaire classique.
bool _useAiAssistForReport(String? typeHandicap) {
  if (typeHandicap == null || typeHandicap.trim().isEmpty) return true;
  return _isMotorHandicap(typeHandicap);
}

Future<void> _openDirections(
  BuildContext context,
  LocationModel location,
  AppStrings strings,
) async {
  HapticFeedback.selectionClick();
  final lat = location.latitude;
  final lng = location.longitude;
  if (lat == 0 && lng == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.coordinatesUnavailable)),
    );
    return;
  }
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
  );
  if (!context.mounted) return;
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.couldNotOpenMaps)),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.couldNotOpenMaps)),
      );
    }
  }
}

void _openReport(
  BuildContext context,
  UserModel? user,
  LocationModel location,
  AppStrings strings,
) {
  HapticFeedback.mediumImpact();
  final assist = _useAiAssistForReport(user?.typeHandicap);
  final prefix = assist ? strings.reportDraftAssistPrefix : '';
  final body =
      '$prefix${strings.reportLocationDraftTitle(location.nom, location.fullAddress)}';
  context.push('/create-post', extra: body);
}

void _safeBackToCommunity(BuildContext context) {
  try {
    if (context.canPop()) {
      context.pop();
      return;
    }
    if (context.mounted) {
      context.go('/home');
    }
  } catch (_) {
    if (context.mounted) {
      try {
        context.go('/home');
      } catch (_) {}
    }
  }
}

class _MotorSettings {
  const _MotorSettings({
    required this.enabled,
    required this.padding,
    required this.dwellEnabled,
    required this.dwellMs,
    required this.largeButtons,
  });

  final bool enabled;
  final double padding;
  final bool dwellEnabled;
  final int dwellMs;
  final bool largeButtons;
}

Future<_MotorSettings> _loadMotorSettings() async {
  final enabled = await AccessibilityMotorPrefs.magneticEnabled();
  final padding = await AccessibilityMotorPrefs.magneticPadding();
  final dwellEnabled = await AccessibilityMotorPrefs.dwellEnabled();
  final dwellMs = await AccessibilityMotorPrefs.dwellMs();
  final largeButtons = await AccessibilityMotorPrefs.largeButtons();
  return _MotorSettings(
    enabled: enabled,
    padding: padding,
    dwellEnabled: dwellEnabled,
    dwellMs: dwellMs,
    largeButtons: largeButtons,
  );
}

String _locationAudioSummary(AppStrings strings, LocationModel location) {
  return strings.locationDetailsAudio(
    location.nom,
    location.fullAddress,
    location.categorie.displayName,
    location.description,
  );
}

/// Écran de détails d'un lieu accessible.
class LocationDetailScreen extends ConsumerWidget {
  const LocationDetailScreen({required this.locationId, super.key});

  final String locationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final locationAsync = ref.watch(locationByIdProvider(locationId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: locationAsync.when(
        data: (location) {
          IconData categoryIcon;
          Color categoryColor;
          switch (location.categorie) {
            case LocationCategory.pharmacy:
              categoryIcon = Icons.local_pharmacy;
              categoryColor = Colors.red;
              break;
            case LocationCategory.restaurant:
              categoryIcon = Icons.restaurant;
              categoryColor = Colors.orange;
              break;
            case LocationCategory.hospital:
              categoryIcon = Icons.local_hospital;
              categoryColor = Colors.red.shade700;
              break;
            case LocationCategory.school:
              categoryIcon = Icons.school;
              categoryColor = Colors.blue;
              break;
            case LocationCategory.shop:
              categoryIcon = Icons.shopping_bag;
              categoryColor = Colors.purple;
              break;
            case LocationCategory.publicTransport:
              categoryIcon = Icons.directions_bus;
              categoryColor = Colors.green;
              break;
            case LocationCategory.park:
              categoryIcon = Icons.park;
              categoryColor = Colors.green.shade700;
              break;
            case LocationCategory.other:
              categoryIcon = Icons.place;
              categoryColor = primary;
              break;
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                actions: [
                  ReadAloudButton(
                    textBuilder: () => _locationAudioSummary(strings, location),
                    readLabel: strings.readScreen,
                    stopLabel: strings.stopReading,
                  ),
                  IconButton(
                    tooltip: strings.sharePlace,
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      final text =
                          '${location.nom}\n${location.fullAddress}\nhttps://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.linkCopied)),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: location.images != null &&
                          location.images!.isNotEmpty
                      ? LayoutBuilder(
                          builder: (context, constraints) {
                            final w = (constraints.maxWidth *
                                    MediaQuery.devicePixelRatioOf(context))
                                .round()
                                .clamp(1, 2048);
                            return Image.network(
                              LocationRepository.imageUrl(location.images!.first),
                              fit: BoxFit.cover,
                              cacheWidth: w,
                              errorBuilder: (_, _, _) => Container(
                                color: categoryColor.withValues(alpha: 0.1),
                                child: Icon(
                                  categoryIcon,
                                  size: 64,
                                  color: categoryColor,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: categoryColor.withValues(alpha: 0.1),
                          child: Icon(
                            categoryIcon,
                            size: 64,
                            color: categoryColor,
                          ),
                        ),
                ),
                leading: BackButton(
                  onPressed: () => _safeBackToCommunity(context),
                ),
              ),
              SliverToBoxAdapter(
                child: _LocationMapPreview(
                  location: location,
                  strings: strings,
                  onOpenMap: () => _openDirections(context, location, strings),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(categoryIcon, size: 16, color: categoryColor),
                                const SizedBox(width: 6),
                                Text(
                                  location.categorie.displayName,
                                  style: TextStyle(
                                    color: categoryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (location.isApproved)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    strings.approved,
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              location.nom,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (location.scoreAccessibilite != null) ...[
                            const SizedBox(width: 8),
                            _AccessibilityScoreBadge(
                              score: location.scoreAccessibilite!,
                              strings: strings,
                            ),
                          ],
                          if (location.riskLevel != null || location.obstaclePresent) ...[
                            const SizedBox(width: 8),
                            _RiskLevelBadge(location: location, strings: strings),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  location.fullAddress,
                                  style: theme.textTheme.bodyLarge,
                                ),
                                if (location.telephone != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        size: 16,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        location.telephone!,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<_MotorSettings>(
                        future: _loadMotorSettings(),
                        builder: (context, snap) {
                          final cfg =
                              snap.data ??
                              const _MotorSettings(
                                enabled: true,
                                padding: 10,
                                dwellEnabled: false,
                                dwellMs: 900,
                                largeButtons: true,
                              );
                          return Row(
                            children: [
                              Expanded(
                                child: MotorAccessibleAction(
                                  enabled: cfg.enabled,
                                  magneticPadding: cfg.padding,
                                  dwellEnabled: cfg.dwellEnabled,
                                  dwellMs: cfg.dwellMs,
                                  onActivate: () => _openDirections(
                                    context,
                                    location,
                                    strings,
                                  ),
                                  child: ElevatedButton.icon(
                                    style: cfg.largeButtons
                                        ? ElevatedButton.styleFrom(
                                            minimumSize: const Size.fromHeight(52),
                                          )
                                        : null,
                                    onPressed: cfg.dwellEnabled
                                        ? null
                                        : () => _openDirections(
                                            context,
                                            location,
                                            strings,
                                          ),
                                    icon: const Icon(Icons.directions),
                                    label: Text(strings.getDirections),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: MotorAccessibleAction(
                                  enabled: cfg.enabled,
                                  magneticPadding: cfg.padding,
                                  dwellEnabled: cfg.dwellEnabled,
                                  dwellMs: cfg.dwellMs,
                                  onActivate: () => _openReport(
                                    context,
                                    user,
                                    location,
                                    strings,
                                  ),
                                  child: OutlinedButton.icon(
                                    style: cfg.largeButtons
                                        ? OutlinedButton.styleFrom(
                                            minimumSize: const Size.fromHeight(52),
                                          )
                                        : null,
                                    onPressed: cfg.dwellEnabled
                                        ? null
                                        : () => _openReport(
                                            context,
                                            user,
                                            location,
                                            strings,
                                          ),
                                    icon: Icon(
                                      _useAiAssistForReport(user?.typeHandicap)
                                          ? Icons.auto_awesome
                                          : Icons.report_problem,
                                    ),
                                    label: Text(strings.reportIssue),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      if (location.description != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          strings.description,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          location.aiSummary ?? location.description!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ] else ...[
                        const SizedBox(height: 24),
                        Text(
                          strings.description,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          strings.noDescriptionForPlace,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (location.horaires != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          strings.openingHours,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              location.horaires!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                      if (location.amenities != null &&
                          location.amenities!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          strings.amenities,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: location.amenities!.map((amenity) {
                            return Chip(
                              label: Text(amenity),
                              avatar: const Icon(Icons.check, size: 18),
                            );
                          }).toList(),
                        ),
                      ],
                      if (location.submittedByName != null) ...[
                        const SizedBox(height: 24),
                        Divider(color: theme.colorScheme.outline),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${strings.submittedBy} ${location.submittedByName}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  strings.errorLoadingPlace,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: Text(strings.goBack),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccessibilityScoreBadge extends StatelessWidget {
  const _AccessibilityScoreBadge({
    required this.score,
    required this.strings,
  });

  final int score;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bg;
    Color fg;
    if (score >= 70) {
      bg = Colors.green.withValues(alpha: 0.15);
      fg = Colors.green.shade800;
    } else if (score >= 40) {
      bg = Colors.orange.withValues(alpha: 0.15);
      fg = Colors.orange.shade900;
    } else {
      bg = theme.colorScheme.errorContainer;
      fg = theme.colorScheme.onErrorContainer;
    }
    return Semantics(
      label: '${strings.accessibilityScoreShort}: $score / 100',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.accessible, size: 16, color: fg),
            const SizedBox(width: 4),
            Text(
              '$score',
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskLevelBadge extends StatelessWidget {
  const _RiskLevelBadge({
    required this.location,
    required this.strings,
  });

  final LocationModel location;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final risk = (location.riskLevel ?? 'safe').toLowerCase();
    late final Color bg;
    late final Color fg;
    late final String label;
    if (risk == 'danger' || location.obstaclePresent) {
      bg = Colors.red.withValues(alpha: 0.16);
      fg = Colors.red.shade900;
      label = strings.riskDanger;
    } else if (risk == 'caution' || (location.verificationStatus ?? '') == 'pending') {
      bg = Colors.orange.withValues(alpha: 0.18);
      fg = Colors.orange.shade900;
      label = strings.riskCaution;
    } else {
      bg = Colors.green.withValues(alpha: 0.16);
      fg = Colors.green.shade800;
      label = strings.riskSafe;
    }
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.report_gmailerrorred, size: 16, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationMapPreview extends StatelessWidget {
  const _LocationMapPreview({
    required this.location,
    required this.strings,
    required this.onOpenMap,
  });

  final LocationModel location;
  final AppStrings strings;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lat = location.latitude;
    final lng = location.longitude;
    final hasCoords = !(lat == 0 && lng == 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: hasCoords ? onOpenMap : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.getDirections,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasCoords
                            ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
                            : strings.coordinatesUnavailable,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.open_in_new,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

