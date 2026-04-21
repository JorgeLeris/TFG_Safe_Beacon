import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safe_beacon/core/constants/constants.dart';
import 'package:safe_beacon/core/language/generated/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/alerts/entities/alert.dart';
import 'package:safe_beacon/presentation/shared/widgets/others/map_location_pin.dart';
import 'package:url_launcher/url_launcher.dart';

class AlertMap extends StatefulWidget {
  final Alert alert;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const AlertMap({
    super.key,
    required this.alert,
    required this.l10n,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  State<AlertMap> createState() => AlertMapState();
}

class AlertMapState extends State<AlertMap> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final point = LatLng(widget.alert.latitude, widget.alert.longitude);

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
                height: 225,
                width: double.infinity,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: point,
                        initialZoom: 15,
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
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: point,
                              width: 25, // same as MapLocationPin size
                              height: 35, // size * 1.4
                              alignment: Alignment.topCenter,
                              child: const MapLocationPin(size: 25),
                            ),
                          ],
                        ),
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
                                    builder: (_) => _FullscreenMapPage(
                                      point: point,
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

                    // "My Location" button
                    Positioned(
                      bottom: 12,
                      left: 56,
                      child: Material(
                        color: widget.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        elevation: 2,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _mapController.move(point, 15),
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
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final url = Uri.parse(
                  Constants.googleMapsUrl(
                    widget.alert.latitude,
                    widget.alert.longitude,
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

// MARK: - Fullscreen map page

class _FullscreenMapPage extends StatefulWidget {
  final LatLng point;
  final ColorScheme colorScheme;
  final LatLng initialCenter;
  final double initialZoom;

  const _FullscreenMapPage({
    required this.point,
    required this.colorScheme,
    required this.initialCenter,
    required this.initialZoom,
  });

  @override
  State<_FullscreenMapPage> createState() => _FullscreenMapPageState();
}

class _FullscreenMapPageState extends State<_FullscreenMapPage> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
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
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.point,
                    width: 25, // same as MapLocationPin size
                    height: 35, // size * 1.4
                    alignment: Alignment.topCenter,
                    child: const MapLocationPin(size: 25),
                  ),
                ],
              ),
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

          // "My Location" button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 12,
            left: 56,
            child: Material(
              color: widget.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _mapController.move(widget.point, 15),
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
