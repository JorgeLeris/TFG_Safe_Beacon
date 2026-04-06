import 'dart:io';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';

/// Manages the home-screen widget state for the panic button.
///
/// The native widget reads a boolean flag from shared storage to decide which
/// visual state to render:
///   - `false` → standby ("SOS / Activar alerta")
///   - `true`  → active ("Alerta activa / Abrir SafeBeacon")
///
/// Both widget buttons simply open the app.
class PanicWidgetService {
  PanicWidgetService._();

  /// Key used in shared storage to persist the alert-active boolean.
  static const String isActiveKey = 'is_alert_active';

  // --- Widget identifiers 

  /// App Group ID shared between the iOS app and the widget extension.
  static const String _appGroupId =
      'group.com.jlerisla.safebeacon.safe_beacon';

  /// Fully-qualified Android AppWidgetProvider class name.
  static const String _androidWidgetName =
      'com.jlerisla.safebeacon.safe_beacon.PanicButtonWidget';

  /// iOS WidgetKit widget kind.
  static const String _iOSWidgetName = 'SafeBeaconWidget';

  // --- Method channel for "Pin widget" on Android

  static const MethodChannel _channel =
      MethodChannel('com.jlerisla.safebeacon/widget');

  // --- Public API

  /// Initialises the service. Call once on app startup, before the first frame.
  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Persists the alert state and triggers a native widget redraw.
  static Future<void> setAlertActive({required bool isActive}) async {
    try {
      await HomeWidget.saveWidgetData<bool>(isActiveKey, isActive);
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidWidgetName,
        iOSName: _iOSWidgetName,
      );
    } catch (e, st) {
      appLogger.warning('PanicWidgetService: widget update failed', e, st);
    }
  }

  /// Asks the OS to show the pin-widget dialog.
  static Future<void> requestPinWidget() async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('requestAddWidget');
    } else {
      throw PlatformException(
        code: 'UNSUPPORTED',
        message: 'Pin-widget not supported on this platform',
      );
    }
  }
}
