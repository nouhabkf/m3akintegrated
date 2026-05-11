import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/location/current_position.dart';
import '../../../core/widgets/read_aloud_button.dart';
import '../../../data/models/location_model.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/community_providers.dart';

/// Liste des lieux accessibles triés par distance (GPS + API [nearby], repli client).
class CommunityNearbyPlacesScreen extends ConsumerStatefulWidget {
  const CommunityNearbyPlacesScreen({
    super.key,
    this.embedded = true,
  });

  /// Dans l’onglet [CommunityMainScreen] : pas de [Scaffold] propre.
  final bool embedded;

  @override
  ConsumerState<CommunityNearbyPlacesScreen> createState() =>
      _CommunityNearbyPlacesScreenState();
}

class _CommunityNearbyPlacesScreenState
    extends ConsumerState<CommunityNearbyPlacesScreen> {
  Position? _pos;
  bool _loadingPos = true;

  /// Rayon max pour l’API + filtre client (4 km).
  static const double _defaultMaxDistanceM = 4000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPosition());
  }

  Future<void> _refreshPosition() async {
    setState(() => _loadingPos = true);
    if (kIsWeb) {
      if (mounted) setState(() => _pos = null);
    } else {
      final p = await getCurrentPositionOrNull();
      if (mounted) setState(() => _pos = p);
    }
    if (mounted) setState(() => _loadingPos = false);
  }

  List<LocationModel> _filterByMaxDistance(
    List<LocationModel> list,
    Position p,
    double maxMeters,
  ) {
    return list.where((loc) {
      if (!loc.latitude.isFinite || !loc.longitude.isFinite) return false;
      final d = Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
        loc.latitude,
        loc.longitude,
      );
      return d <= maxMeters;
    }).toList();
  }

  /// Source API si non vide, sinon liste complète ; toujours bornée au [maxMeters].
  List<LocationModel> _nearbyDisplayList(
    List<LocationModel> apiNearby,
    List<LocationModel> allLocations,
    Position p,
  ) {
    final source = apiNearby.isNotEmpty ? apiNearby : allLocations;
    final filtered = _filterByMaxDistance(source, p, _defaultMaxDistanceM);
    return _sortByRiskThenDistance(filtered, p);
  }

  int _riskRank(LocationModel loc) {
    final risk = (loc.riskLevel ?? 'safe').toLowerCase();
    if (risk == 'danger' || loc.obstaclePresent) return 0;
    if (risk == 'caution' || (loc.verificationStatus ?? '') == 'pending') return 1;
    return 2;
  }

  List<LocationModel> _sortByRiskThenDistance(
    List<LocationModel> list,
    Position p,
  ) {
    final copy = List<LocationModel>.from(list);
    copy.sort((a, b) {
      final rr = _riskRank(a).compareTo(_riskRank(b));
      if (rr != 0) return rr;
      final da = Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
        a.latitude,
        a.longitude,
      );
      final db = Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
        b.latitude,
        b.longitude,
      );
      return da.compareTo(db);
    });
    return copy;
  }

  String _buildAudioSummary(
    AppStrings strings,
    List<LocationModel> locations,
    Position p,
  ) {
    final buf = StringBuffer(strings.nearbyPlacesAudioIntro(locations.length));
    final take = locations.length > 5 ? 5 : locations.length;
    for (var i = 0; i < take; i++) {
      final loc = locations[i];
      final meters = Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
        loc.latitude,
        loc.longitude,
      );
      final distance = meters >= 1000
          ? strings.nearbyPlacesKmOneDecimal(meters / 1000)
          : strings.nearbyPlacesMeters(meters.round());
      buf.write(' ');
      buf.write(
        strings.nearbyPlaceAudioItem(
          loc.nom,
          loc.categorie.displayName,
          distance,
        ),
      );
    }
    return buf.toString();
  }

  (Color, String) _riskStyle(LocationModel loc, AppStrings strings, ThemeData theme) {
    final risk = (loc.riskLevel ?? 'safe').toLowerCase();
    if (risk == 'danger' || loc.obstaclePresent) {
      return (Colors.red.shade700, strings.riskDanger);
    }
    if (risk == 'caution' || (loc.verificationStatus ?? '') == 'pending') {
      return (Colors.orange.shade800, strings.riskCaution);
    }
    return (Colors.green.shade700, strings.riskSafe);
  }

  Widget _buildBody(AppStrings strings, ThemeData theme) {
    if (kIsWeb) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            strings.nearbyPlacesWebUnavailable,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    if (_loadingPos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pos == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off, size: 56, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                strings.nearbyPlacesNeedLocation,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _refreshPosition,
                icon: const Icon(Icons.refresh),
                label: Text(strings.retry),
              ),
            ],
          ),
        ),
      );
    }

    final p = _pos!;
    final params = (
      lat: p.latitude,
      lng: p.longitude,
      maxDistance: _defaultMaxDistanceM,
    );

    final nearbyAsync = ref.watch(nearbyLocationsProvider(params));
    final allAsync = ref.watch(locationsProvider);

    return nearbyAsync.when(
      data: (apiList) {
        if (apiList.isNotEmpty) {
          final displayed = _nearbyDisplayList(apiList, const [], p);
          if (displayed.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  strings.nearbyPlacesNoneInRadiusKm(
                    (_defaultMaxDistanceM / 1000).round(),
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            );
          }
          return _buildList(strings, theme, displayed, p);
        }
        return allAsync.when(
          data: (all) {
            if (all.isEmpty) {
              return Center(child: Text(strings.noPlacesFound));
            }
            final displayed = _nearbyDisplayList(apiList, all, p);
            if (displayed.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    strings.nearbyPlacesNoneInRadiusKm(
                      (_defaultMaxDistanceM / 1000).round(),
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              );
            }
            return _buildList(strings, theme, displayed, p);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(strings.errorLoadingPlaces)),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) {
        return allAsync.when(
          data: (all) {
            if (all.isEmpty) {
              return Center(child: Text(strings.noPlacesFound));
            }
            final displayed = _nearbyDisplayList([], all, p);
            if (displayed.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    strings.nearbyPlacesNoneInRadiusKm(
                      (_defaultMaxDistanceM / 1000).round(),
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              );
            }
            return _buildList(strings, theme, displayed, p);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('${strings.errorLoadingPlaces}: $e')),
        );
      },
    );
  }

  Widget _buildList(
    AppStrings strings,
    ThemeData theme,
    List<LocationModel> locations,
    Position p,
  ) {
    final audioText = _buildAudioSummary(strings, locations, p);
    return RefreshIndicator(
      onRefresh: () async {
        await _refreshPosition();
        final p2 = _pos;
        if (p2 == null) return;
        ref.invalidate(
          nearbyLocationsProvider((
            lat: p2.latitude,
            lng: p2.longitude,
            maxDistance: _defaultMaxDistanceM,
          )),
        );
        ref.invalidate(locationsProvider);
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: locations.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.nearbyPlacesHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ReadAloudButton(
                    textBuilder: () => audioText,
                    readLabel: strings.readScreen,
                    stopLabel: strings.stopReading,
                  ),
                ],
              ),
            );
          }
          final loc = locations[i - 1];
          final meters = Geolocator.distanceBetween(
            p.latitude,
            p.longitude,
            loc.latitude,
            loc.longitude,
          );
          final distLabel = meters >= 1000
              ? strings.nearbyPlacesKmOneDecimal(meters / 1000)
              : strings.nearbyPlacesMeters(meters.round());
          final semanticsLabel = strings.nearbyPlaceAudioItem(
            loc.nom,
            loc.categorie.displayName,
            distLabel,
          );
          final (riskColor, riskLabel) = _riskStyle(loc, strings, theme);

          return Semantics(
            button: true,
            label: '$semanticsLabel $riskLabel.',
            child: Material(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.place, color: riskColor),
                ),
                title: Text(
                  loc.nom,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '$riskLabel · ${loc.categorie.displayName} · $distLabel\n${loc.aiSummary ?? loc.fullAddress}',
                  style: theme.textTheme.bodySmall,
                ),
                isThreeLine: true,
                trailing: Icon(Icons.chevron_right, color: theme.colorScheme.outline),
                onTap: () => context.push('/location-detail/${loc.id}'),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);

    final body = ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: _buildBody(strings, theme),
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final nav = Navigator.of(context);
            if (nav.canPop()) {
              nav.pop();
            } else {
              context.go('/home?tab=3');
            }
          },
        ),
        title: Text(strings.nearbyPlacesTitle),
        actions: [
          if (_pos != null)
            ReadAloudButton(
              textBuilder: () {
                final p = _pos!;
                final params = (
                  lat: p.latitude,
                  lng: p.longitude,
                  maxDistance: _defaultMaxDistanceM,
                );
                final apiList =
                    ref.read(nearbyLocationsProvider(params)).valueOrNull ?? [];
                final allAsync = ref.read(locationsProvider);
                if (apiList.isEmpty && allAsync.isLoading) {
                  return strings.splashLoading;
                }
                if (apiList.isEmpty && allAsync.hasError) {
                  return strings.errorLoadingPlaces;
                }
                final allList = allAsync.valueOrNull ?? [];
                if (allList.isEmpty && apiList.isEmpty) {
                  return strings.noPlacesFound;
                }
                final displayed = _nearbyDisplayList(apiList, allList, p);
                if (displayed.isEmpty) {
                  return strings.nearbyPlacesNoneInRadiusKm(
                    (_defaultMaxDistanceM / 1000).round(),
                  );
                }
                return _buildAudioSummary(strings, displayed, p);
              },
              readLabel: strings.readScreen,
              stopLabel: strings.stopReading,
            ),
        ],
      ),
      body: body,
    );
  }
}

