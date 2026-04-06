package com.jlerisla.safebeacon.safe_beacon

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.os.Build
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val WIDGET_CHANNEL = "com.jlerisla.safebeacon/widget"
        private const val PREFS_FILE = "HomeWidgetPreferences"
        private const val KEY_IS_ACTIVE = "is_alert_active"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WIDGET_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestAddWidget" -> {
                    requestPinWidget()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Requests the launcher to display the pin-widget dialog with a live
     * preview of the panic button widget in its current state.
     *
     * The preview [RemoteViews] is built from the same layout and shared
     * preferences used by [PanicButtonWidget].
     */
    private fun requestPinWidget() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = AppWidgetManager.getInstance(this)
            val provider = ComponentName(this, PanicButtonWidget::class.java)
            if (!manager.isRequestPinAppWidgetSupported) return

            val prefs = getSharedPreferences(PREFS_FILE, MODE_PRIVATE)
            val isActive = prefs.getBoolean(KEY_IS_ACTIVE, false)

            // Build a preview showing the correct state (normal or active).
            val preview = RemoteViews(packageName, R.layout.panic_button_widget).apply {
                setViewVisibility(
                    R.id.layout_normal,
                    if (isActive) View.GONE else View.VISIBLE,
                )
                setViewVisibility(
                    R.id.layout_active,
                    if (isActive) View.VISIBLE else View.GONE,
                )
            }

            val extras = Bundle().apply {
                putParcelable(AppWidgetManager.EXTRA_APPWIDGET_PREVIEW, preview)
            }

            manager.requestPinAppWidget(provider, extras, null)
        }
    }
}

