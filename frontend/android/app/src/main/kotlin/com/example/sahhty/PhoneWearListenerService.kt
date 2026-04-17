package com.example.sahhty

import android.content.Intent
import android.util.Log
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.WearableListenerService

class PhoneWearListenerService : WearableListenerService() {

    companion object {
        private const val TAG = "PhoneWearListener"
        private const val HEART_RATE_PATH = "/sahhty/heart_rate"
        const val ACTION_HEART_RATE = "com.example.sahhty.HEART_RATE_FROM_WATCH"
        const val EXTRA_HEART_RATE = "heart_rate"
        const val EXTRA_TIMESTAMP = "timestamp"
        const val EXTRA_CONTEXT = "context"
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
                val context = dataMap.getString("context", "smartwatch data")

                Log.d(TAG, "Received HR from watch: $heartRate BPM at $timestamp")

                // Broadcast to MainActivity which will forward to Flutter
                val intent = Intent(ACTION_HEART_RATE).apply {
                    setPackage(packageName)
                    putExtra(EXTRA_HEART_RATE, heartRate)
                    putExtra(EXTRA_TIMESTAMP, timestamp)
                    putExtra(EXTRA_CONTEXT, context)
                }
                sendBroadcast(intent)
            }
        }
    }
}
