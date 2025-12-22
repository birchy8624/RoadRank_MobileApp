package com.roadrank.app.data

import android.content.Context
import java.util.UUID

object DeviceIdManager {
    private const val prefsName = "roadrank_prefs"
    private const val keyDeviceId = "roadrank_device_id"
    private var cachedId: String? = null

    fun init(context: Context) {
        if (cachedId != null) return
        val prefs = context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
        val existing = prefs.getString(keyDeviceId, null)
        val deviceId = existing ?: UUID.randomUUID().toString().also {
            prefs.edit().putString(keyDeviceId, it).apply()
        }
        cachedId = deviceId
    }

    val deviceId: String
        get() = cachedId ?: "unknown"
}
