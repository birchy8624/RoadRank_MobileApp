package com.roadrank.app.services

import android.content.Context
import android.content.SharedPreferences
import java.util.UUID

/**
 * Device Manager for unique device identification - matching iOS
 */
object DeviceManager {
    private const val PREFS_NAME = "roadrank_prefs"
    private const val DEVICE_ID_KEY = "roadrank_device_id"

    private var _deviceId: String? = null

    fun init(context: Context) {
        if (_deviceId == null) {
            val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            var id = prefs.getString(DEVICE_ID_KEY, null)
            if (id == null) {
                id = UUID.randomUUID().toString()
                prefs.edit().putString(DEVICE_ID_KEY, id).apply()
            }
            _deviceId = id
        }
    }

    val deviceId: String
        get() = _deviceId ?: throw IllegalStateException("DeviceManager not initialized. Call init(context) first.")
}
