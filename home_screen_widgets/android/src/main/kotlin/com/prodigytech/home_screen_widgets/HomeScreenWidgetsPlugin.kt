package com.prodigytech.home_screen_widgets

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

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

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  companion object {
    fun directory(context: Context): File = File(context.filesDir, "home_screen_widgets")
  }
}
