package com.example.active_tracker

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "active_tracker/run_service").setMethodCallHandler { call, result ->
            val raw = call.argument<Boolean>("raw") ?: false
            when (call.method) {
                "start" -> {
                    val running = RunService.instance
                    if (running != null) {
                        running.request(raw)
                        result.success(true)
                    } else {
                        val intent = Intent(this, RunService::class.java)
                            .setAction(RunService.ACTION_START)
                            .putExtra(RunService.EXTRA_RAW, raw)
                        result.success(
                            try {
                                startForegroundService(intent)
                                true
                            } catch (_: Exception) {
                                false
                            },
                        )
                    }
                }
                "listen" -> {
                    val running = RunService.instance
                    running?.request(raw)
                    result.success(running != null)
                }
                "stop" -> {
                    RunService.instance?.shutdown()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        EventChannel(messenger, "active_tracker/run_fixes").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    RunService.sink = { events.success(it) }
                }

                override fun onCancel(arguments: Any?) {
                    RunService.sink = null
                }
            },
        )
    }
}
