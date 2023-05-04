package com.moducbt

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.webview_intents"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "launchIntent") {
                val url = call.arguments as String
                val intent = Intent.parseUri(url, Intent.URI_INTENT_SCHEME)
                try {
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("UNABLE_TO_LAUNCH_INTENT", "Could not launch intent", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}