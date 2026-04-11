import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safe_beacon/core/constants/constants.dart';
import 'package:safe_beacon/core/language/generated/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/shared/widgets/others/map_location_pin.dart';
import 'package:url_launcher/url_launcher.dart';

class GuardianModeMap extends StatefulWidget {
  final LatLng currentLocation;
  final LatLng? destinationPoint;
  final bool isActive;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final ValueChanged<LatLng>? onDestinationChanged;

  const GuardianModeMap({
    super.key,
    required this.currentLocation,
    required this.isActive,
    required this.l10n,
    required this.colorScheme,
    required this.textTheme,
    this.destinationPoint,
    this.onDestinationChanged,
  });

  @override
  State<GuardianModeMap> createState() => _GuardianModeMapState();
}

class _GuardianModeMapState extends State<GuardianModeMap> {
  final MapController _mapController = MapController();

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (widget.isActive) return;
    widget.onDestinationChanged?.call(point);

    debugPrint(
      '[GuardianModeMap] Current location: '
      '${widget.currentLocation.latitude}, ${widget.currentLocation.longitude} | '
      'Destination: ${point.latitude}, ${point.longitude}',
    );
  }

  List<Marker> get _markers {
    return [
      // Current location marker (blue)
      Marker(
        point: widget.currentLocation,
        width: 25,
        height: 35,
        alignment: Alignment.topCenter,
        child: const MapLocationPin(size: 25, color: Color(0xFF1565C0)),
      ),
      // Destination marker (red, only when set)
      if (widget.destinationPoint != null)
        Marker(
          point: widget.destinationPoint!,
          width: 25,
          height: 35,
          alignment: Alignment.topCenter,
          child: const MapLocationPin(size: 25),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 280,
                width: double.infinity,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: widget.currentLocation,
                        initialZoom: 15,
                        minZoom: 4,
                        maxZoom: 19,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                        onTap: _onMapTap,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: Constants.openStreetMapTileUrl,
                          userAgentPackageName: Constants.bundleId,
                        ),
                        MarkerLayer(markers: _markers),
                        RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution(
                              Constants.openStreetMapAttribution,
                              onTap: () => launchUrl(
                                Uri.parse(Constants.openStreetMapCopyrightUrl),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Fullscreen button
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Material(
                        color: widget.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        elevation: 2,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => _GuardianFullscreenMapPage(
                                currentLocation: widget.currentLocation,
                                destinationPoint: widget.destinationPoint,
                                isActive: widget.isActive,
                                colorScheme: widget.colorScheme,
                                onDestinationChanged: (point) {
                                  widget.onDestinationChanged?.call(point);
                                  debugPrint(
                                    '[GuardianModeMap] Current location: '
                                    '${widget.currentLocation.latitude}, ${widget.currentLocation.longitude} | '
                                    'Destination: ${point.latitude}, ${point.longitude}',
                                  );
                                },
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.fullscreen_rounded,
                              size: 20,
                              color: widget.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // My location button
                    Positioned(
                      bottom: 12,
                      left: 56,
                      child: Material(
                        color: widget.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        elevation: 2,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () =>
                              _mapController.move(widget.currentLocation, 15),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.my_location_rounded,
                              size: 20,
                              color: widget.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Tap hint (only when inactive and no destination set yet)
                    if (!widget.isActive && widget.destinationPoint == null)
                      Positioned(
                        top: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: widget.colorScheme.surface.withValues(
                                alpha: 0.88,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.touch_app_rounded,
                                  size: 14,
                                  color: widget.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.l10n.guardianModeSetDestination,
                                  style: widget.textTheme.labelSmall?.copyWith(
                                    color: widget.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Map legend
          const SizedBox(height: 8),
          Row(
            children: [
              const _LegendDot(color: Color(0xFF1565C0)),
              const SizedBox(width: 4),
              Text(
                'Tu ubicación',
                style: widget.textTheme.labelSmall?.copyWith(
                  color: widget.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 14),
              const _LegendDot(color: Color(0xFFE53935)),
              const SizedBox(width: 4),
              Text(
                'Destino',
                style: widget.textTheme.labelSmall?.copyWith(
                  color: widget.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// MARK: - Legend dot helper

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// MARK: - Fullscreen map page

class _GuardianFullscreenMapPage extends StatefulWidget {
  final LatLng currentLocation;
  final LatLng? destinationPoint;
  final bool isActive;
  final ColorScheme colorScheme;
  final ValueChanged<LatLng> onDestinationChanged;

  const _GuardianFullscreenMapPage({
    required this.currentLocation,
    required this.destinationPoint,
    required this.isActive,
    required this.colorScheme,
    required this.onDestinationChanged,
  });

  @override
  State<_GuardianFullscreenMapPage> createState() =>
      _GuardianFullscreenMapPageState();
}

class _GuardianFullscreenMapPageState
    extends State<_GuardianFullscreenMapPage> {
  final MapController _mapController = MapController();
  late LatLng? _destinationPoint;

  @override
  void initState() {
    super.initState();
    _destinationPoint = widget.destinationPoint;
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (widget.isActive) return;
    setState(() => _destinationPoint = point);
    widget.onDestinationChanged(point);
  }

  List<Marker> get _markers {
    return [
      Marker(
        point: widget.currentLocation,
        width: 25,
        height: 35,
        alignment: Alignment.topCenter,
        child: const MapLocationPin(size: 25, color: Color(0xFF1565C0)),
      ),
      if (_destinationPoint != null)
        Marker(
          point: _destinationPoint!,
          width: 25,
          height: 35,
          alignment: Alignment.topCenter,
          child: const MapLocationPin(size: 25),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.currentLocation,
              initialZoom: 15,
              minZoom: 4,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: Constants.openStreetMapTileUrl,
                userAgentPackageName: Constants.bundleId,
              ),
              MarkerLayer(markers: _markers),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    Constants.openStreetMapAttribution,
                    onTap: () => launchUrl(
                      Uri.parse(Constants.openStreetMapCopyrightUrl),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Close button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 12,
            left: 12,
            child: Material(
              color: widget.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.fullscreen_exit_rounded,
                    size: 20,
                    color: widget.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),

          // My location button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 12,
            left: 56,
            child: Material(
              color: widget.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _mapController.move(widget.currentLocation, 15),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.my_location_rounded,
                    size: 20,
                    color: widget.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
