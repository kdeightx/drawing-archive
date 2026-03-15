package com.drawarchive.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Environment

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.drawarchive.app/storage")
            .setMethodCallHandler { call, result ->
                if (call.method == "getExternalStorageRoot") {
                    val path = Environment.getExternalStorageDirectory()?.absolutePath
                    if (path != null) {
                        result.success(path)
                    } else {
                        result.error("UNAVAILABLE", "External storage not available", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
