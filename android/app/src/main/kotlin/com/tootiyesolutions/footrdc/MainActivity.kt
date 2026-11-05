package com.tootiyesolutions.footrdc

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannels()
        // Native ads in lists use FootRDC's own layout (see FootrdcNativeAdFactory).
        GoogleMobileAdsPlugin.registerNativeAdFactory(flutterEngine, NATIVE_AD_FACTORY, FootrdcNativeAdFactory(layoutInflater))
        // Plus › Notifications: open this app's notification settings (permission, sound, per channel).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "footrdc/notification_settings").setMethodCallHandler { call, result ->
            if (call.method == "open") {
                val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                } else {
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).setData(android.net.Uri.fromParts("package", packageName, null))
                }
                startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, NATIVE_AD_FACTORY)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    companion object {
        /** Must match `androidNativeAdFactoryId` in lib/shared/widgets/ads.dart. */
        const val NATIVE_AD_FACTORY = "footrdcNative"
    }

    /** One channel per kind of message, so users can tune sound and importance for each in the system settings. */
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        manager.createNotificationChannel(
            NotificationChannel("actualites", "Actualités — À la Une", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Les articles publiés dans « À la Une »"
            },
        )
        manager.createNotificationChannel(
            NotificationChannel("matchs", "Matchs Linafoot", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Alertes des clubs que vous suivez"
            },
        )
    }
}
