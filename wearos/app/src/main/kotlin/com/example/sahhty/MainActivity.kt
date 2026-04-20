package com.example.sahhty

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import androidx.activity.ComponentActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkInfo
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

class MainActivity : ComponentActivity() {

    companion object {
        private const val WORK_NAME = "sahhty_heart_rate_monitor"
        private const val PERMISSION_REQUEST_CODE = 100
        const val INTERVAL_MINUTES = 1L
    }

    private lateinit var statusText: TextView
    private lateinit var timerText: TextView
    private lateinit var lastSyncText: TextView
    private lateinit var heartRateText: TextView
    private lateinit var pulseIcon: TextView
    private lateinit var progressBar: ProgressBar

    private val handler = android.os.Handler(android.os.Looper.getMainLooper())
    private var nextSendTime = 0L
    private var lastSyncTime = 0L
    private var lastHeartRate = 0f
    private var isMeasuring = false

    private val primaryColor = Color.parseColor("#E53935")
    private val backgroundColor = Color.parseColor("#121212")
    private val textPrimary = Color.parseColor("#FFFFFF")
    private val textSecondary = Color.parseColor("#AAAAAA")
    private val measuringColor = Color.parseColor("#FFA000")

    private val heartRateUpdateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == DataLayerService.ACTION_UPDATE_HR) {
                val hr = intent.getFloatExtra(DataLayerService.EXTRA_HEART_RATE, 0f)
                if (hr > 0f) {
                    updateHeartRate(hr)
                }
            }
        }
    }

    private val timerRunnable = object : Runnable {
        override fun run() {
            updateUI()
            handler.postDelayed(this, 1000)
        }
    }

    private val workObserverRunnable = object : Runnable {
        override fun run() {
            observeWorkerStatus()
            handler.postDelayed(this, 2000)
        }
    }

    private val pulseRunnable = object : Runnable {
        override fun run() {
            if (isMeasuring) {
                pulseIcon.animate()
                    .scaleX(1.3f).scaleY(1.3f)
                    .setDuration(300)
                    .withEndAction {
                        pulseIcon.animate()
                            .scaleX(1f).scaleY(1f)
                            .setDuration(300)
                            .start()
                    }.start()
            }
            handler.postDelayed(this, 700)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(buildUI())
        checkAndRequestPermissions()
    }

    override fun onResume() {
        super.onResume()

        val filter = IntentFilter(DataLayerService.ACTION_UPDATE_HR)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(heartRateUpdateReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(heartRateUpdateReceiver, filter)
        }

        handler.post(timerRunnable)
        handler.post(workObserverRunnable)
        handler.post(pulseRunnable)
    }

    override fun onPause() {
        super.onPause()
        unregisterReceiver(heartRateUpdateReceiver)
        handler.removeCallbacks(timerRunnable)
        handler.removeCallbacks(workObserverRunnable)
        handler.removeCallbacks(pulseRunnable)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE &&
            grantResults.isNotEmpty() &&
            grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        ) {
            startMonitoring()
        }
    }

    private fun buildUI(): LinearLayout {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(backgroundColor)
            setPadding(24, 24, 24, 24)
        }

        pulseIcon = TextView(this).apply {
            text = "♥"
            textSize = 32f
            setTextColor(primaryColor)
            gravity = Gravity.CENTER
        }
        root.addView(pulseIcon)

        heartRateText = TextView(this).apply {
            text = "-- BPM"
            textSize = 26f
            setTextColor(textPrimary)
            gravity = Gravity.CENTER
            setPadding(0, 4, 0, 0)
            typeface = Typeface.DEFAULT_BOLD
        }
        root.addView(heartRateText)

        val divider = View(this).apply {
            setBackgroundColor(Color.parseColor("#333333"))
            layoutParams = LinearLayout.LayoutParams(
                120.dpToPx(), 1.dpToPx()
            ).apply { setMargins(0, 12, 0, 12) }
        }
        root.addView(divider)

        statusText = TextView(this).apply {
            text = "Sahhty Monitor"
            textSize = 13f
            setTextColor(textPrimary)
            gravity = Gravity.CENTER
        }
        root.addView(statusText)

        timerText = TextView(this).apply {
            text = "Initialisation..."
            textSize = 12f
            setTextColor(primaryColor)
            gravity = Gravity.CENTER
            setPadding(0, 6, 0, 0)
        }
        root.addView(timerText)

        progressBar = ProgressBar(
            this, null,
            android.R.attr.progressBarStyleHorizontal
        ).apply {
            layoutParams = LinearLayout.LayoutParams(
                160.dpToPx(), 4.dpToPx()
            ).apply { setMargins(0, 8, 0, 8) }
            max = (INTERVAL_MINUTES * 60).toInt()
            progress = 0
            progressDrawable.setColorFilter(
                primaryColor,
                android.graphics.PorterDuff.Mode.SRC_IN
            )
            isIndeterminate = false
            visibility = View.GONE
        }
        root.addView(progressBar)

        lastSyncText = TextView(this).apply {
            text = "En attente..."
            textSize = 10f
            setTextColor(textSecondary)
            gravity = Gravity.CENTER
            setPadding(0, 4, 0, 0)
        }
        root.addView(lastSyncText)

        return root
    }

    private fun Int.dpToPx(): Int =
        (this * resources.displayMetrics.density).toInt()

    private fun checkAndRequestPermissions() {
        val permissionsNeeded = mutableListOf<String>()

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.BODY_SENSORS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            permissionsNeeded.add(Manifest.permission.BODY_SENSORS)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.BODY_SENSORS_BACKGROUND
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            permissionsNeeded.add(Manifest.permission.BODY_SENSORS_BACKGROUND)
        }

        if (permissionsNeeded.isEmpty()) {
            startMonitoring()
        } else {
            ActivityCompat.requestPermissions(
                this,
                permissionsNeeded.toTypedArray(),
                PERMISSION_REQUEST_CODE
            )
            statusText.text = "Permissions requises"
            timerText.text = "Veuillez autoriser"
        }
    }

    private fun startMonitoring() {
        scheduleHeartRateWorker()
        nextSendTime = System.currentTimeMillis() + INTERVAL_MINUTES * 60 * 1000
        statusText.text = "Surveillance active"
    }

    private fun observeWorkerStatus() {
        WorkManager.getInstance(applicationContext)
            .getWorkInfosForUniqueWork(WORK_NAME)
            .get()
            ?.firstOrNull()
            ?.let { workInfo ->
                when (workInfo.state) {
                    WorkInfo.State.RUNNING -> {
                        isMeasuring = true
                        progressBar.visibility = View.GONE
                        progressBar.isIndeterminate = true
                    }
                    WorkInfo.State.SUCCEEDED -> {
                        if (isMeasuring) {
                            isMeasuring = false
                            lastSyncTime = System.currentTimeMillis()
                            nextSendTime = System.currentTimeMillis() +
                                    INTERVAL_MINUTES * 60 * 1000
                            progressBar.isIndeterminate = false
                            progressBar.visibility = View.VISIBLE
                        }
                    }
                    WorkInfo.State.ENQUEUED -> {
                        isMeasuring = false
                        progressBar.isIndeterminate = false
                        progressBar.visibility = View.VISIBLE
                    }
                    else -> {}
                }
            }
    }

    private fun updateUI() {
        if (isMeasuring) {
            timerText.text = "Mesure en cours..."
            timerText.setTextColor(measuringColor)
            pulseIcon.setTextColor(measuringColor)
            if (lastHeartRate <= 0f) heartRateText.text = "... BPM"
            return
        }

        timerText.setTextColor(primaryColor)
        pulseIcon.setTextColor(primaryColor)

        val remaining = (nextSendTime - System.currentTimeMillis()) / 1000
        val total = INTERVAL_MINUTES * 60

        if (remaining > 0) {
            val minutes = remaining / 60
            val seconds = remaining % 60
            timerText.text = "Prochain: %02d:%02d".format(minutes, seconds)
            progressBar.progress = (total - remaining).toInt().coerceIn(0, total.toInt())
        } else {
            timerText.text = "Mesure en cours..."
        }

        if (lastSyncTime > 0) {
            val diff = (System.currentTimeMillis() - lastSyncTime) / 1000
            val mins = diff / 60
            val secs = diff % 60
            lastSyncText.text = if (mins > 0) {
                "Sync: il y a ${mins}m ${secs}s"
            } else {
                "Sync: il y a ${secs}s"
            }
        } else {
            lastSyncText.text = "En attente de mesure..."
        }
    }

    fun updateHeartRate(heartRate: Float) {
        lastHeartRate = heartRate
        runOnUiThread {
            heartRateText.text = "${heartRate.toInt()} BPM"
        }
    }

    private fun scheduleHeartRateWorker() {
        val workRequest = OneTimeWorkRequestBuilder<HeartRateWorker>()
            .setInitialDelay(INTERVAL_MINUTES, TimeUnit.MINUTES)
            .build()

        WorkManager.getInstance(applicationContext).enqueueUniqueWork(
            WORK_NAME,
            ExistingWorkPolicy.KEEP,
            workRequest
        )
    }
}