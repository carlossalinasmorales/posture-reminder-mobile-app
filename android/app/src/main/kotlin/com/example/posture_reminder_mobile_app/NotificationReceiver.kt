package com.example.posture_reminder_mobile_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class NotificationActionReceiver : BroadcastReceiver() {
    companion object {
        const val CHANNEL = "notification_actions"
        const val ACTION_COMPLETE = "complete"
        const val ACTION_POSTPONE = "postpone"
        const val EXTRA_REMINDER_ID = "reminder_id"
        const val EXTRA_ACTION = "action"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d("NotificationAction", "Acción recibida: ${intent.action}")
        
        val reminderId = intent.getStringExtra(EXTRA_REMINDER_ID)
        val action = intent.getStringExtra(EXTRA_ACTION)
        
        Log.d("NotificationAction", "ReminderId: $reminderId, Action: $action")
        
        if (reminderId != null && action != null) {
            // Guardar la acción en SharedPreferences para procesarla cuando la app se abra
            val prefs = context.getSharedPreferences("notification_actions", Context.MODE_PRIVATE)
            prefs.edit()
                .putString("pending_reminder_id", reminderId)
                .putString("pending_action", action)
                .putLong("pending_timestamp", System.currentTimeMillis())
                .apply()
            
            Log.d("NotificationAction", "Acción guardada en SharedPreferences")
            
            // Intentar procesar inmediatamente si la app está en memoria
            try {
                MainActivity.processNotificationAction(context, reminderId, action)
            } catch (e: Exception) {
                Log.e("NotificationAction", "No se pudo procesar inmediatamente: ${e.message}")
            }
        }
    }
}