package com.example.sahhty

import android.content.Intent
import android.util.Log
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.WearableListenerService

class DataLayerService : WearableListenerService() {

    companion object {
        private const val TAG = "DataLayerService"
        private const val DATA_PATH = "/sahhty/heart_rate"
        const val ACTION_UPDATE_HR = "com.example.sahhty.UPDATE_HEART_RATE"
        const val EXTRA_HEART_RATE = "heart_rate"
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        dataEvents.forEach { event ->
            if (event.type == DataEvent.TYPE_CHANGED &&
                event.dataItem.uri.path == DATA_PATH
            ) {
                val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap
                val heartRate = dataMap.getFloat("heart_rate")
                val timestamp = dataMap.getLong("timestamp")

                Log.d(TAG, "Received heart rate: $heartRate BPM at $timestamp")

                val intent = Intent(ACTION_UPDATE_HR).apply {
                    setPackage(packageName)
                    putExtra(EXTRA_HEART_RATE, heartRate)
                }
                sendBroadcast(intent)
            }
        }
    }
}