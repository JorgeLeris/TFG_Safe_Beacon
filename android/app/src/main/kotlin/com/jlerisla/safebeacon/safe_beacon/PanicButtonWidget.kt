package com.jlerisla.safebeacon.safe_beacon

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

/**
 * Android AppWidget provider for the SafeBeacon panic button home-screen widget.
 *
 * Both buttons simply open [MainActivity]; Flutter shows the correct panic
 * button state via [PanicButtonCubit.loadAlertState] on screen entry.
 */
class PanicButtonWidget : AppWidgetProvider() {

    companion object {
        private const val PREFS_FILE = "HomeWidgetPreferences"
        private const val KEY_IS_ACTIVE = "is_alert_active"

        /** Builds and pushes the RemoteViews for a single widget instance. */
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val prefs = context.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
            val isActive = prefs.getBoolean(KEY_IS_ACTIVE, false)

            val views = RemoteViews(context.packageName, R.layout.panic_button_widget)

            // Toggle layout visibility
            views.setViewVisibility(
                R.id.layout_normal,
                if (isActive) View.GONE else View.VISIBLE,
            )
            views.setViewVisibility(
                R.id.layout_active,
                if (isActive) View.VISIBLE else View.GONE,
            )

            // Both buttons open the app — Flutter handles the current state.
            val openIntent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 0, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            views.setOnClickPendingIntent(R.id.btn_activate, pendingIntent)
            views.setOnClickPendingIntent(R.id.btn_open_app, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }
}
