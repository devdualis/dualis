package com.dualischeckup.app.dualis_mobile

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Opens this app's notification settings (NotificationsBlockedNotice).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dualis/app_settings")
            .setMethodCallHandler { call, result ->
                if (call.method != "openNotificationSettings") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                } else {
                    Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.fromParts("package", packageName, null),
                    )
                }
                try {
                    startActivity(intent)
                    result.success(null)
                } catch (e: Exception) {
                    // Some phones lack the notification screen: use app details.
                    try {
                        startActivity(
                            Intent(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.fromParts("package", packageName, null),
                            ),
                        )
                        result.success(null)
                    } catch (e2: Exception) {
                        result.error("unavailable", e2.message, null)
                    }
                }
            }
    }
}
