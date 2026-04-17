package com.example.sahhty

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
import androidx.work.CoroutineWorker
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
    }

    override suspend fun doWork(): Result {
        Log.d(TAG, "HeartRateWorker started")

        val heartRate = readHeartRate()
        if (heartRate == null) {
            Log.w(TAG, "No heart rate reading within timeout")
            return Result.retry()
        }

        Log.d(TAG, "Heart rate measured: $heartRate BPM")

        return try {
            sendToPhone(heartRate)
            Log.d(TAG, "Heart rate sent to phone successfully")
            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send to phone: ${e.message}")
            Result.retry()
        }
    }

    private suspend fun readHeartRate(): Float? {
        val sensorManager = applicationContext.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val heartRateSensor = sensorManager.getDefaultSensor(Sensor.TYPE_HEART_RATE)
            ?: run {
                Log.e(TAG, "Heart rate sensor not available on this device")
                return null
            }

        return withTimeoutOrNull(TIMEOUT_MS) {
            suspendCancellableCoroutine { cont ->
                val listener = object : SensorEventListener {
                    override fun onSensorChanged(event: SensorEvent?) {
                        val value = event?.values?.firstOrNull()
                        if (value != null && value > 0f) {
                            sensorManager.unregisterListener(this)
                            if (cont.isActive) cont.resume(value)
                        }
                    }

                    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
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
