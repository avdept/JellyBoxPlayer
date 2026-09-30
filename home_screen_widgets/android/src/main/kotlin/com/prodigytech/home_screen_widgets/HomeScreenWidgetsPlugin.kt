package com.prodigytech.home_screen_widgets

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import kotlin.math.max
import kotlin.math.roundToInt

class HomeScreenWidgetsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "home_screen_widgets")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "directory" -> result.success(directory(context).path)
      "reload" -> {
        call.argument<String>("androidProvider")?.let(::reload)
        result.success(null)
      }
      "artwork" -> {
        val source = call.argument<String>("source")
        val target = call.argument<String>("target")
        val size = call.argument<Int>("size")
        if (source == null || target == null || size == null) {
          result.success(null)
          return
        }
        Thread {
          val pixels = runCatching { artwork(source, target, size) }.getOrNull()
          Handler(Looper.getMainLooper()).post { result.success(pixels) }
        }.start()
      }
      else -> result.notImplemented()
    }
  }

  private fun reload(providerClass: String) {
    val component = ComponentName(context.packageName, providerClass)
    val ids = AppWidgetManager.getInstance(context).getAppWidgetIds(component)
    if (ids.isEmpty()) return
    context.sendBroadcast(
      Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
        .setComponent(component)
        .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids),
    )
  }

  private fun artwork(source: String, target: String, size: Int): IntArray? {
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeFile(source, bounds)
    if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
    var sample = 1
    while (max(bounds.outWidth, bounds.outHeight) / (sample * 2) >= size) sample *= 2
    val decoded = BitmapFactory.decodeFile(source, BitmapFactory.Options().apply { inSampleSize = sample })
      ?: return null
    val scaled = fit(decoded, size)
    FileOutputStream(target).use { scaled.compress(Bitmap.CompressFormat.PNG, 100, it) }
    val sampled = fit(scaled, COLOR_SAMPLE_SIZE)
    val pixels = IntArray(sampled.width * sampled.height)
    sampled.getPixels(pixels, 0, sampled.width, 0, 0, sampled.width, sampled.height)
    return pixels
  }

  private fun fit(bitmap: Bitmap, size: Int): Bitmap {
    val longest = max(bitmap.width, bitmap.height)
    if (longest <= size) return bitmap
    val scale = size.toFloat() / longest
    return Bitmap.createScaledBitmap(
      bitmap,
      max(1, (bitmap.width * scale).roundToInt()),
      max(1, (bitmap.height * scale).roundToInt()),
      true,
    )
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  companion object {
    private const val COLOR_SAMPLE_SIZE = 112

    fun directory(context: Context): File = File(context.filesDir, "home_screen_widgets")
  }
}
