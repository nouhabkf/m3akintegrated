part of 'accessibility_module.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  Widgets carte, liste, réservations, contributions — identiques à l'original
// ═══════════════════════════════════════════════════════════════════════════════

class _OpenStreetMapPlacesLayer extends StatefulWidget {
  final List<AccessiblePlace> places;
  final AccessiblePlace? selectedPlace;
  final ValueChanged<AccessiblePlace> onSelectPlace;
  final Color Function(int score) scoreColor;
  final VoidCallback onMapTap;
  final LatLng? userLocation;
  final bool locationSetupComplete;
  final int myLocationRecenterSignal;
  final List<LatLng>? routePolyline;
  final int routeFitToken;
  const _OpenStreetMapPlacesLayer({required this.places,required this.selectedPlace,required this.onSelectPlace,required this.scoreColor,required this.onMapTap,required this.userLocation,required this.locationSetupComplete,required this.myLocationRecenterSignal,required this.routePolyline,required this.routeFitToken});
  static const LatLng tunisCenter = LatLng(36.8065, 10.1815);
  static const double defaultZoom = 13, selectedZoom = 15, userZoom = 15;
  @override
  State<_OpenStreetMapPlacesLayer> createState() => _OpenStreetMapPlacesLayerState();
}

class _OpenStreetMapPlacesLayerState extends State<_OpenStreetMapPlacesLayer> {
  final MapController _mapController = MapController();
  String? _lastCenteredPlaceId;
  bool _openingCameraApplied = false;

  @override
  void initState() { super.initState(); if(widget.locationSetupComplete) WidgetsBinding.instance.addPostFrameCallback((_)=>_applyOpeningCamera()); }

  @override
  void didUpdateWidget(covariant _OpenStreetMapPlacesLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.locationSetupComplete&&widget.locationSetupComplete) WidgetsBinding.instance.addPostFrameCallback((_)=>_applyOpeningCamera());
    if (widget.myLocationRecenterSignal!=oldWidget.myLocationRecenterSignal&&widget.userLocation!=null)
      WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)_mapController.move(widget.userLocation!,_OpenStreetMapPlacesLayer.userZoom);});
    if (widget.selectedPlace?.id!=oldWidget.selectedPlace?.id)
      WidgetsBinding.instance.addPostFrameCallback((_){if(_openingCameraApplied)_syncCameraToSelection();});
    if (widget.routeFitToken!=oldWidget.routeFitToken&&widget.routeFitToken>0&&widget.routePolyline!=null&&widget.routePolyline!.length>=2)
      WidgetsBinding.instance.addPostFrameCallback((_)=>_fitRouteOnMap());
  }

  void _fitRouteOnMap() {
    if (!mounted) return;
    final pts=widget.routePolyline; if(pts==null||pts.length<2) return;
    try { _mapController.fitCamera(CameraFit.bounds(bounds:LatLngBounds.fromPoints(pts),padding:const EdgeInsets.fromLTRB(36,100,36,200),maxZoom:17)); } catch(_) {}
  }

  void _applyOpeningCamera() {
    if (!mounted||_openingCameraApplied) return;
    _openingCameraApplied=true;
    if (widget.userLocation!=null) _mapController.move(widget.userLocation!,_OpenStreetMapPlacesLayer.userZoom);
    else _syncCameraToSelection();
  }

  void _syncCameraToSelection() {
    if (!mounted) return;
    final sel=widget.selectedPlace;
    if (sel!=null&&sel.id!=_lastCenteredPlaceId) { _lastCenteredPlaceId=sel.id; _mapController.move(LatLng(sel.latitude,sel.longitude),_OpenStreetMapPlacesLayer.selectedZoom); }
    else if (sel==null&&_lastCenteredPlaceId!=null) {
      _lastCenteredPlaceId=null;
    }
  }

  @override
  void dispose() { _mapController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController:_mapController,
      options:MapOptions(initialCenter:_OpenStreetMapPlacesLayer.tunisCenter,initialZoom:_OpenStreetMapPlacesLayer.defaultZoom,minZoom:3,maxZoom:19,
        onTap:(TapPosition tapPosition,LatLng point){widget.onMapTap();}),
      children:[
        TileLayer(urlTemplate:'https://tile.openstreetmap.org/{z}/{x}/{y}.png',userAgentPackageName:'com.m3ak.accessibility'),
        if (widget.routePolyline!=null&&widget.routePolyline!.length>=2)
          PolylineLayer(polylines:[Polyline(points:widget.routePolyline!,strokeWidth:5,color:const Color(0xFF0D77A6),borderStrokeWidth:2.5,borderColor:Colors.white)]),
        MarkerLayer(markers:[
          for (final place in widget.places)
            Marker(point:LatLng(place.latitude,place.longitude),
              width:widget.selectedPlace?.id==place.id?52:44,height:widget.selectedPlace?.id==place.id?52:44,
              child:GestureDetector(onTap:()=>widget.onSelectPlace(place),
                child:AnimatedContainer(duration:const Duration(milliseconds:200),
                  decoration:BoxDecoration(shape:BoxShape.circle,
                    color:widget.selectedPlace?.id==place.id?const Color(0xFF0A678E):widget.scoreColor(place.accessibilityScore),
                    boxShadow:const[BoxShadow(color:Color(0x33000000),blurRadius:10,offset:Offset(0,3))]),
                  child:Icon(_mapIconForCategory(place.category),color:Colors.white,size:widget.selectedPlace?.id==place.id?26:20)))),
          if (widget.userLocation!=null)
            Marker(point:widget.userLocation!,width:32,height:32,child:const _UserLocationMapMarker()),
        ]),
      ],
    );
  }
}

class _UserLocationMapMarker extends StatelessWidget {
  const _UserLocationMapMarker();
  @override
  Widget build(BuildContext context) => Container(
    decoration:BoxDecoration(shape:BoxShape.circle,color:const Color(0xFF1E88E5),
      border:Border.all(color:Colors.white,width:3),
      boxShadow:const[BoxShadow(color:Color(0x44000000),blurRadius:8,offset:Offset(0,2))]),
    child:const Icon(Icons.navigation_rounded,color:Colors.white,size:16));
}

IconData _mapIconForCategory(PlaceCategory category) {
  switch(category){
    case PlaceCategory.hopital:       return Icons.local_hospital_rounded;
    case PlaceCategory.administration:return Icons.account_balance_rounded;
    case PlaceCategory.cafe:          return Icons.local_cafe_rounded;
    case PlaceCategory.commerce:      return Icons.store_rounded;
    case PlaceCategory.transport:     return Icons.directions_transit_rounded;
    case PlaceCategory.autre:         return Icons.accessible_rounded;
  }
}

class AccessibilityMapTabScreen extends StatelessWidget {
  final TextEditingController searchController;
  final DisabilityType selectedDisability;
  final ValueChanged<DisabilityType> onSelectDisability;
  final Set<PlaceCategory> selectedCategories;
  final ValueChanged<PlaceCategory> onToggleCategory;
  final bool isExpanded;
  final VoidCallback onExpandMap, onCollapseMap;
  final List<AccessiblePlace> places;
  final AccessiblePlace? selectedPlace;
  final ValueChanged<AccessiblePlace> onSelectPlace;
  final VoidCallback onClearSelection;
  final Color Function(int score) scoreColor;
  final int Function(AccessiblePlace place) reportsForPlace, photosForPlace;
  final PlaceGeoInsights? geoInsights;
  final bool geoInsightsLoading, geoEnabled;
  final VoidCallback? onReserve;
  final VoidCallback onOpenReservationsHistory;
  /// Ferme uniquement la fiche lieu (sans désélectionner ni bouger la caméra par effet de bord).
  final VoidCallback onDismissPlaceCard;
  /// Rouvre la fiche lieu après l’avoir masquée.
  final VoidCallback onOpenPlaceCard;
  final VoidCallback onOpenRoute;
  final LatLng? userLocation;
  final bool locationSetupComplete;
  final int myLocationRecenterSignal;
  final VoidCallback onMyLocationPressed;
  final List<LatLng>? routePolyline;
  final int routeFitToken;
  final AIAccessibilityResult? aiResult;
  final bool aiLoading;
  final bool showPlaceCard;

  const AccessibilityMapTabScreen({required this.searchController,required this.selectedDisability,required this.onSelectDisability,required this.selectedCategories,required this.onToggleCategory,required this.isExpanded,required this.onExpandMap,required this.onCollapseMap,required this.places,required this.selectedPlace,required this.onSelectPlace,required this.onClearSelection,required this.onDismissPlaceCard,required this.onOpenPlaceCard,required this.scoreColor,required this.reportsForPlace,required this.photosForPlace,required this.geoInsights,required this.geoInsightsLoading,required this.geoEnabled,required this.onReserve,required this.onOpenReservationsHistory,required this.onOpenRoute,required this.showPlaceCard,required this.userLocation,required this.locationSetupComplete,required this.myLocationRecenterSignal,required this.onMyLocationPressed,required this.routePolyline,required this.routeFitToken,required this.aiResult,required this.aiLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:BoxDecoration(borderRadius:BorderRadius.circular(16),color:const Color(0xFFE8EEF3)),
      child:Stack(children:[
        Positioned.fill(child:ClipRRect(borderRadius:BorderRadius.circular(isExpanded?0:16),
          child:_OpenStreetMapPlacesLayer(places:places,selectedPlace:selectedPlace,onSelectPlace:onSelectPlace,scoreColor:scoreColor,userLocation:userLocation,locationSetupComplete:locationSetupComplete,myLocationRecenterSignal:myLocationRecenterSignal,routePolyline:routePolyline,routeFitToken:routeFitToken,
            onMapTap:(){ if(isExpanded){onClearSelection();}else{onExpandMap();} }))),
        Positioned(left:8,right:8,bottom:6,child:IgnorePointer(child:Text('© OpenStreetMap contributors',textAlign:TextAlign.center,style:TextStyle(fontSize:10,color:Colors.black.withValues(alpha:0.45),shadows:const[Shadow(color:Colors.white,blurRadius:4),Shadow(color:Colors.white,blurRadius:4)])))),
        if (!isExpanded)
          Positioned(
            top: 8,
            left: 14,
            right: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SearchFiltersBar(
                  controller: searchController,
                  selectedDisability: selectedDisability,
                  onSelectDisability: onSelectDisability,
                  filteredCount: places.length,
                  searchResults:
                      searchController.text.trim().isEmpty ? const [] : places,
                  onSelectPlace: onSelectPlace,
                ),
                const SizedBox(height: 8),
                _CategoryFilters(
                  selectedCategories: selectedCategories,
                  onToggle: onToggleCategory,
                  allPlaces: places,
                ),
              ],
            ),
          )
        else
          Positioned(top:10,right:10,child:IconButton.filledTonal(onPressed:onCollapseMap,icon:const Icon(Icons.fullscreen_exit_rounded),tooltip:'Reduire la carte')),
        if (!isExpanded && showPlaceCard) _PlaceCard(place:selectedPlace,reports:selectedPlace==null?0:reportsForPlace(selectedPlace!),photos:selectedPlace==null?0:photosForPlace(selectedPlace!),geoInsights:geoInsights,geoInsightsLoading:geoInsightsLoading,geoEnabled:geoEnabled,onReserve:onReserve,onOpenReservationsHistory:onOpenReservationsHistory,onRoute:onOpenRoute,onBack:onDismissPlaceCard,aiResult:aiResult,aiLoading:aiLoading),
        // Fiche masquée : rouvrir (tap gauche) ou quitter la sélection (✕).
        if (!isExpanded && !showPlaceCard && selectedPlace!=null)
          Positioned(top:10,left:10,right:76,child:Material(elevation:4,borderRadius:BorderRadius.circular(24),color:Colors.white,
            child:Row(children:[
              Expanded(child:InkWell(borderRadius:BorderRadius.circular(24),onTap:onOpenPlaceCard,
                child:Padding(padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),
                  child:Row(children:[
                    const Icon(Icons.place_outlined,color:Color(0xFF0D77A6),size:18),
                    const SizedBox(width:8),
                    Expanded(child:Text(selectedPlace!.name,style:const TextStyle(color:Color(0xFF0D77A6),fontWeight:FontWeight.w700,fontSize:13),maxLines:1,overflow:TextOverflow.ellipsis)),
                  ])))),
              IconButton(
                tooltip:'Quitter ce lieu sur la carte',
                visualDensity:VisualDensity.compact,
                constraints:const BoxConstraints(minWidth:40,minHeight:40),
                onPressed:onClearSelection,
                icon:const Icon(Icons.close_rounded,color:Color(0xFF6B7C8E),size:20),
              ),
            ]))),
        // Au-dessus de la fiche pour rester cliquable ; remonte quand la fiche est ouverte
        Positioned(
          right:14,
          bottom:!isExpanded&&(selectedPlace!=null&&showPlaceCard)?310:104,
          child:Tooltip(
            message:'Ma position',
            child:Material(
              elevation:6,
              shape:const CircleBorder(),
              color:Colors.white,
              shadowColor:Colors.black45,
              child:InkWell(
                customBorder:const CircleBorder(),
                onTap:onMyLocationPressed,
                child:const SizedBox(
                  width:56,
                  height:56,
                  child:Center(
                    child:Icon(Icons.my_location_rounded,color:Color(0xFF1A237E),size:28),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (places.isEmpty) Positioned(top:200,left:22,right:22,child:Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white.withValues(alpha:0.94),borderRadius:BorderRadius.circular(14)),child:const Text('Aucun lieu ne correspond aux filtres selectionnes.',textAlign:TextAlign.center,style:TextStyle(color:Color(0xFF516474),fontWeight:FontWeight.w600)))),
      ]),
    );
  }
}

class AccessibilityItineraryTabScreen extends StatelessWidget {
  final AccessiblePlace? selectedPlace;
  final bool offlineEnabled,mapDownloaded,routesDownloaded,placesDownloaded,avoidObstacles,includeElevators;
  final RoutePlan? currentRoute;
  final bool routeLoading;
  final String? routeError;
  final bool openRouteConfigured;
  final TransportMode selectedTransportMode;
  final ValueChanged<TransportMode> onTransportModeChange;
  final ValueChanged<bool> onOfflineToggle,onAvoidObstaclesToggle,onIncludeElevatorToggle;
  final VoidCallback onDownloadOffline,onBuildRoute;
  final VoidCallback? onViewOnMap;
  final VoidCallback? onStartNavigation;

  const AccessibilityItineraryTabScreen({
    required this.selectedPlace, required this.offlineEnabled,
    required this.mapDownloaded, required this.routesDownloaded, required this.placesDownloaded,
    required this.avoidObstacles, required this.includeElevators,
    required this.currentRoute, required this.routeLoading, required this.routeError,
    required this.openRouteConfigured, required this.selectedTransportMode,
    required this.onTransportModeChange, required this.onOfflineToggle,
    required this.onAvoidObstaclesToggle, required this.onIncludeElevatorToggle,
    required this.onDownloadOffline, required this.onBuildRoute,
    this.onViewOnMap, this.onStartNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:BoxDecoration(borderRadius:BorderRadius.circular(16),color:Colors.white),
      child:SingleChildScrollView(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Navigation adaptée',style:TextStyle(fontSize:22,fontWeight:FontWeight.w700,color:Color(0xFF204157))),
        const SizedBox(height:6),
        Text(selectedPlace==null?'Aucun lieu sélectionné':'Destination : ${selectedPlace!.name}',
          style:const TextStyle(color:Color(0xFF5F7282))),
        const SizedBox(height:16),

        // ── Mode de transport ─────────────────────────────────────────────────
        const Text('Mode de transport',style:TextStyle(fontWeight:FontWeight.w700,fontSize:14,color:Color(0xFF2D4A5E))),
        const SizedBox(height:8),
        _TransportSelector(
          selected: selectedTransportMode,
          onSelect: onTransportModeChange,
        ),
        const SizedBox(height:16),
        const Divider(height:1),
        const SizedBox(height:12),

        SwitchListTile.adaptive(title:const Text('Mode hors ligne'),subtitle:const Text('Télécharger zone carte, itinéraires, infos lieux'),value:offlineEnabled,onChanged:onOfflineToggle),
        ListTile(contentPadding:EdgeInsets.zero,title:const Text('Téléchargements'),
          subtitle:Text('Carte : ${mapDownloaded?"OK":"Non"} | Itinéraires : ${routesDownloaded?"OK":"Non"} | Lieux : ${placesDownloaded?"OK":"Non"}'),
          trailing:FilledButton(onPressed:onDownloadOffline,child:const Text('Télécharger'))),
        const Divider(height:24),
        CheckboxListTile(title:const Text('Éviter les obstacles'),value:avoidObstacles,onChanged:(v)=>onAvoidObstaclesToggle(v??true)),
        CheckboxListTile(title:const Text('Prioriser ascenseurs'),value:includeElevators,onChanged:(v)=>onIncludeElevatorToggle(v??true)),
        const SizedBox(height:10),
        FilledButton.icon(
          onPressed:(selectedPlace==null||routeLoading)?null:onBuildRoute,
          style:FilledButton.styleFrom(minimumSize:const Size(double.infinity,48)),
          icon:routeLoading?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(Icons.alt_route_rounded),
          label:Text(routeLoading?'Calcul en cours…':'Calculer l\'itinéraire accessible')),
        if (routeError!=null)...[
          const SizedBox(height:10),
          Container(width:double.infinity,padding:const EdgeInsets.all(10),
            decoration:BoxDecoration(color:const Color(0xFFFFEBEE),borderRadius:BorderRadius.circular(10),border:Border.all(color:const Color(0xFFE57373))),
            child:Text(routeError!,style:const TextStyle(color:Color(0xFFB71C1C),fontSize:13))),
        ],
        const SizedBox(height:14),
        if (currentRoute!=null) _RouteResultSheet(
          route: currentRoute!,
          place: selectedPlace,
          transportMode: selectedTransportMode,
          onViewOnMap: onViewOnMap,
          onStartNavigation: onStartNavigation,
        ),
      ])),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding:const EdgeInsets.symmetric(vertical:2),
    child:Row(children:[
      Icon(icon,size:15,color:const Color(0xFF0D77A6)),
      const SizedBox(width:8),
      Text('$label : ',style:const TextStyle(fontSize:13,color:Color(0xFF5A7A90))),
      Text(value,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w700,color:Color(0xFF1A3A50))),
    ]),
  );

  Widget _infoBadge(String label, Color color) => Padding(
    padding:const EdgeInsets.only(top:4),
    child:Container(
      padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
      decoration:BoxDecoration(color:color.withValues(alpha:0.12),borderRadius:BorderRadius.circular(20)),
      child:Text(label,style:TextStyle(fontSize:11,fontWeight:FontWeight.w600,color:color)),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  _RouteResultSheet — Fiche itinéraire complète style Google Maps
// ═══════════════════════════════════════════════════════════════════════════════
class _RouteResultSheet extends StatelessWidget {
  final RoutePlan route;
  final AccessiblePlace? place;
  final TransportMode transportMode;
  final VoidCallback? onViewOnMap;
  final VoidCallback? onStartNavigation;

  const _RouteResultSheet({
    required this.route,
    required this.place,
    required this.transportMode,
    this.onViewOnMap,
    this.onStartNavigation,
  });

  Color get _scoreColor {
    if (route.aiScore == null) return const Color(0xFF0D77A6);
    final s = route.aiScore! * 100;
    if (s >= 80) return const Color(0xFF2A9F58);
    if (s >= 60) return const Color(0xFFE69D2A);
    return const Color(0xFFD24C4C);
  }

  String get _transportLabel {
    switch (transportMode) {
      case TransportMode.apied:   return 'À pied';
      case TransportMode.voiture: return 'En voiture';
      case TransportMode.moto:    return 'En moto';
    }
  }

  IconData get _transportIcon {
    switch (transportMode) {
      case TransportMode.apied:   return Icons.directions_walk_rounded;
      case TransportMode.voiture: return Icons.directions_car_rounded;
      case TransportMode.moto:    return Icons.two_wheeler_rounded;
    }
  }

  /// Génère des étapes pseudo-réalistes basées sur la distance / durée
  List<_NavStep> _generateSteps() {
    final isAI = route.source == RouteSource.pythonAI;
    if (isAI) {
      return [
        _NavStep(icon: Icons.my_location_rounded, color: const Color(0xFF0D77A6),
          title: 'Départ depuis votre position', subtitle: 'Point de départ détecté'),
        _NavStep(icon: Icons.accessible_forward_rounded, color: const Color(0xFF2A9F58),
          title: 'Suivez le tracé accessible', subtitle: 'Chemin sans obstacles optimisé par IA'),
        if (route.includesElevator)
          _NavStep(icon: Icons.elevator_rounded, color: const Color(0xFF1565C0),
            title: 'Ascenseur disponible', subtitle: 'Priorité aux accès de plain-pied'),
        if (route.avoidObstacles)
          _NavStep(icon: Icons.block_rounded, color: const Color(0xFF7B3FA6),
            title: 'Obstacles contournés', subtitle: 'Zones inaccessibles évitées automatiquement'),
        _NavStep(icon: Icons.flag_rounded, color: const Color(0xFFD24C4C),
          title: 'Arrivée : ${place?.name ?? "Destination"}', subtitle: place?.city ?? ''),
      ];
    } else {
      return [
        _NavStep(icon: Icons.my_location_rounded, color: const Color(0xFF0D77A6),
          title: 'Départ depuis votre position', subtitle: 'Position GPS utilisée'),
        _NavStep(icon: Icons.turn_slight_right_rounded, color: const Color(0xFF607080),
          title: 'Continuez tout droit', subtitle: 'Suivez la rue principale'),
        _NavStep(icon: Icons.turn_left_rounded, color: const Color(0xFF607080),
          title: 'Tournez à gauche', subtitle: 'À l\'intersection suivante'),
        _NavStep(icon: Icons.flag_rounded, color: const Color(0xFFD24C4C),
          title: 'Arrivée : ${place?.name ?? "Destination"}', subtitle: place?.city ?? ''),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final scorePercent = route.aiScore != null
        ? '${(route.aiScore! * 100).toStringAsFixed(0)} %'
        : null;
    final isAI = route.source == RouteSource.pythonAI;
    final steps = _generateSteps();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ══════════════════════════════════════════════════════════════════
      // HEADER CARTE — gradient bleu avec stats
      // ══════════════════════════════════════════════════════════════════
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isAI
              ? const [Color(0xFF0B4F72), Color(0xFF0D77A6), Color(0xFF1A9FD8)]
              : const [Color(0xFF1A3A50), Color(0xFF2A6080)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D77A6).withValues(alpha: 0.35),
              blurRadius: 16, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Ligne du haut : icône + destination + badge IA ──────────
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_transportIcon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ITINÉRAIRE CALCULÉ',
                style: TextStyle(color: Colors.white60, fontSize: 10,
                  fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              const SizedBox(height: 3),
              Text(place?.name ?? 'Destination',
                style: const TextStyle(color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.w800),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              if (place?.city != null && place!.city.isNotEmpty)
                Text(place!.city,
                  style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ])),
            if (isAI)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 13),
                  SizedBox(width: 5),
                  Text('A* · DL', style: TextStyle(color: Colors.white,
                    fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ]),
              ),
          ]),

          const SizedBox(height: 18),

          // ── Stats : distance / durée / score ────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IntrinsicHeight(child: Row(children: [
              _StatBubble(icon: Icons.straighten_rounded, label: 'Distance', value: route.distance),
              const VerticalDivider(color: Colors.white24, width: 1),
              _StatBubble(icon: Icons.schedule_rounded,   label: 'Durée',    value: route.duration),
              if (scorePercent != null) ...[
                const VerticalDivider(color: Colors.white24, width: 1),
                _StatBubble(icon: Icons.accessibility_new_rounded,
                  label: 'Accessibilité', value: scorePercent),
              ],
            ])),
          ),
        ]),
      ),

      const SizedBox(height: 14),

      // ══════════════════════════════════════════════════════════════════
      // BOUTONS PRINCIPAUX — Voir tracé / Démarrer
      // ══════════════════════════════════════════════════════════════════
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: onViewOnMap,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 52),
            side: const BorderSide(color: Color(0xFF0D77A6), width: 1.8),
            foregroundColor: const Color(0xFF0D77A6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.map_rounded, size: 19),
          label: const Text('Voir le tracé',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        )),
        const SizedBox(width: 10),
        Expanded(child: FilledButton.icon(
          onPressed: onStartNavigation,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52),
            backgroundColor: const Color(0xFF17A34A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.navigation_rounded, size: 19),
          label: const Text('Démarrer',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        )),
      ]),

      const SizedBox(height: 16),

      // ══════════════════════════════════════════════════════════════════
      // FICHE DÉTAILLÉE — Étapes de navigation
      // ══════════════════════════════════════════════════════════════════
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E8EF)),
          boxShadow: const [
            BoxShadow(color: Color(0x0C000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Titre section ──────────────────────────────────────────
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.route_rounded, size: 16, color: Color(0xFF0D77A6)),
            ),
            const SizedBox(width: 10),
            const Text('Détails de l\'itinéraire',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                color: Color(0xFF1F2D3A))),
          ]),

          const SizedBox(height: 14),

          // ── Étapes ────────────────────────────────────────────────
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            final isLast = i == steps.length - 1;
            return _RouteStepTile(step: step, isLast: isLast);
          }),

          const SizedBox(height: 12),

          // ── Divider ───────────────────────────────────────────────
          const Divider(height: 1, color: Color(0xFFECF1F6)),
          const SizedBox(height: 12),

          // ── Source & badges ────────────────────────────────────────
          Row(children: [
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isAI ? const Color(0xFFF3EEFF) : const Color(0xFFF0F8FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isAI ? const Color(0xFFB39DDB) : const Color(0xFFB0D4EC),
                ),
              ),
              child: Row(children: [
                Icon(isAI ? Icons.smart_toy_rounded : Icons.map_rounded,
                  size: 14,
                  color: isAI ? const Color(0xFF7B3FA6) : const Color(0xFF1565C0)),
                const SizedBox(width: 7),
                Expanded(child: Text(
                  isAI
                    ? 'Tracé IA Python · A* + Deep Learning'
                    : 'Tracé OSRM · OpenStreetMap',
                  style: TextStyle(fontSize: 11,
                    color: isAI ? const Color(0xFF5E2BA5) : const Color(0xFF1A5276),
                    fontWeight: FontWeight.w600),
                )),
              ]),
            )),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 7, runSpacing: 6, children: [
            _Badge(icon: _transportIcon, label: _transportLabel, color: const Color(0xFF0D77A6)),
            if (route.avoidObstacles)
              const _Badge(icon: Icons.block_rounded, label: 'Obstacles évités', color: Color(0xFF2A9F58)),
            if (route.includesElevator)
              const _Badge(icon: Icons.elevator_rounded, label: 'Ascenseurs', color: Color(0xFF1565C0)),
            if (isAI)
              const _Badge(icon: Icons.psychology_rounded, label: 'Chemin accessible IA', color: Color(0xFF7B3FA6)),
          ]),
        ]),
      ),

      const SizedBox(height: 8),
    ]);
  }
}

// ── Modèle d'étape de navigation ─────────────────────────────────────────────
class _NavStep {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _NavStep({
    required this.icon, required this.color,
    required this.title, required this.subtitle,
  });
}

// ── Tuile d'une étape de navigation ──────────────────────────────────────────
class _RouteStepTile extends StatelessWidget {
  final _NavStep step;
  final bool isLast;
  const _RouteStepTile({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Ligne verticale + icône ─────────────────────────────────
        SizedBox(width: 36, child: Column(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: step.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: step.color.withValues(alpha: 0.3)),
            ),
            child: Icon(step.icon, size: 16, color: step.color),
          ),
          if (!isLast)
            Expanded(child: Container(
              width: 2,
              margin: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [step.color.withValues(alpha: 0.4), Colors.transparent],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            )),
        ])),
        const SizedBox(width: 10),
        // ── Texte ───────────────────────────────────────────────────
        Expanded(child: Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 6),
            Text(step.title, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2D3A))),
            if (step.subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(step.subtitle, style: const TextStyle(
                fontSize: 11, color: Color(0xFF7A8F9E))),
            ],
          ]),
        )),
      ]),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _StatBubble({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: Colors.white70, size: 16),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
    ]),
  ));
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  _NavigationOverlay — HUD navigation style Google Maps pro
// ═══════════════════════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════════════════
//  _NavigationOverlay — Navigation GPS temps réel style Google Maps
// ═══════════════════════════════════════════════════════════════════════════════
class _NavigationOverlay extends StatefulWidget {
  final RoutePlan route;
  final AccessiblePlace destination;
  final TransportMode mode;
  final List<LatLng> routePolyline;
  final LatLng? userLocation;
  final double progressFraction;
  final double distanceRemaining;
  final double durationRemaining;
  final int closestPointIndex;
  final VoidCallback onStop;

  const _NavigationOverlay({
    required this.route,
    required this.destination,
    required this.mode,
    required this.routePolyline,
    required this.progressFraction,
    required this.distanceRemaining,
    required this.durationRemaining,
    required this.closestPointIndex,
    required this.onStop,
    this.userLocation,
  });

  @override
  State<_NavigationOverlay> createState() => _NavigationOverlayState();
}

class _NavigationOverlayState extends State<_NavigationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  IconData get _modeIcon {
    switch (widget.mode) {
      case TransportMode.apied:
        return Icons.directions_walk_rounded;
      case TransportMode.voiture:
        return Icons.directions_car_rounded;
      case TransportMode.moto:
        return Icons.two_wheeler_rounded;
    }
  }

  String get _modeLabel {
    switch (widget.mode) {
      case TransportMode.apied:
        return 'À pied';
      case TransportMode.voiture:
        return 'En voiture';
      case TransportMode.moto:
        return 'En moto';
    }
  }

  // ── Instruction suivante basée sur la position dans le tracé ─────────────
  String _getNextInstruction() {
    final pts = widget.routePolyline;
    final idx = widget.closestPointIndex;
    if (pts.isEmpty || idx >= pts.length - 1) return 'Vous arrivez à destination';
    if (widget.distanceRemaining < 50)  return 'Destination dans ${widget.distanceRemaining.toInt()} m';
    if (widget.distanceRemaining < 200) return 'Arrivée imminente';

    // Detect turn based on bearing change
    if (idx + 2 < pts.length) {
      final b1 = _bearing(pts[idx],     pts[idx + 1]);
      final b2 = _bearing(pts[idx + 1], pts[(idx + 2).clamp(0, pts.length - 1)]);
      final diff = ((b2 - b1 + 540) % 360) - 180;
      final lookAheadDist = const Distance().as(LengthUnit.Meter, pts[idx], pts[idx + 1]);
      if (lookAheadDist < 200) {
        if (diff >  25) return 'Tournez à droite';
        if (diff < -25) return 'Tournez à gauche';
      }
    }
    return 'Continuez tout droit';
  }

  IconData _getNextInstructionIcon() {
    final inst = _getNextInstruction();
    if (inst.contains('droite'))    return Icons.turn_right_rounded;
    if (inst.contains('gauche'))    return Icons.turn_left_rounded;
    if (inst.contains('destination') || inst.contains('imminente') || inst.contains('arrivez'))
      return Icons.flag_rounded;
    return Icons.straight_rounded;
  }

  double _bearing(LatLng a, LatLng b) {
    const toRad = 3.14159265358979 / 180;
    final lat1 = a.latitude  * toRad;
    final lat2 = b.latitude  * toRad;
    final dLon = (b.longitude - a.longitude) * toRad;
    // Using approximation-free formula via precomputed values
    // sin/cos via iterative computation (no dart:math needed)
    final sinLat1 = _navSin(lat1), cosLat1 = _navCos(lat1);
    final sinLat2 = _navSin(lat2), cosLat2 = _navCos(lat2);
    final sinDLon = _navSin(dLon), cosDLon = _navCos(dLon);
    final y = sinDLon * cosLat2;
    final x = cosLat1 * sinLat2 - sinLat1 * cosLat2 * cosDLon;
    return _navAtan2(y, x) * 180 / 3.14159265358979;
  }

  // Pure-Dart trig (no dart:math import needed)
  static double _navSin(double x) {
    // Reduce x to [-pi, pi]
    const pi = 3.14159265358979;
    while (x >  pi) x -= 2 * pi;
    while (x < -pi) x += 2 * pi;
    double r = x, t = x;
    for (int i = 1; i < 8; i++) {
      t *= -x * x / ((2 * i) * (2 * i + 1));
      r += t;
    }
    return r;
  }
  static double _navCos(double x) => _navSin(x + 3.14159265358979 / 2);
  static double _navAtan2(double y, double x) {
    const pi = 3.14159265358979;
    if (x == 0) return y > 0 ? pi / 2 : -pi / 2;
    final r = y / x;
    final absR = r < 0 ? -r : r;
    // atan approximation accurate to ~0.005 rad
    final at = absR <= 1
        ? r.sign * (pi / 4 * absR - absR * (absR - 1) * (0.2447 + 0.0663 * absR))
        : r.sign * (pi / 2 - (pi / 4 / absR - (1 / absR) * (1 / absR - 1) * (0.2447 + 0.0663 / absR)));
    return x < 0 ? (y >= 0 ? at + pi : at - pi) : at;
  }

  String _formatDist(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatDur(double seconds) {
    if (seconds <= 0) return '0 min';
    final m = (seconds / 60).ceil();
    if (m >= 60) { final h = m ~/ 60; final rm = m % 60; return '$h h $rm min'; }
    return '$m min';
  }

  @override
  Widget build(BuildContext context) {
    final isAI = widget.route.source == RouteSource.pythonAI;
    final progress = widget.progressFraction;
    final distStr = _formatDist(widget.distanceRemaining > 0
        ? widget.distanceRemaining
        : double.tryParse(widget.route.distance.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0);
    final durStr = _formatDur(widget.durationRemaining > 0
        ? widget.durationRemaining
        : double.tryParse(widget.route.duration.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0);
    final nextInstruction = _getNextInstruction();
    final nextIcon = _getNextInstructionIcon();

    return Stack(children: [
      // ── Bandeau supérieur : instruction suivante ────────────────────────────
      Positioned(top: 0, left: 0, right: 0,
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16, right: 16, bottom: 14,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF08405E), Color(0xFF0D77A6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [BoxShadow(color: Color(0x55000000), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Instruction principale ─────────────────────────────────────
            Row(children: [
              ScaleTransition(scale: _pulse,
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                  ),
                  child: Icon(nextIcon, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nextInstruction,
                  style: const TextStyle(color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w900, height: 1.1)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(width: 8, height: 8,
                    decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text('Navigation en cours · $_modeLabel',
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  if (isAI) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 9),
                        SizedBox(width: 3),
                        Text('IA', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ],
                ]),
              ])),
              // ── ETA + distance ───────────────────────────────────────────
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(durStr,
                  style: const TextStyle(color: Colors.white, fontSize: 26,
                    fontWeight: FontWeight.w900, )),
                Text(distStr,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ]),

            const SizedBox(height: 12),

            // ── Barre de progression réelle ────────────────────────────────
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.trip_origin, color: Colors.white54, size: 10),
                const SizedBox(width: 4),
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(children: [
                    Container(height: 6, color: Colors.white.withValues(alpha: 0.2)),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(height: 6,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF4ADE80), Color(0xFF22C55E)]),
                        )),
                    ),
                  ]),
                )),
                const SizedBox(width: 4),
                Icon(_modeIcon, color: Colors.white54, size: 10),
              ]),
              const SizedBox(height: 3),
              Text('${(progress * 100).toInt()}% du trajet effectué',
                style: const TextStyle(color: Colors.white54, fontSize: 9)),
            ]),
          ]),
        ),
      ),

      // ── Panneau inférieur : destination + score + stop ─────────────────────
      Positioned(bottom: 24, left: 12, right: 12,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Destination card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4))],
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_modeIcon, color: const Color(0xFF0D77A6), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.destination.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A2E3B)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(widget.destination.city,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF607080))),
              ])),
              if (widget.route.aiScore != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF7E4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(children: [
                    const Text('Accès', style: TextStyle(fontSize: 9, color: Color(0xFF2A9F58))),
                    Text('${(widget.route.aiScore! * 100).toInt()}%',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF2A9F58))),
                  ]),
                ),
                const SizedBox(width: 8),
              ],
            ]),
          ),

          const SizedBox(height: 10),

          // Stop button
          SizedBox(width: double.infinity,
            child: Material(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(14),
              elevation: 6,
              shadowColor: const Color(0x60DC2626),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: widget.onStop,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.stop_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text('Arrêter la navigation',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _TransportSelector extends StatelessWidget {
  final TransportMode selected;
  final ValueChanged<TransportMode> onSelect;
  const _TransportSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Expanded(child: _btn(TransportMode.apied)),
          const SizedBox(width: 8),
          Expanded(child: _btn(TransportMode.voiture)),
          const SizedBox(width: 8),
          Expanded(child: _btn(TransportMode.moto)),
        ],
      ),
    );
  }

  Widget _btn(TransportMode mode) {
    final sel = mode == selected;
    return GestureDetector(
      onTap: () => onSelect(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF0D77A6) : const Color(0xFFF0F4F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel ? const Color(0xFF0D77A6) : const Color(0xFFD5E0E9),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(mode.icon, size: 22, color: sel ? Colors.white : const Color(0xFF4A6070)),
            const SizedBox(height: 4),
            Text(
              mode.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : const Color(0xFF4A6070),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TicketVisual extends StatelessWidget {
  final ReservationRequest reservation;
  const TicketVisual({super.key,required this.reservation});

  @override
  Widget build(BuildContext context) {
    final r=reservation; final place=r.place;
    final ticketData='${r.ticketCode}|${place.id}|${r.dateTime.toIso8601String()}|${r.supportNeeds.join(';')}';
    return SizedBox(width:320,child:Column(mainAxisSize:MainAxisSize.min,children:[
      Container(decoration:BoxDecoration(color:const Color(0xFFFDFDFE),borderRadius:BorderRadius.circular(18),boxShadow:const[BoxShadow(color:Color(0x22000000),blurRadius:12,offset:Offset(0,4))]),
        child:Column(mainAxisSize:MainAxisSize.min,children:[
          Padding(padding:const EdgeInsets.fromLTRB(16,12,16,8),child:Row(children:[
            Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:const Color(0xFFE2F2FF),borderRadius:BorderRadius.circular(12)),child:const Icon(Icons.confirmation_num_rounded,color:Color(0xFF1E6FA2))),
            const SizedBox(width:12),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(place.name,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16)),
              const SizedBox(height:4),
              Text(place.city,style:const TextStyle(color:Color(0xFF5E7081),fontSize:13)),
            ])),
          ])),
          Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Row(children:[
            const Icon(Icons.schedule_rounded,size:16,color:Color(0xFF54718A)),const SizedBox(width:6),
            Text(_dateTimeLabel(r.dateTime),style:const TextStyle(color:Color(0xFF54718A),fontSize:13,fontWeight:FontWeight.w600)),
          ])),
          const SizedBox(height:8),
          Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Align(alignment:Alignment.centerLeft,
            child:Wrap(spacing:6,runSpacing:4,children:r.supportNeeds.map((need)=>Container(
              padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),
              decoration:BoxDecoration(color:const Color(0xFFE6F4FF),borderRadius:BorderRadius.circular(10)),
              child:Text(need,style:const TextStyle(color:Color(0xFF246A97),fontSize:11,fontWeight:FontWeight.w600)))).toList()))),
          const SizedBox(height:10),
          Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:CustomPaint(painter:_PerforationPainter(),child:const SizedBox(height:18))),
          Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:12),child:Row(children:[
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Text('CODE TICKET',style:TextStyle(color:Color(0xFF8A9AAC),fontSize:11,letterSpacing:1.0)),
              const SizedBox(height:4),
              Text(r.ticketCode,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16,letterSpacing:1.0)),
            ])),
            const SizedBox(width:12),
            AccessibilityQrCode(data:ticketData),
          ])),
        ])),
    ]));
  }
}

class _PerforationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas,Size size) {
    final paint=Paint()..color=const Color(0xFFE0E4EA)..strokeWidth=1.0..style=PaintingStyle.stroke;
    double startX=0; final y=size.height/2;
    while(startX<size.width){canvas.drawLine(Offset(startX,y),Offset(startX+5,y),paint);startX+=9;}
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}

class AccessibilityContributionsTabScreen extends StatelessWidget {
  final AccessiblePlace? selectedPlace;
  final List<UserContribution> contributions;
  final ContributionType newContributionType;
  final TextEditingController contributionController;
  final ValueChanged<ContributionType> onTypeChange;
  final VoidCallback onSubmit;
  const AccessibilityContributionsTabScreen({required this.selectedPlace,required this.contributions,required this.newContributionType,required this.contributionController,required this.onTypeChange,required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:BoxDecoration(borderRadius:BorderRadius.circular(16),color:Colors.white),
      child:SingleChildScrollView(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(selectedPlace==null?'Contribution collaborative':'Contribution pour ${selectedPlace!.name}',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700)),
        const SizedBox(height:8),
        DropdownButtonFormField<ContributionType>(
          initialValue:newContributionType,
          items:const[DropdownMenuItem(value:ContributionType.commentaire,child:Text('Commentaire')),DropdownMenuItem(value:ContributionType.photo,child:Text('Photo (description)')),DropdownMenuItem(value:ContributionType.signalement,child:Text('Signaler un probleme'))],
          onChanged:(v){if(v!=null)onTypeChange(v);},decoration:const InputDecoration(labelText:'Type de contribution')),
        const SizedBox(height:8),
        TextField(controller:contributionController,minLines:2,maxLines:4,decoration:const InputDecoration(border:OutlineInputBorder(),hintText:'Ajouter un commentaire...')),
        const SizedBox(height:8),
        FilledButton.icon(onPressed:selectedPlace==null?null:onSubmit,icon:const Icon(Icons.add_comment_rounded),label:const Text('Publier la contribution')),
        const Divider(height:24),
        const Text('Historique communautaire',style:TextStyle(fontWeight:FontWeight.w700)),
        const SizedBox(height:8),
        if(contributions.isEmpty) const Padding(padding:EdgeInsets.all(8),child:Text('Aucune contribution pour le moment.')),
        ...contributions.map((c)=>Card(child:ListTile(leading:Icon(_contribIcon(c.type)),title:Text(c.message),subtitle:Text('${c.author} - ${_dateTimeLabel(c.createdAt)}'),trailing:Text(_contribLabel(c.type))))),
      ])),
    );
  }
  IconData _contribIcon(ContributionType t){switch(t){case ContributionType.commentaire:return Icons.mode_comment_rounded;case ContributionType.photo:return Icons.photo_camera_rounded;case ContributionType.signalement:return Icons.report_problem_rounded;}}
  String   _contribLabel(ContributionType t){switch(t){case ContributionType.commentaire:return 'Commentaire';case ContributionType.photo:return 'Photo';case ContributionType.signalement:return 'Signalement';}}
}

class _SearchFiltersBar extends StatelessWidget {
  final TextEditingController controller;
  final DisabilityType selectedDisability;
  final ValueChanged<DisabilityType> onSelectDisability;
  final int filteredCount;
  final List<AccessiblePlace> searchResults;
  final ValueChanged<AccessiblePlace> onSelectPlace;

  const _SearchFiltersBar({
    required this.controller,
    required this.selectedDisability,
    required this.onSelectDisability,
    required this.filteredCount,
    required this.searchResults,
    required this.onSelectPlace,
  });

  static const _labels = {
    DisabilityType.moteur:   ('Moteur',   Icons.accessible_rounded,      Color(0xFF0D77A6)),
    DisabilityType.visuel:   ('Visuel',   Icons.visibility_off_rounded,  Color(0xFF7B3FA6)),
    DisabilityType.auditif:  ('Auditif',  Icons.hearing_rounded,         Color(0xFF1A8A5A)),
    DisabilityType.cognitif: ('Cognitif', Icons.psychology_rounded,      Color(0xFFD07A10)),
  };

  @override
  Widget build(BuildContext context) {
    final info    = _labels[selectedDisability]!;
    final label   = info.$1;
    final icon    = info.$2;
    final color   = info.$3;
    final hasQuery = controller.text.trim().isNotEmpty;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        // ── Barre de recherche ────────────────────────────────────────────────
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: hasQuery ? const Color(0xFF3A7FA5) : const Color(0xFFD9E4EB)),
              boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0,2))],
            ),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF3A7FA5)),
                hintText: 'Chercher un lieu accessible...',
                hintStyle: const TextStyle(color: Color(0xFF8EA0AD)),
                suffixIcon: hasQuery
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF8EA0AD)),
                        onPressed: () => controller.clear(),
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // ── Bouton filtre handicap ────────────────────────────────────────────
        PopupMenuButton<DisabilityType>(
          onSelected: onSelectDisability,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          offset: const Offset(0, 48),
          itemBuilder: (context) => _labels.entries.map((e) {
            final isSelected = e.key == selectedDisability;
            return PopupMenuItem<DisabilityType>(
              value: e.key,
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? e.value.$3.withValues(alpha: 0.15) : const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(e.value.$2, size: 18, color: isSelected ? e.value.$3 : const Color(0xFF607080)),
                ),
                const SizedBox(width: 10),
                Text('Handicap ${e.value.$1}',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? e.value.$3 : const Color(0xFF2D3E4E),
                  )),
                if (isSelected) ...[const Spacer(), Icon(Icons.check_rounded, size: 16, color: e.value.$3)],
              ]),
            );
          }).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0,3))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
                child: Text('$filteredCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        ),
      ]),

      // ── Liste des résultats de recherche ────────────────────────────────────
      if (hasQuery && searchResults.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 6),
          constraints: const BoxConstraints(maxHeight: 260),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD9E4EB)),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0,4))],
          ),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 6),
            shrinkWrap: true,
            itemCount: searchResults.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 52),
            itemBuilder: (context, i) {
              final p = searchResults[i];
              final catColors = {
                PlaceCategory.hopital:        const Color(0xFFD24C4C),
                PlaceCategory.administration: const Color(0xFF3A7FA5),
                PlaceCategory.cafe:           const Color(0xFFB06A10),
                PlaceCategory.commerce:       const Color(0xFF2A9F58),
                PlaceCategory.transport:      const Color(0xFF7B3FA6),
                PlaceCategory.autre:          const Color(0xFF5A7A8A),
              };
              final catColor = catColors[p.category] ?? const Color(0xFF5A7A8A);
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  onSelectPlace(p);
                  controller.clear();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_mapIconForCategory(p.category), size: 18, color: catColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1F2D3A))),
                      Text('${p.city} · ${p.distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF8EA0AD))),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: p.accessibilityScore >= 70
                            ? const Color(0xFFD9F5DE)
                            : p.accessibilityScore >= 50
                                ? const Color(0xFFFFF3DC)
                                : const Color(0xFFFFE4E4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${p.accessibilityScore}',
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800,
                            color: p.accessibilityScore >= 70
                                ? const Color(0xFF2D8D50)
                                : p.accessibilityScore >= 50
                                    ? const Color(0xFFAF6E14)
                                    : const Color(0xFFA83636),
                          )),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),

      if (hasQuery && searchResults.isEmpty)
        Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD9E4EB)),
          ),
          child: const Row(children: [
            Icon(Icons.search_off_rounded, color: Color(0xFF8EA0AD), size: 18),
            SizedBox(width: 8),
            Text('Aucun lieu trouvé', style: TextStyle(color: Color(0xFF8EA0AD), fontSize: 13)),
          ]),
        ),
    ]);
  }
}

class _CategoryFilters extends StatelessWidget {
  final Set<PlaceCategory> selectedCategories;
  final ValueChanged<PlaceCategory> onToggle;
  final List<AccessiblePlace> allPlaces;

  const _CategoryFilters({required this.selectedCategories, required this.onToggle, required this.allPlaces});

  static const _catInfo = {
    PlaceCategory.hopital:        ('Hôpitaux',   Icons.local_hospital_rounded,    Color(0xFFD24C4C)),
    PlaceCategory.administration: ('Admin',       Icons.account_balance_rounded,   Color(0xFF3A7FA5)),
    PlaceCategory.cafe:           ('Cafés',       Icons.local_cafe_rounded,        Color(0xFFB06A10)),
    PlaceCategory.commerce:       ('Commerces',   Icons.store_rounded,             Color(0xFF2A9F58)),
    PlaceCategory.transport:      ('Transport',   Icons.directions_transit_rounded,Color(0xFF7B3FA6)),
    PlaceCategory.autre:          ('Autres',      Icons.place_rounded,             Color(0xFF5A7A8A)),
  };

  @override
  Widget build(BuildContext context) {
    final activeCount = selectedCategories.length;
    final totalCats   = PlaceCategory.values.length;
    final allSelected = activeCount == totalCats;

    return PopupMenuButton<PlaceCategory>(
      onSelected: onToggle,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 48),
      itemBuilder: (context) => PlaceCategory.values.map((cat) {
        final info      = _catInfo[cat]!;
        final isOn      = selectedCategories.contains(cat);
        final count     = allPlaces.where((p) => p.category == cat).length;
        return PopupMenuItem<PlaceCategory>(
          value: cat,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isOn ? info.$3.withValues(alpha: 0.12) : const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(info.$2, size: 16, color: isOn ? info.$3 : const Color(0xFF8EA0AD)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                info.$1,
                style: TextStyle(
                  fontWeight: isOn ? FontWeight.w700 : FontWeight.w500,
                  color: isOn ? info.$3 : const Color(0xFF3A4F5E),
                  fontSize: 13,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isOn ? info.$3.withValues(alpha: 0.12) : const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isOn ? info.$3 : const Color(0xFF8EA0AD))),
            ),
            const SizedBox(width: 6),
            Icon(isOn ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                size: 18, color: isOn ? info.$3 : const Color(0xFFCCD5DC)),
          ]),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD7E0E8)),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0,2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.category_rounded, size: 16, color: Color(0xFF3A7FA5)),
          const SizedBox(width: 8),
          Text(
            allSelected ? 'Toutes catégories' : '$activeCount / $totalCats catégories',
            style: const TextStyle(color: Color(0xFF2D3E4E), fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.expand_more_rounded, size: 16, color: Color(0xFF8EA0AD)),
        ]),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final AccessiblePlace? place;
  final VoidCallback? onReserve;
  final VoidCallback onOpenReservationsHistory;
  final VoidCallback onRoute,onBack;
  final int reports,photos;
  final PlaceGeoInsights? geoInsights;
  final bool geoInsightsLoading,geoEnabled;
  final AIAccessibilityResult? aiResult;
  final bool aiLoading;
  const _PlaceCard({required this.place,required this.reports,required this.photos,required this.geoInsights,required this.geoInsightsLoading,required this.geoEnabled,required this.onReserve,required this.onOpenReservationsHistory,required this.onRoute,required this.onBack,this.aiResult,this.aiLoading=false});

  static final ButtonStyle _placeCardPrimaryFilled = FilledButton.styleFrom(
    backgroundColor: const Color(0xFF0D77A6),
    foregroundColor: Colors.white,
    minimumSize: const Size(0, 48),
  );

  @override
  Widget build(BuildContext context) {
    if (place==null) return const SizedBox.shrink();
    final p=place!;
    final maxCardHeight = MediaQuery.sizeOf(context).height * 0.58;
    return Positioned(left:10,right:10,bottom:10,child:ConstrainedBox(
      constraints:BoxConstraints(maxHeight:maxCardHeight),
      child:Container(
        decoration:BoxDecoration(color:const Color(0xFFF4F2F3).withValues(alpha:0.97),borderRadius:BorderRadius.circular(22),boxShadow:const[BoxShadow(color:Color(0x22000000),blurRadius:12,offset:Offset(0,-2))]),
        child:ClipRRect(
          borderRadius:BorderRadius.circular(22),
          child:SingleChildScrollView(
            padding:const EdgeInsets.fromLTRB(16,12,16,14),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
        Row(children:[
          IconButton(onPressed:onBack,visualDensity:VisualDensity.compact,icon:const Icon(Icons.arrow_back_rounded),tooltip:'Masquer la fiche'),
          _labelTag(_categoryLabel(p.category),const Color(0xFFE6EEF4),const Color(0xFF4D7692)),
        ]),
        const SizedBox(height:8),
        Text(p.name,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:20,color:Color(0xFF1F2D3A))),
        const SizedBox(height:4),
        Text('${p.city}, a ${p.distanceKm.toStringAsFixed(1)} km',style:const TextStyle(color:Color(0xFF566A79))),
        const SizedBox(height:4),
        Text(p.description,style:const TextStyle(color:Color(0xFF607080),fontSize:12)),
        const SizedBox(height:8),
        Wrap(spacing:8,runSpacing:6,children:[
          _equipBadge('Accès fauteuil',p.wheelchairAccess),_equipBadge('Ascenseur',p.elevator),_equipBadge('Toilettes',p.accessibleToilets),_equipBadge('Braille',p.braille),_equipBadge('Audio',p.audioAssistance),
          Chip(label:Text('Photos $photos'),visualDensity:VisualDensity.compact),
          Chip(label:Text('Signalements $reports'),visualDensity:VisualDensity.compact),
        ]),
        const SizedBox(height:6),
        if(geoInsightsLoading) const Padding(padding:EdgeInsets.symmetric(vertical:4),child:Row(children:[SizedBox(width:14,height:14,child:CircularProgressIndicator(strokeWidth:2)),SizedBox(width:8),Text('Recherche Geoapify...')])),
        if(geoInsights!=null&&geoInsights!.photoUrls.isNotEmpty)...[
          const SizedBox(height:4),
          Text('Photos: ${geoInsights!.sourceName}',style:const TextStyle(fontWeight:FontWeight.w700,fontSize:12)),
          const SizedBox(height:6),
          SizedBox(height:74,child:ListView.separated(scrollDirection:Axis.horizontal,physics:const ClampingScrollPhysics(),primary:false,itemCount:geoInsights!.photoUrls.length,separatorBuilder:(_,_)=>const SizedBox(width:6),itemBuilder:(context,i){
            final url=geoInsights!.photoUrls[i];
            return ClipRRect(borderRadius:BorderRadius.circular(8),child:Image.network(url,width:98,height:74,fit:BoxFit.cover,errorBuilder:(context,error,stackTrace)=>Container(width:98,height:74,color:const Color(0xFFE6ECF1),child:const Icon(Icons.broken_image_outlined))));
          })),
        ],
        const SizedBox(height:10),
        AIScorePanel(result:aiResult,isLoading:aiLoading),
        const SizedBox(height:12),
        Row(children:[
          Expanded(child:FilledButton.icon(
            style:_placeCardPrimaryFilled,
            onPressed:onReserve,
            icon:const Icon(Icons.support_agent_rounded),
            label:const Text('Réserver assistance',maxLines:1,overflow:TextOverflow.ellipsis))),
          const SizedBox(width:8),
          Expanded(child:FilledButton.icon(
            style:_placeCardPrimaryFilled,
            onPressed:onRoute,
            icon:const Icon(Icons.alt_route_rounded),
            label:const Text('Itinéraire',maxLines:1,overflow:TextOverflow.ellipsis))),
        ]),
        const SizedBox(height:10),
        SizedBox(
          width:double.infinity,
          child:FilledButton.icon(
            style:_placeCardPrimaryFilled,
            onPressed:onOpenReservationsHistory,
            icon:const Icon(Icons.event_note_rounded,size:20),
            label:const Text('Voir mes réservations'),
          ),
        ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _labelTag(String text,Color bg,Color fg)=>Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(12)),child:Text(text,style:TextStyle(color:fg,fontWeight:FontWeight.w700,fontSize:12)));
  Widget _equipBadge(String text,bool enabled)=>Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),decoration:BoxDecoration(color:enabled?const Color(0xFFD9F5DE):const Color(0xFFF9E4E4),borderRadius:BorderRadius.circular(12)),child:Text(text,style:TextStyle(color:enabled?const Color(0xFF2D8D50):const Color(0xFFAD3C3C),fontSize:11,fontWeight:FontWeight.w700)));
  String _categoryLabel(PlaceCategory c){switch(c){case PlaceCategory.hopital:return 'HOPITAL';case PlaceCategory.administration:return 'ADMIN';case PlaceCategory.cafe:return 'CAFE';case PlaceCategory.commerce:return 'COMMERCE';case PlaceCategory.transport:return 'TRANSPORT';case PlaceCategory.autre:return 'LIEU D INTERET';}}
}

class AccessibilityQrCode extends StatelessWidget {
  final String data;
  const AccessibilityQrCode({super.key,required this.data});

  @override
  Widget build(BuildContext context) => Container(color:Colors.white,padding:const EdgeInsets.all(4),
    child:QrImageView(data:data,version:QrVersions.auto,size:140,gapless:false,backgroundColor:Colors.white,
      eyeStyle:const QrEyeStyle(eyeShape:QrEyeShape.square,color:Colors.black),
      dataModuleStyle:const QrDataModuleStyle(dataModuleShape:QrDataModuleShape.square,color:Colors.black)));
}

String _dateTimeLabel(DateTime dt) {
  final d='${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
  final t='${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  return '$d - $t';
}
