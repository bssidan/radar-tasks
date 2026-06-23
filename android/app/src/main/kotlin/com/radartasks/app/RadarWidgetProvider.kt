package com.radartasks.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin

/// Widget למסך הבית — מציג ספירת משימות והמשימה הקרובה.
class RadarWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            // נתונים שנשמרו על ידי home_widget מצד Flutter.
            val prefs = HomeWidgetPlugin.getData(context)
            val waitingOnMe = prefs.getInt("waiting_on_me", 0)
            val active = prefs.getInt("active", 0)
            val overdue = prefs.getInt("overdue", 0)
            val nextTask = prefs.getString("next_task", "אין משימות קרובות")
            val title = prefs.getString("title", "Radar Tasks")

            val views = RemoteViews(context.packageName, R.layout.radar_widget)
            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_waiting_on_me, waitingOnMe.toString())
            views.setTextViewText(R.id.widget_active, active.toString())
            views.setTextViewText(R.id.widget_overdue, overdue.toString())
            views.setTextViewText(R.id.widget_next_task, nextTask)

            // לחיצה על ה-Widget פותחת את האפליקציה.
            val pendingIntent: PendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
