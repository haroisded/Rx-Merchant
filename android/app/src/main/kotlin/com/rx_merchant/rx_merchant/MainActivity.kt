package com.rx_merchant.rx_merchant

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Opens an Android settings screen for the receipt printer section
    // (05-invoices-and-receipts section 5, States): "bluetooth" or "app".
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "rx_merchant/settings")
            .setMethodCallHandler { call, result ->
                val intent = when (call.method) {
                    "bluetooth" -> Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
                    "app" -> Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.fromParts("package", packageName, null),
                    )
                    else -> null
                }
                if (intent == null) {
                    result.notImplemented()
                } else {
                    startActivity(intent)
                    result.success(null)
                }
            }
    }
}
