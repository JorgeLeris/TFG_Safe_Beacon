import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:safe_beacon/core/constants/constants.dart';

/// The result of a successful OSRM route request.
class OsrmRouteResult {
  const OsrmRouteResult({
    required this.points,
    required this.estimatedDuration,
  });

  /// Decoded GeoJSON polyline as a list of [LatLng] coordinates.
  final List<LatLng> points;

  /// OSRM travel-time estimate.
  final Duration estimatedDuration;
}

/// Fetches walking routes from the public OSRM API.
///
/// The base URL is defined in [Constants.osrmRoutingUrl].
class OsrmService {
  /// Requests a walking route from [from] to [to].
  ///
  /// Returns an [OsrmRouteResult] containing the decoded polyline and the
  /// estimated travel duration. Returns `null` when the request fails, the
  /// server returns a non-200 status, or the response contains no routes.
  Future<OsrmRouteResult?> fetchRoute(LatLng from, LatLng to) async {
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
          // ignore: avoid_dynamic_calls
          final durationSecs = (routes[0]['duration'] as num).toDouble();
          final estimatedDuration = Duration(
            seconds: (durationSecs * 1.25).round(),
          );
          return OsrmRouteResult(
            points: points,
            estimatedDuration: estimatedDuration,
          );
        }
      }
    } catch (_) {
      // Silently ignore routing errors.
    }
    return null;
  }
}
