package com.example.native_route_picker

import android.app.Activity
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class NativeRoutePickerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel: MethodChannel
  private var activity: Activity? = null
  private var appContext: Context? = null

  private val mediaOutputAction = "com.android.settings.panel.action.MEDIA_OUTPUT"
  private val extraPackageName = "com.android.settings.panel.extra.PACKAGE_NAME"

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    appContext = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "native_route_picker")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "showOutputSwitcher" -> result.success(showOutputSwitcher())
      else -> result.notImplemented()
    }
  }

  private fun showOutputSwitcher(): Boolean {
    val ctx: Context = activity ?: appContext ?: return false
    val intent = Intent(mediaOutputAction).apply {
      putExtra(extraPackageName, ctx.packageName)
      if (activity == null) addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }
    return try {
      ctx.startActivity(intent)
      true
    } catch (e: Exception) {
      false
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    appContext = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}
