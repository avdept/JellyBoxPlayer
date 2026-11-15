package com.prodigytech.jellybox

import android.app.UiModeManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : AudioServiceActivity() {
    companion object {
        private const val PLATFORM_CHANNEL = "jellybox/platform"
    }

    private val channelWorker = Executors.newSingleThreadExecutor()
    private var platformChannel: MethodChannel? = null
    private var pendingAlbumId: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingAlbumId = TvHomeChannel.albumIdFrom(intent?.data)
        platformChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PLATFORM_CHANNEL)
            .apply {
                setMethodCallHandler { call, result ->
                    when (call.method) {
                        "isTelevision" -> result.success(isTelevision())
                        "deviceInfo" -> result.success(
                            mapOf(
                                "release" to Build.VERSION.RELEASE,
                                "model" to Build.MODEL,
                            ),
                        )
                        "takePendingAlbum" -> {
                            result.success(pendingAlbumId)
                            pendingAlbumId = null
                        }
                        "publishHomeChannel" -> {
                            val title = call.argument<String>("title") ?: ""
                            val albums = call.argument<List<Map<*, *>>>("albums") ?: emptyList()
                            channelWorker.execute {
                                TvHomeChannel.publish(applicationContext, title, albums)
                            }
                            result.success(null)
                        }
                        "clearHomeChannel" -> {
                            channelWorker.execute { TvHomeChannel.clear(applicationContext) }
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val albumId = TvHomeChannel.albumIdFrom(intent.data) ?: return
        val channel = platformChannel
        if (channel == null) {
            pendingAlbumId = albumId
        } else {
            channel.invokeMethod("openAlbum", albumId)
        }
    }

    private fun isTelevision(): Boolean {
        val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager
        if (uiModeManager?.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION) return true
        val pm = packageManager
        return pm.hasSystemFeature(PackageManager.FEATURE_LEANBACK) ||
            pm.hasSystemFeature(PackageManager.FEATURE_TELEVISION)
    }
}
