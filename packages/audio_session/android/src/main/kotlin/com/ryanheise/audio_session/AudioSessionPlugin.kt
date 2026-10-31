package com.ryanheise.audio_session

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** AudioSessionPlugin  */
class AudioSessionPlugin : FlutterPlugin, MethodCallHandler {
    private var channel: MethodChannel? = null
    private var androidAudioManager: AndroidAudioManager? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPluginBinding) {
        val messenger: BinaryMessenger = flutterPluginBinding.getBinaryMessenger()
        channel = MethodChannel(messenger, "com.ryanheise.audio_session")
        channel!!.setMethodCallHandler(this)
        androidAudioManager =
            AndroidAudioManager(flutterPluginBinding.getApplicationContext(), messenger)
        instances.add(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        channel!!.setMethodCallHandler(null)
        channel = null
        androidAudioManager!!.dispose()
        androidAudioManager = null
        instances.remove(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val args = call.arguments as List<*>
        when (call.method) {
            "setConfiguration" -> {
                configuration = args[0] as Map<*, *>?
                result.success(null)
                invokeMethod("onConfigurationChanged", configuration!!)
            }

            "getConfiguration" -> {
                result.success(configuration)
            }

            else -> result.notImplemented()
        }
    }

    private fun invokeMethod(method: String, vararg args: Any) {
        for (instance in instances) {
            val list = args.toMutableList()
            instance.channel!!.invokeMethod(method, list)
        }
    }

    companion object {
        private var configuration: Map<*, *>? = null
        private val instances: MutableList<AudioSessionPlugin> = ArrayList()
    }
}
