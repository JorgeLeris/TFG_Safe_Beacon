import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:safe_beacon/core/constants/constants.dart';
import 'package:safe_beacon/core/language/generated/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/shared/widgets/others/map_location_pin.dart';
import 'package:url_launcher/url_launcher.dart';

/// Map widget for the follow-up detail screen.
///
/// Shows three points: the start location, the last known user location, and the destination.
///  + The computed route between start and destination.
class FollowUpMap extends StatefulWidget {
  final LatLng startPoint;
  final LatLng userPoint;
  final LatLng? destinationPoint;
  final String lastUpdateLabel;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const FollowUpMap({
    super.key,
    required this.startPoint,
    required this.userPoint,
    this.destinationPoint,
    required this.lastUpdateLabel,
    required this.l10n,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  State<FollowUpMap> createState() => _FollowUpMapState();
}

class _FollowUpMapState extends State<FollowUpMap> {
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    if (widget.destinationPoint != null) {
      _fetchRoute(widget.startPoint, widget.destinationPoint!);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchRoute(LatLng from, LatLng to) async {
    final url = Uri.parse(
      '${Constants.osrmRoutingUrl}'
      '${from.longitude},${from.latitude};'
      '${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          // ignore: avoid_dynamic_calls
          final geometry = routes[0]['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List<dynamic>;
          final points = coordinates
              .cast<List<dynamic>>()
              .map(
                (c) =>
                    LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
              )
              .toList();
          if (mounted) setState(() => _routePoints = points);
        }
      }
    } catch (_) {
      // Silently ignore routing errors.
    }
  }

  List<Marker> get _markers {
    return [
      // Start location (green)
      Marker(
        point: widget.startPoint,
        width: 25,
        height: 35,
        alignment: Alignment.topCenter,
        child: const MapLocationPin(size: 25, color: Color(0xFF2E7D32)),
      ),
      // Current user location (blue)
      Marker(
        point: widget.userPoint,
        width: 25,
        height: 35,
        alignment: Alignment.topCenter,
        child: const MapLocationPin(size: 25, color: Color(0xFF1565C0)),
      ),
      // Destination (red)
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last update label
          Text(
            widget.lastUpdateLabel,
            style: widget.textTheme.bodySmall?.copyWith(
              color: widget.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 8),

          // Map
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
                height: 225,
                width: double.infinity,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: widget.userPoint,
                        initialZoom: 14,
                        minZoom: 4,
                        maxZoom: 19,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: Constants.openStreetMapTileUrl,
                          userAgentPackageName: Constants.bundleId,
                        ),
                        if (_routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                color: const Color(0xFF4285F4),
                                strokeWidth: 4.0,
                              ),
                            ],
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
                          onTap: () async {
                            final result = await Navigator.of(context)
                                .push<(LatLng, double)>(
                                  MaterialPageRoute<(LatLng, double)>(
                                    builder: (_) => _FullscreenFollowUpMapPage(
                                      startPoint: widget.startPoint,
                                      userPoint: widget.userPoint,
                                      destinationPoint: widget.destinationPoint,
                                      routePoints: _routePoints,
                                      colorScheme: widget.colorScheme,
                                      initialCenter:
                                          _mapController.camera.center,
                                      initialZoom: _mapController.camera.zoom,
                                    ),
                                  ),
                                );
                            if (result != null) {
                              _mapController.move(result.$1, result.$2);
                            }
                          },
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

                    // My location button (centers on current user)
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
                              _mapController.move(widget.userPoint, 15),
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
              ),
            ),
          ),

          // Map legend
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _LegendDot(
                color: const Color(0xFF2E7D32),
                label: 'Origen',
                textTheme: widget.textTheme,
                colorScheme: widget.colorScheme,
              ),
              _LegendDot(
                color: const Color(0xFF1565C0),
                label: 'Ubicación actual',
                textTheme: widget.textTheme,
                colorScheme: widget.colorScheme,
              ),
              _LegendDot(
                color: const Color(0xFFE53935),
                label: 'Destino',
                textTheme: widget.textTheme,
                colorScheme: widget.colorScheme,
              ),
            ],
          ),

          // Open in Google Maps
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final url = Uri.parse(
                  Constants.googleMapsUrl(
                    widget.userPoint.latitude,
                    widget.userPoint.longitude,
                  ),
                );
                launchUrl(url, mode: LaunchMode.externalApplication);
              },
              icon: Icon(
                Icons.map_outlined,
                color: widget.colorScheme.tertiary,
              ),
              label: Text(
                widget.l10n.openInGoogleMaps,
                style: TextStyle(color: widget.colorScheme.tertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _LegendDot({
    required this.color,
    required this.label,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

// MARK: - Fullscreen map page

class _FullscreenFollowUpMapPage extends StatefulWidget {
  final LatLng startPoint;
  final LatLng userPoint;
  final LatLng? destinationPoint;
  final List<LatLng> routePoints;
  final ColorScheme colorScheme;
  final LatLng initialCenter;
  final double initialZoom;

  const _FullscreenFollowUpMapPage({
    required this.startPoint,
    required this.userPoint,
    this.destinationPoint,
    required this.routePoints,
    required this.colorScheme,
    required this.initialCenter,
    required this.initialZoom,
  });

  @override
  State<_FullscreenFollowUpMapPage> createState() =>
      _FullscreenFollowUpMapPageState();
}

class _FullscreenFollowUpMapPageState
    extends State<_FullscreenFollowUpMapPage> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<Marker> get _markers {
    return [
      Marker(
        point: widget.startPoint,
        width: 25,
        height: 35,
        alignment: Alignment.topCenter,
        child: const MapLocationPin(size: 25, color: Color(0xFF2E7D32)),
      ),
      Marker(
        point: widget.userPoint,
        width: 25,
        height: 35,
        alignment: Alignment.topCenter,
        child: const MapLocationPin(size: 25, color: Color(0xFF1565C0)),
      ),
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
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: widget.initialZoom,
              minZoom: 4,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: Constants.openStreetMapTileUrl,
                userAgentPackageName: Constants.bundleId,
              ),
              if (widget.routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.routePoints,
                      color: const Color(0xFF4285F4),
                      strokeWidth: 4.0,
                    ),
                  ],
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
                onTap: () => Navigator.of(context).pop((
                  _mapController.camera.center,
                  _mapController.camera.zoom,
                )),
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
                onTap: () => _mapController.move(widget.userPoint, 15),
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
