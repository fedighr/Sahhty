package com.example.sahhty

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.work.CoroutineWorker
import androidx.work.ForegroundInfo
import androidx.work.WorkerParameters
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.coroutines.resume

class HeartRateWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    companion object {
        private const val TAG = "HeartRateWorker"
        private const val TIMEOUT_MS = 30_000L
        private const val DATA_PATH = "/sahhty/heart_rate"
        private const val CHANNEL_ID = "sahhty_monitor"
        private const val NOTIFICATION_ID = 1
    }

    override suspend fun getForegroundInfo(): ForegroundInfo {
        val manager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager

        if (manager.getNotificationChannel(CHANNEL_ID) == null) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Sahhty Monitor",
                    NotificationManager.IMPORTANCE_LOW
                )
            )
        }

        val notification = NotificationCompat.Builder(applicationContext, CHANNEL_ID)
            .setContentTitle("Sahhty")
            .setContentText("Mesure du rythme cardiaque...")
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .build()

        return ForegroundInfo(NOTIFICATION_ID, notification)
    }

    override suspend fun doWork(): Result {
        setForeground(getForegroundInfo())
        Log.d(TAG, "HeartRateWorker started — ${System.currentTimeMillis()}")

        val heartRate = readHeartRate()

        if (heartRate == null) {
            Log.w(TAG, "No heart rate reading within timeout")
            scheduleNext()
            return Result.success()
        }

        Log.d(TAG, "Heart rate measured: $heartRate BPM — sending to phone")

        return try {
            sendToPhone(heartRate)
            Log.d(TAG, "Sent successfully")
            scheduleNext()
            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send: ${e.message}")
            scheduleNext()
            Result.success()
        }
    }

    private fun scheduleNext() {
        val nextWork = androidx.work.OneTimeWorkRequestBuilder<HeartRateWorker>()
            .setInitialDelay(MainActivity.INTERVAL_MINUTES, java.util.concurrent.TimeUnit.MINUTES)
            .build()

        androidx.work.WorkManager.getInstance(applicationContext).enqueueUniqueWork(
            "sahhty_heart_rate_monitor",
            androidx.work.ExistingWorkPolicy.REPLACE,
            nextWork
        )
    }

    private suspend fun readHeartRate(): Float? {
        val sensorManager = applicationContext
            .getSystemService(Context.SENSOR_SERVICE) as SensorManager

        val heartRateSensor = sensorManager.getDefaultSensor(Sensor.TYPE_HEART_RATE)
            ?: run {
                Log.e(TAG, "Heart rate sensor not available")
                return null
            }

        return withTimeoutOrNull(TIMEOUT_MS) {
            suspendCancellableCoroutine { cont ->
                val listener = object : SensorEventListener {
                    override fun onSensorChanged(event: SensorEvent?) {
                        val value = event?.values?.firstOrNull()
                        if (value != null && value > 0f &&
                            event.accuracy >= SensorManager.SENSOR_STATUS_ACCURACY_LOW
                        ) {
                            sensorManager.unregisterListener(this)
                            if (cont.isActive) cont.resume(value)
                        }
                    }

                    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
                        Log.d(TAG, "Accuracy: $accuracy")
                    }
                }

                sensorManager.registerListener(
                    listener,
                    heartRateSensor,
                    SensorManager.SENSOR_DELAY_NORMAL
                )

                cont.invokeOnCancellation {
                    sensorManager.unregisterListener(listener)
                }
            }
        }
    }

    private suspend fun sendToPhone(heartRate: Float) {
        val dataClient: DataClient = Wearable.getDataClient(applicationContext)

        val putDataReq = PutDataMapRequest.create(DATA_PATH).apply {
            dataMap.putFloat("heart_rate", heartRate)
            dataMap.putLong("timestamp", System.currentTimeMillis())
            dataMap.putString("context", "smartwatch data")
        }.asPutDataRequest().setUrgent()

        dataClient.putDataItem(putDataReq).await()
    }
}