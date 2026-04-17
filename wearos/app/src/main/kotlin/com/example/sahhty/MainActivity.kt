package com.example.sahhty

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.TextView
import android.widget.LinearLayout
import android.view.Gravity
import androidx.activity.ComponentActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

class MainActivity : ComponentActivity() {

    companion object {
        private const val WORK_NAME = "sahhty_heart_rate_monitor"
        private const val PERMISSION_REQUEST_CODE = 100
        private const val INTERVAL_MINUTES = 30L
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(32, 32, 32, 32)
        }

        val statusText = TextView(this).apply {
            textSize = 14f
            gravity = Gravity.CENTER
        }
        layout.addView(statusText)
        setContentView(layout)

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.BODY_SENSORS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.BODY_SENSORS),
                PERMISSION_REQUEST_CODE
            )
            statusText.text = "Requesting sensor permission..."
        } else {
            scheduleHeartRateWorker()
            statusText.text = "✅ Sahhty Monitor Active\n\nHeart rate measured every 30 min\nand sent to your phone automatically."
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE &&
            grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        ) {
            scheduleHeartRateWorker()
            recreate()
        }
    }

    private fun scheduleHeartRateWorker() {
        val constraints = Constraints.Builder()
            .setRequiresDeviceIdle(false)
            .build()

        val workRequest = PeriodicWorkRequestBuilder<HeartRateWorker>(
            INTERVAL_MINUTES, TimeUnit.MINUTES
        )
            .setConstraints(constraints)
            .build()

        WorkManager.getInstance(applicationContext).enqueueUniquePeriodicWork(
            WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            workRequest
        )
    }
}
