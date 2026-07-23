package com.example.native_route_picker

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.util.Log
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

  // Candidate actions for the system output switcher. It's a semi-public
  // Settings panel whose action string varies by OEM/version, so we try the
  // known variants in order and launch the first that succeeds.
  private val outputSwitcherActions = listOf(
    "com.android.settings.panel.action.MEDIA_OUTPUT",
    "android.settings.panel.action.MEDIA_OUTPUT",
  )

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
    // Don't gate on resolveActivity() — Android 11+ package visibility can
    // hide the Settings activity from queries even when it's launchable.
    // Just attempt each candidate and take the first that starts.
    for (action in outputSwitcherActions) {
      val intent = Intent(action).apply {
        // Different builds read different keys; set both.
        putExtra("com.android.settings.panel.extra.PACKAGE_NAME", ctx.packageName)
        putExtra("android.provider.extra.APP_PACKAGE", ctx.packageName)
        if (activity == null) addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      }
      try {
        ctx.startActivity(intent)
        return true
      } catch (e: Exception) {
        Log.w("NativeRoutePicker", "Output switcher action failed: $action", e)
      }
    }
    return false
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
