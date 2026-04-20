package com.example.sahhty

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.WearableListenerService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class PhoneWearListenerService : WearableListenerService() {

    companion object {
        private const val TAG = "PhoneWearListener"
        private const val HEART_RATE_PATH = "/sahhty/heart_rate"
        private const val BACKEND_URL = "http://192.168.100.10:8000/measurements/MeasurementService/create_measurement/"
        private const val CHANNEL_ID = "sahhty_risk_alerts"
        private const val NOTIFICATION_ID = 1001
        const val ACTION_HEART_RATE = "com.example.sahhty.HEART_RATE_FROM_WATCH"
        const val ACTION_RISK_ALERT = "com.example.sahhty.RISK_ALERT"
        const val EXTRA_HEART_RATE = "heart_rate"
        const val EXTRA_TIMESTAMP = "timestamp"
        const val EXTRA_CONTEXT = "context"
        const val EXTRA_RISK_LEVEL = "risk_level"
        const val EXTRA_RISK_NOTE = "note"
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        super.onDataChanged(dataEvents)
        for (event in dataEvents) {
            if (event.type == DataEvent.TYPE_CHANGED &&
                event.dataItem.uri.path == HEART_RATE_PATH
            ) {
                val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap
                val heartRate = dataMap.getFloat("heart_rate")
                val timestamp = dataMap.getLong("timestamp")
                val ctx = dataMap.getString("context", "smartwatch data")

                Log.d(TAG, "Received HR from watch: $heartRate BPM at $timestamp")

                // Broadcast to Flutter if app is open
                sendBroadcast(Intent(ACTION_HEART_RATE).apply {
                    setPackage(packageName)
                    putExtra(EXTRA_HEART_RATE, heartRate)
                    putExtra(EXTRA_TIMESTAMP, timestamp)
                    putExtra(EXTRA_CONTEXT, ctx)
                })

                // Always POST to backend directly
                postToBackend(heartRate, ctx)
            }
        }
    }

    private fun postToBackend(heartRate: Float, context: String) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val prefs = getSharedPreferences("sahhty_prefs", Context.MODE_PRIVATE)

                val patientId = prefs.getString("patient_id", null) ?: run {
                    Log.w(TAG, "No patient_id found — app not opened yet?")
                    return@launch
                }

                val token = prefs.getString("token", null) ?: run {
                    Log.w(TAG, "No token found — user not logged in?")
                    return@launch
                }

                val payload = JSONObject().apply {
                    put("type", "HEART_RATE")
                    put("value1", heartRate.toBigDecimal().toPlainString())
                    put("unit", "BPM")
                    put("context", context)
                    put("patient_id", patientId.toInt())
                }.toString()

                Log.d(TAG, "Posting to backend: $payload")

                val connection = URL(BACKEND_URL).openConnection() as HttpURLConnection
                connection.apply {
                    requestMethod = "POST"
                    setRequestProperty("Content-Type", "application/json")
                    setRequestProperty("Authorization", "Bearer $token")
                    doOutput = true
                    connectTimeout = 10000
                    readTimeout = 10000
                }

                connection.outputStream.use { it.write(payload.toByteArray()) }

                val responseCode = connection.responseCode
                Log.d(TAG, "Backend response code: $responseCode")

                if (responseCode == 200 || responseCode == 201) {
                    val response = connection.inputStream.bufferedReader().readText()
                    val json = JSONObject(response)
                    val data = json.optJSONObject("data")

                    if (data != null) {
                        val riskLevel = data.optString("risk_level", "")
                        val note = data.optString("note", "")

                        Log.d(TAG, "Risk level: $riskLevel — $note")

                        // Broadcast to Flutter if app is open
                        sendBroadcast(Intent(ACTION_RISK_ALERT).apply {
                            setPackage(packageName)
                            putExtra(EXTRA_RISK_LEVEL, riskLevel)
                            putExtra(EXTRA_RISK_NOTE, note)
                            putExtra(EXTRA_HEART_RATE, heartRate)
                        })

                        // Show notification if HIGH risk
                        if (riskLevel == "HIGH") {
                            showRiskNotification(heartRate, note)
                        }
                    }
                }

                connection.disconnect()

            } catch (e: Exception) {
                Log.e(TAG, "Failed to POST to backend: ${e.message}")
            }
        }
    }

    private fun showRiskNotification(heartRate: Float, note: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (manager.getNotificationChannel(CHANNEL_ID) == null) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Alertes de santé",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Alertes de risque détectées par la montre"
                }
            )
        }

        val openAppIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("⚠️ Alerte santé détectée")
            .setContentText("Rythme cardiaque: ${heartRate.toInt()} BPM")
            .setStyle(NotificationCompat.BigTextStyle().bigText(note))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(openAppIntent)
            .build()

        manager.notify(NOTIFICATION_ID, notification)
    }
}