package com.example.sahhty

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.util.Log
import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.Node
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import kotlinx.coroutines.tasks.await

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val WEAR_CHANNEL = "com.example.sahhty/wear"
        private const val WEARABLE_CHANNEL = "com.sahhty/wearable"
        private const val CAPABILITY_NAME = "sahhty_wear_app"
    }

    private var wearMethodChannel: MethodChannel? = null
    private var wearableMethodChannel: MethodChannel? = null
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    private val heartRateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == PhoneWearListenerService.ACTION_HEART_RATE) {
                val hr = intent.getFloatExtra(PhoneWearListenerService.EXTRA_HEART_RATE, 0f)
                val ts = intent.getLongExtra(PhoneWearListenerService.EXTRA_TIMESTAMP, 0L)
                val ctx = intent.getStringExtra(PhoneWearListenerService.EXTRA_CONTEXT) ?: "smartwatch data"

                val data = mapOf(
                    "heart_rate" to hr.toDouble(),
                    "timestamp" to ts,
                    "context" to ctx
                )
                wearMethodChannel?.invokeMethod("onHeartRateFromWatch", data)
            }
        }
    }

    private val riskAlertReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == PhoneWearListenerService.ACTION_RISK_ALERT) {
                val riskLevel = intent.getStringExtra(PhoneWearListenerService.EXTRA_RISK_LEVEL)
                val note = intent.getStringExtra(PhoneWearListenerService.EXTRA_RISK_NOTE)
                val heartRate = intent.getFloatExtra(PhoneWearListenerService.EXTRA_HEART_RATE, 0f)

                val data = mapOf(
                    "risk_level" to riskLevel,
                    "note" to note,
                    "heart_rate" to heartRate.toDouble()
                )
                wearMethodChannel?.invokeMethod("onRiskAlert", data)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        wearMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WEAR_CHANNEL).also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "setCredentials" -> {
                        val args = call.arguments as Map<*, *>
                        val token = args["token"] as? String
                        val patientId = args["patient_id"] as? String
                        if (token != null && patientId != null) {
                            getSharedPreferences("sahhty_prefs", Context.MODE_PRIVATE)
                                .edit()
                                .putString("token", token)
                                .putString("patient_id", patientId)
                                .apply()
                            Log.d(TAG, "Credentials saved for background service")
                            result.success(true)
                        } else {
                            result.error("INVALID", "Token or patient_id is null", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }

        wearableMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WEARABLE_CHANNEL).also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkWatchAppInstalled" -> handleCheckWatchApp(result)
                    "openPlayStoreOnWatch" -> handleOpenPlayStore(result)
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val heartFilter = IntentFilter(PhoneWearListenerService.ACTION_HEART_RATE)
        val riskFilter = IntentFilter(PhoneWearListenerService.ACTION_RISK_ALERT)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(heartRateReceiver, heartFilter, RECEIVER_NOT_EXPORTED)
            registerReceiver(riskAlertReceiver, riskFilter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(heartRateReceiver, heartFilter)
            registerReceiver(riskAlertReceiver, riskFilter)
        }
    }

    override fun onDestroy() {
        unregisterReceiver(heartRateReceiver)
        unregisterReceiver(riskAlertReceiver)
        scope.cancel()
        super.onDestroy()
    }

    private fun handleCheckWatchApp(result: MethodChannel.Result) {
        scope.launch {
            try {
                val nodeClient = Wearable.getNodeClient(this@MainActivity)
                val connectedNodes: List<Node> = nodeClient.connectedNodes.await()

                if (connectedNodes.isEmpty()) {
                    result.success(mapOf(
                        "status" to "no_watch",
                        "message" to "Aucune montre connectée détectée."
                    ))
                    return@launch
                }

                val capabilityClient = Wearable.getCapabilityClient(this@MainActivity)
                val capabilityInfo = capabilityClient.getCapability(
                    CAPABILITY_NAME,
                    CapabilityClient.FILTER_REACHABLE
                ).await()

                val capableNodes = capabilityInfo.nodes
                if (capableNodes.isNotEmpty()) {
                    result.success(mapOf(
                        "status" to "installed",
                        "message" to "L'application montre est installée.",
                        "nodeCount" to capableNodes.size
                    ))
                } else {
                    result.success(mapOf(
                        "status" to "not_installed",
                        "message" to "Montre détectée mais l'application n'est pas installée.",
                        "watchNodeId" to connectedNodes.first().id
                    ))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error checking watch app", e)
                result.success(mapOf(
                    "status" to "error",
                    "message" to "Erreur lors de la détection: ${e.localizedMessage}"
                ))
            }
        }
    }

    private fun handleOpenPlayStore(result: MethodChannel.Result) {
        scope.launch {
            try {
                val nodeClient = Wearable.getNodeClient(this@MainActivity)
                val connectedNodes = nodeClient.connectedNodes.await()

                if (connectedNodes.isEmpty()) {
                    result.error("NO_WATCH", "Aucune montre connectée.", null)
                    return@launch
                }

                val playStoreUri = "market://details?id=com.example.sahhty"
                val messageClient = Wearable.getMessageClient(this@MainActivity)

                var sent = false
                for (node in connectedNodes) {
                    try {
                        messageClient.sendMessage(
                            node.id,
                            "/open_play_store",
                            playStoreUri.toByteArray()
                        ).await()
                        sent = true
                        Log.d(TAG, "Play Store open request sent to node ${node.id}")
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to send to node ${node.id}", e)
                    }
                }

                if (sent) {
                    result.success(mapOf(
                        "status" to "sent",
                        "message" to "Demande d'installation envoyée à la montre."
                    ))
                } else {
                    result.error("SEND_FAILED", "Impossible d'envoyer à la montre.", null)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error opening Play Store on watch", e)
                result.error("ERROR", e.localizedMessage, null)
            }
        }
    }
}