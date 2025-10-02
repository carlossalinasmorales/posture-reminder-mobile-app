package com.example.posture_reminder_mobile_app

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    companion object {
        private const val CHANNEL = "notification_actions"
        private var methodChannel: MethodChannel? = null
        
        fun processNotificationAction(context: Context, reminderId: String, action: String) {
            Log.d("MainActivity", "Procesando acción: $action para $reminderId")
            methodChannel?.invokeMethod("onNotificationAction", mapOf(
                "reminderId" to reminderId,
                "action" to action
            ))
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPendingActions" -> {
                    checkPendingActions()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        checkPendingActions()
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        checkPendingActions()
    }
    
    private fun checkPendingActions() {
        val prefs = getSharedPreferences("notification_actions", Context.MODE_PRIVATE)
        val reminderId = prefs.getString("pending_reminder_id", null)
        val action = prefs.getString("pending_action", null)
        val timestamp = prefs.getLong("pending_timestamp", 0)
        
        // Solo procesar acciones de los últimos 5 minutos
        if (reminderId != null && action != null && 
            System.currentTimeMillis() - timestamp < 300000) {
            
            Log.d("MainActivity", "Procesando acción pendiente: $action para $reminderId")
            
            processNotificationAction(this, reminderId, action)
            
            // Limpiar las acciones pendientes
            prefs.edit().clear().apply()
        }
    }
}