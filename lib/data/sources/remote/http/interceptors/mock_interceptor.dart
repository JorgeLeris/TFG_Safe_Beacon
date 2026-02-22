import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockInterceptor extends Interceptor {
  const MockInterceptor();

  static const _indexPath = 'assets/mocks/mock_index.json';
  static const _baseMockPath = 'assets/mocks';

  static const _defaultVariant = '0-ok';

  // See assets/mocks/mock_index.json for the structure of the index file.
  static Future<String> get _selectedVariant async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('mockType') ?? _defaultVariant;
  }

  /// Intercepts the request to provide a mock response if the path matches.
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final variant = await _selectedVariant;
    final endpointBase = options.path
        .replaceFirst('/api/', '')
        .replaceAll('/', '_');

    try {
      final indexString = await rootBundle.loadString(_indexPath);
      final Map<String, dynamic> indexData = jsonDecode(indexString);

      if (indexData.containsKey(endpointBase)) {
        final Map<String, dynamic> variants = indexData[endpointBase];

        // Selects the variant defined statically.
        if (variants.containsKey(variant)) {
          final String relativePath = variants[variant];
          final filePath = '$_baseMockPath/$relativePath';

          final responseString = await rootBundle.loadString(filePath);
          final data = jsonDecode(responseString);

          return handler.resolve(
            Response(requestOptions: options, statusCode: 200, data: data),
          );
        }
      }

      appLogger.info('Mock not found for $endpointBase for $variant');
    } catch (e, s) {
      appLogger.severe('Error for $endpointBase', e, s);
    }

    // If no mock is found or an error is caught, continue with the real request.
    handler.next(options);
  }
}
