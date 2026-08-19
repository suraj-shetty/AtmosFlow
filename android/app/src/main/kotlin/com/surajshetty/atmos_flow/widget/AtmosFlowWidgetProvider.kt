package com.surajshetty.atmos_flow.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.TypedValue
import android.widget.RemoteViews
import com.surajshetty.atmos_flow.MainActivity
import com.surajshetty.atmos_flow.R

/** The home-screen widget: the design's 4×2 Android tile. */
class AtmosFlowWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        ids: IntArray,
    ) {
        ids.forEach { render(context, manager, it) }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        id: Int,
        options: Bundle,
    ) {
        // Resizing changes the tile's real dimensions, and the whole thing is
        // one painted bitmap — so it has to be repainted, not just re-laid.
        render(context, manager, id)
    }

    private fun render(context: Context, manager: AppWidgetManager, id: Int) {
        val options = manager.getAppWidgetOptions(id)
        val density = context.resources.displayMetrics.density
        fun px(dp: Int, fallback: Float) =
            ((if (dp > 0) dp.toFloat() else fallback) * density).toInt()

        val width = px(options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH), 280f)
        val height = px(options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT), 144f)

        val snapshot = WidgetSnapshot.read(context)
        val views = RemoteViews(context.packageName, R.layout.atmosflow_widget)
        views.setImageViewBitmap(
            R.id.atmosflow_tile,
            TileRenderer.render(context, snapshot, width, height),
        )
        views.setContentDescription(R.id.atmosflow_tile, snapshot.description)
        views.setOnClickPendingIntent(R.id.atmosflow_tile, openApp(context))
        manager.updateAppWidget(id, views)
    }

    private fun openApp(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    companion object {
        /** Repaints every placed widget — what the app calls after a refresh. */
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, AtmosFlowWidgetProvider::class.java),
            )
            if (ids.isEmpty()) return
            AtmosFlowWidgetProvider().onUpdate(context, manager, ids)
        }
    }
}
