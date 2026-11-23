package com.example.active_tracker

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority

class RunService : Service() {
    companion object {
        const val ACTION_START = "com.example.active_tracker.RUN_START"
        const val EXTRA_RAW = "raw"
        private const val CHANNEL_ID = "run_recording"
        private const val NOTIFICATION_ID = 7301
        private const val INTERVAL_MS = 1000L
        private const val WAKE_LIMIT_MS = 8L * 60 * 60 * 1000

        @Volatile
        var instance: RunService? = null
            private set

        @Volatile
        var sink: ((Map<String, Any?>) -> Unit)? = null
    }

    private var fused: FusedLocationProviderClient? = null
    private var manager: LocationManager? = null
    private var wake: PowerManager.WakeLock? = null
    private var requested = false

    private val fusedCallback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            result.locations.forEach(::emit)
        }
    }

    private val gpsListener = LocationListener { emit(it) }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        fused = LocationServices.getFusedLocationProviderClient(this)
        manager = getSystemService(LOCATION_SERVICE) as LocationManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!goForeground()) {
            stopSelf()
            return START_NOT_STICKY
        }
        instance = this
        holdWakeLock()
        request(intent?.getBooleanExtra(EXTRA_RAW, false) ?: false)
        return START_NOT_STICKY
    }

    fun request(raw: Boolean) {
        removeUpdates()
        try {
            if (raw) {
                manager?.requestLocationUpdates(LocationManager.GPS_PROVIDER, INTERVAL_MS, 0f, gpsListener, Looper.getMainLooper())
            } else {
                val req = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, INTERVAL_MS)
                    .setMinUpdateIntervalMillis(INTERVAL_MS)
                    .setWaitForAccurateLocation(false)
                    .build()
                fused?.requestLocationUpdates(req, fusedCallback, Looper.getMainLooper())
            }
            requested = true
        } catch (_: SecurityException) {
        } catch (_: IllegalArgumentException) {
        }
    }

    fun shutdown() {
        removeUpdates()
        releaseWakeLock()
        instance = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        shutdown()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        removeUpdates()
        releaseWakeLock()
        if (instance === this) instance = null
        super.onDestroy()
    }

    private fun removeUpdates() {
        if (!requested) return
        fused?.removeLocationUpdates(fusedCallback)
        manager?.removeUpdates(gpsListener)
        requested = false
    }

    private fun emit(l: Location) {
        val map = hashMapOf<String, Any?>(
            "lat" to l.latitude,
            "lng" to l.longitude,
            "t" to l.time,
            "acc" to (if (l.hasAccuracy()) l.accuracy.toDouble() else 999.0),
            "speed" to (if (l.hasSpeed()) l.speed.toDouble() else 0.0),
        )
        if (l.hasAltitude()) map["alt"] = l.altitude
        if (l.hasBearing()) map["heading"] = l.bearing.toDouble()
        if (l.hasBearingAccuracy()) map["headingAcc"] = l.bearingAccuracyDegrees.toDouble()
        sink?.invoke(map)
    }

    private fun goForeground(): Boolean {
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        nm.createNotificationChannel(NotificationChannel(CHANNEL_ID, "Run recording", NotificationManager.IMPORTANCE_LOW))
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val notification = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("Recording your run")
            .setContentText("Active Tracker keeps recording while the screen is off.")
            .setSmallIcon(R.drawable.ic_stat_run)
            .setContentIntent(open)
            .setOngoing(true)
            .build()
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun holdWakeLock() {
        if (wake?.isHeld == true) return
        val pm = getSystemService(POWER_SERVICE) as PowerManager
        wake = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "ActiveTracker:run").apply {
            setReferenceCounted(false)
            acquire(WAKE_LIMIT_MS)
        }
    }

    private fun releaseWakeLock() {
        wake?.takeIf { it.isHeld }?.release()
        wake = null
    }
}
