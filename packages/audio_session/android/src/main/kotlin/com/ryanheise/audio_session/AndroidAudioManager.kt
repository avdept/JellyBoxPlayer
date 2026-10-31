package com.ryanheise.audio_session

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.media.MicrophoneInfo
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import androidx.media.AudioAttributesCompat
import androidx.media.AudioFocusRequestCompat
import androidx.media.AudioManagerCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.IOException

class AndroidAudioManager(applicationContext: Context, messenger: BinaryMessenger) :
    MethodCallHandler {
    var messenger: BinaryMessenger?
    var channel: MethodChannel?

    init {
        if (singleton == null) singleton = AudioManagerSingleton(applicationContext)
        this.messenger = messenger
        channel = MethodChannel(messenger, "com.ryanheise.android_audio_manager")
        singleton!!.add(this)
        channel!!.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            val args = call.arguments as List<*>
            when (call.method) {
                "requestAudioFocus" -> {
                    result.success(singleton!!.requestAudioFocus(args))
                }

                "abandonAudioFocus" -> {
                    result.success(singleton!!.abandonAudioFocus())
                }

                "dispatchMediaKeyEvent" -> {
                    result.success(
                        singleton!!.dispatchMediaKeyEvent(
                            args[0] as Map<*, *>
                        )
                    )
                }

                "isVolumeFixed" -> {
                    if (Build.VERSION.SDK_INT < 21) throw ApiException(21)
                    result.success(singleton!!.isVolumeFixed)
                }

                "adjustStreamVolume" -> {
                    result.success(
                        singleton!!.adjustStreamVolume(
                            args[0] as Int,
                            args[1] as Int,
                            args[2] as Int
                        )
                    )
                }

                "adjustVolume" -> {
                    result.success(singleton!!.adjustVolume(args[0] as Int, args[1] as Int))
                }

                "adjustSuggestedStreamVolume" -> {
                    result.success(
                        singleton!!.adjustSuggestedStreamVolume(
                            args[0] as Int, args[1] as Int, args[2] as Int
                        )
                    )
                }

                "getRingerMode" -> {
                    result.success(singleton!!.ringerMode)
                }

                "getStreamMaxVolume" -> {
                    result.success(singleton!!.getStreamMaxVolume(args[0] as Int))
                }

                "getStreamMinVolume" -> {
                    if (Build.VERSION.SDK_INT < 28) throw ApiException(28)
                    result.success(singleton!!.getStreamMinVolume(args[0] as Int))
                }

                "getStreamVolume" -> {
                    result.success(singleton!!.getStreamVolume(args[0] as Int))
                }

                "getStreamVolumeDb" -> {
                    if (Build.VERSION.SDK_INT < 28) throw ApiException(28)
                    result.success(
                        singleton!!.getStreamVolumeDb(
                            args[0] as Int,
                            args[1] as Int,
                            args[2] as Int
                        )
                    )
                }

                "setRingerMode" -> {
                    result.success(singleton!!.setRingerMode(args[0] as Int))
                }

                "setStreamVolume" -> {
                    result.success(
                        singleton!!.setStreamVolume(
                            args[0] as Int,
                            args[1] as Int,
                            args[2] as Int
                        )
                    )
                }

                "isStreamMute" -> {
                    if (Build.VERSION.SDK_INT < 23) throw ApiException(23)
                    result.success(singleton!!.isStreamMute(args[0] as Int))
                }

                "getAvailableCommunicationDevices" -> {
                    if (Build.VERSION.SDK_INT < 31) throw ApiException(31)
                    result.success(singleton!!.availableCommunicationDevices)
                }

                "setCommunicationDevice" -> {
                    if (Build.VERSION.SDK_INT < 31) throw ApiException(31)
                    result.success(
                        singleton!!.setCommunicationDevice(
                            args[0] as Int
                        )
                    )
                }

                "getCommunicationDevice" -> {
                    if (Build.VERSION.SDK_INT < 31) throw ApiException(31)
                    result.success(singleton!!.communicationDevice)
                }

                "clearCommunicationDevice" -> {
                    if (Build.VERSION.SDK_INT < 31) throw ApiException(31)
                    result.success(singleton!!.clearCommunicationDevice())
                }

                "setSpeakerphoneOn" -> {
                    result.success(singleton!!.setSpeakerphoneOn(args[0] as Boolean))
                }

                "isSpeakerphoneOn" -> {
                    result.success(singleton!!.isSpeakerphoneOn)
                }

                "setAllowedCapturePolicy" -> {
                    if (Build.VERSION.SDK_INT < 29) throw ApiException(29)
                    result.success(
                        singleton!!.setAllowedCapturePolicy(
                            args[0] as Int
                        )
                    )
                }

                "getAllowedCapturePolicy" -> {
                    if (Build.VERSION.SDK_INT < 29) throw ApiException(29)
                    result.success(singleton!!.allowedCapturePolicy)
                }

                "isBluetoothScoAvailableOffCall" -> {
                    result.success(singleton!!.isBluetoothScoAvailableOffCall)
                }

                "startBluetoothSco" -> {
                    result.success(singleton!!.startBluetoothSco())
                }

                "stopBluetoothSco" -> {
                    result.success(singleton!!.stopBluetoothSco())
                }

                "setBluetoothScoOn" -> {
                    result.success(singleton!!.setBluetoothScoOn(args[0] as Boolean))
                }

                "isBluetoothScoOn" -> {
                    result.success(singleton!!.isBluetoothScoOn)
                }

                "setMicrophoneMute" -> {
                    result.success(singleton!!.setMicrophoneMute(args[0] as Boolean))
                }

                "isMicrophoneMute" -> {
                    result.success(singleton!!.isMicrophoneMute)
                }

                "setMode" -> {
                    result.success(singleton!!.setMode(args[0] as Int))
                }

                "getMode" -> {
                    result.success(singleton!!.mode)
                }

                "isMusicActive" -> {
                    result.success(singleton!!.isMusicActive)
                }

                "generateAudioSessionId" -> {
                    if (Build.VERSION.SDK_INT < 21) throw ApiException(21)
                    result.success(singleton!!.generateAudioSessionId())
                }

                "setParameters" -> {
                    result.success(singleton!!.setParameters(args[0] as String?))
                }

                "getParameters" -> {
                    result.success(singleton!!.getParameters(args[0] as String?))
                }

                "playSoundEffect" -> {
                    result.success(singleton!!.playSoundEffect(args[0] as Int, args[1] as Double?))
                }

                "loadSoundEffects" -> {
                    result.success(singleton!!.loadSoundEffects())
                }

                "unloadSoundEffects" -> {
                    result.success(singleton!!.unloadSoundEffects())
                }

                "getProperty" -> {
                    result.success(singleton!!.getProperty(args[0] as String?))
                }

                "getDevices" -> {
                    if (Build.VERSION.SDK_INT < 23) throw ApiException(23)
                    result.success(singleton!!.getDevices(args[0] as Int))
                }

                "getMicrophones" -> {
                    if (Build.VERSION.SDK_INT < 28) throw ApiException(28)
                    result.success(singleton!!.microphones)
                }

                "isHapticPlaybackSupported" -> {
                    if (Build.VERSION.SDK_INT < 29) throw ApiException(29)
                    result.success(singleton!!.isHapticPlaybackSupported)
                }

                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
            result.error("Error: $e", null, null)
        }
    }

    fun dispose() {
        channel!!.setMethodCallHandler(null)
        singleton!!.remove(this)
        if (singleton!!.isEmpty) {
            singleton!!.dispose()
            singleton = null
        }
        channel = null
        messenger = null
    }

    companion object {
        // TODO: synchronize access
        private var singleton: AudioManagerSingleton? = null
    }
}

class ApiException(requiredLevel: Int) : RuntimeException("Requires API level $requiredLevel")

/**
 * To emulate iOS's AVAudioSession, we maintain a single app-wide audio
 * focus request and noisy receiver at any one time which all isolates
 * share access to.
 */
private class AudioManagerSingleton(applicationContext: Context) {
    private val handler: Handler = Handler(Looper.getMainLooper())
    private val instances: MutableList<AndroidAudioManager> = ArrayList()
    private var audioFocusRequest: AudioFocusRequestCompat? = null
    private var noisyReceiver: BroadcastReceiver? = null
    private var scoReceiver: BroadcastReceiver? = null
    private var applicationContext: Context?
    private var audioManager: AudioManager?
    private var audioDeviceCallback: Any? = null
    private var devices: List<AudioDeviceInfo> = ArrayList()

    init {
        this.applicationContext = applicationContext
        audioManager =
            applicationContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= 23) {
            initAudioDeviceCallback()
        }
    }

    @RequiresApi(23)
    fun initAudioDeviceCallback() {
        audioDeviceCallback = object : AudioDeviceCallback() {
            override fun onAudioDevicesAdded(addedDevices: Array<AudioDeviceInfo>) {
                invokeMethod("onAudioDevicesAdded", encodeAudioDevices(addedDevices))
            }

            override fun onAudioDevicesRemoved(removedDevices: Array<AudioDeviceInfo>) {
                invokeMethod("onAudioDevicesRemoved", encodeAudioDevices(removedDevices))
            }
        }
        audioManager!!.registerAudioDeviceCallback(
            audioDeviceCallback as AudioDeviceCallback,
            handler
        )
    }

    fun add(manager: AndroidAudioManager) {
        instances.add(manager)
    }

    fun remove(manager: AndroidAudioManager) {
        instances.remove(manager)
    }

    val isEmpty: Boolean
        get() = instances.size == 0

    fun requestAudioFocus(args: List<*>): Boolean {
        if (audioFocusRequest != null) {
            return true
        }
        val request = args[0] as Map<*, *>
        val builder: AudioFocusRequestCompat.Builder =
            AudioFocusRequestCompat.Builder(request["gainType"] as Int)
        builder.setOnAudioFocusChangeListener { focusChange: Int ->
            if (focusChange == AudioManager.AUDIOFOCUS_LOSS) abandonAudioFocus()
            invokeMethod("onAudioFocusChanged", focusChange)
        }
        if (request["audioAttributes"] != null) {
            builder.setAudioAttributes(decodeAudioAttributes((request["audioAttributes"] as Map<*, *>?)!!))
        }
        if (request["willPauseWhenDucked"] != null) {
            builder.setWillPauseWhenDucked(request["willPauseWhenDucked"] as Boolean)
        }
        val focusRequest = builder.build()
        val status: Int =
            AudioManagerCompat.requestAudioFocus(audioManager!!, focusRequest)
        val success = status == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        if (success) {
            // LOCAL PATCH (JellyBox): remember the request only once Android has
            // granted it. Upstream stored it before asking, so a refused request
            // (for example during a phone call) made every later call return
            // true without asking Android again. Android Auto only opens the
            // car's media channel on a real focus grant, so the app then played
            // into nothing.
            audioFocusRequest = focusRequest
            registerNoisyReceiver()
            registerScoReceiver()
        }
        return success
    }

    fun abandonAudioFocus(): Boolean {
        if (applicationContext == null) return false
        unregisterNoisyReceiver()
        unregisterScoReceiver()
        if (audioFocusRequest == null) {
            return true
        } else {
            val status: Int =
                AudioManagerCompat.abandonAudioFocusRequest(audioManager!!, audioFocusRequest!!)
            audioFocusRequest = null
            return status == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
    }

    fun dispatchMediaKeyEvent(rawKeyEvent: Map<*, *>): Any? {
        val keyEvent = KeyEvent(
            getLong(rawKeyEvent["downTime"])!!,
            getLong(rawKeyEvent["eventTime"])!!,
            rawKeyEvent["action"] as Int,
            rawKeyEvent["keyCode"] as Int,
            rawKeyEvent["repeatCount"] as Int,
            rawKeyEvent["metaState"] as Int,
            rawKeyEvent["deviceId"] as Int,
            rawKeyEvent["scanCode"] as Int,
            rawKeyEvent["flags"] as Int,
            rawKeyEvent["source"] as Int
        )
        audioManager!!.dispatchMediaKeyEvent(keyEvent)
        return null
    }

    @get:RequiresApi(21)
    val isVolumeFixed: Any
        get() {
            return audioManager!!.isVolumeFixed()
        }

    fun adjustStreamVolume(streamType: Int, direction: Int, flags: Int): Any? {
        audioManager!!.adjustStreamVolume(streamType, direction, flags)
        return null
    }

    fun adjustVolume(direction: Int, flags: Int): Any? {
        audioManager!!.adjustVolume(direction, flags)
        return null
    }

    fun adjustSuggestedStreamVolume(
        direction: Int,
        suggestedStreamType: Int,
        flags: Int
    ): Any? {
        audioManager!!.adjustSuggestedStreamVolume(direction, suggestedStreamType, flags)
        return null
    }

    val ringerMode: Any
        get() = audioManager!!.getRingerMode()

    fun getStreamMaxVolume(streamType: Int): Any {
        return audioManager!!.getStreamMaxVolume(streamType)
    }

    @RequiresApi(28)
    fun getStreamMinVolume(streamType: Int): Any {
        return audioManager!!.getStreamMinVolume(streamType)
    }

    fun getStreamVolume(streamType: Int): Any {
        return audioManager!!.getStreamVolume(streamType)
    }

    @RequiresApi(28)
    fun getStreamVolumeDb(streamType: Int, index: Int, deviceType: Int): Any {
        return audioManager!!.getStreamVolumeDb(streamType, index, deviceType)
    }

    fun setRingerMode(ringerMode: Int): Any? {
        audioManager!!.setRingerMode(ringerMode)
        return null
    }

    fun setStreamVolume(streamType: Int, index: Int, flags: Int): Any? {
        audioManager!!.setStreamVolume(streamType, index, flags)
        return null
    }

    @RequiresApi(23)
    fun isStreamMute(streamType: Int): Any {
        return audioManager!!.isStreamMute(streamType)
    }

    @get:RequiresApi(31)
    val availableCommunicationDevices: List<Map<String, Any?>>
        get() = audioManager!!.availableCommunicationDevices.map { encodeAudioDevice(it) }

    @RequiresApi(31)
    fun setCommunicationDevice(deviceId: Int): Boolean {
        for (device in devices) {
            if (device.id == deviceId) {
                return audioManager!!.setCommunicationDevice(device)
            }
        }
        return false
    }

    @get:RequiresApi(31)
    val communicationDevice: Map<String, Any?>?
        get() {
            val device = audioManager!!.communicationDevice
            return if (device == null) null else encodeAudioDevice(device)
        }

    @RequiresApi(31)
    fun clearCommunicationDevice(): Any? {
        audioManager!!.clearCommunicationDevice()
        return null
    }

    @Suppress("deprecation")
    fun setSpeakerphoneOn(enabled: Boolean): Any? {
        audioManager!!.setSpeakerphoneOn(enabled)
        return null
    }

    @get:Suppress("deprecation")
    val isSpeakerphoneOn: Any
        get() = audioManager!!.isSpeakerphoneOn()

    @RequiresApi(29)
    fun setAllowedCapturePolicy(capturePolicy: Int): Any? {
        audioManager!!.setAllowedCapturePolicy(capturePolicy)
        return null
    }

    @get:RequiresApi(29)
    val allowedCapturePolicy: Any
        get() {
            return audioManager!!.getAllowedCapturePolicy()
        }

    val isBluetoothScoAvailableOffCall: Any
        get() = audioManager!!.isBluetoothScoAvailableOffCall

    @Suppress("deprecation")
    fun startBluetoothSco(): Any? {
        audioManager!!.startBluetoothSco()
        return null
    }

    @Suppress("deprecation")
    fun stopBluetoothSco(): Any? {
        audioManager!!.stopBluetoothSco()
        return null
    }

    fun setBluetoothScoOn(enabled: Boolean): Any? {
        audioManager!!.setBluetoothScoOn(enabled)
        return null
    }

    @get:Suppress("deprecation")
    val isBluetoothScoOn: Any
        get() = audioManager!!.isBluetoothScoOn()

    fun setMicrophoneMute(enabled: Boolean): Any? {
        audioManager!!.setMicrophoneMute(enabled)
        return null
    }

    val isMicrophoneMute: Any
        get() = audioManager!!.isMicrophoneMute()

    fun setMode(mode: Int): Any? {
        audioManager!!.setMode(mode)
        return null
    }

    val mode: Any
        get() = audioManager!!.getMode()
    val isMusicActive: Any
        get() = audioManager!!.isMusicActive()

    @RequiresApi(21)
    fun generateAudioSessionId(): Any {
        return audioManager!!.generateAudioSessionId()
    }

    fun setParameters(parameters: String?): Any? {
        audioManager!!.setParameters(parameters)
        return null
    }

    fun getParameters(keys: String?): Any {
        return audioManager!!.getParameters(keys)
    }

    fun playSoundEffect(effectType: Int, volume: Double?): Any? {
        if (volume != null) {
            audioManager!!.playSoundEffect(effectType, volume.toFloat())
        } else {
            audioManager!!.playSoundEffect(effectType)
        }
        return null
    }

    fun loadSoundEffects(): Any? {
        audioManager!!.loadSoundEffects()
        return null
    }

    fun unloadSoundEffects(): Any? {
        audioManager!!.unloadSoundEffects()
        return null
    }

    fun getProperty(arg: String?): Any {
        return audioManager!!.getProperty(arg)
    }

    @RequiresApi(23)
    fun getDevices(flags: Int): Any {
        val result = mutableListOf<Map<String, Any?>>();
        val devices: Array<AudioDeviceInfo> = audioManager!!.getDevices(flags)
        for (i in devices.indices) {
            result.add(encodeAudioDevice(devices[i]))
        }
        return result
    }

    @get:Throws(IOException::class)
    @get:RequiresApi(28)
    val microphones: Any
        get() {
            val result = mutableListOf<Map<String, Any?>>();
            val microphones: List<MicrophoneInfo> =
                audioManager!!.getMicrophones()
            for (microphone in microphones) {
                val frequencyResponse = microphone.frequencyResponse.map {
                    listOf(
                        it.first.toDouble(),
                        it.second.toDouble()
                    )
                }
                val channelMapping = microphone.channelMapping.map {
                    listOf(
                        it.first.toInt(),
                        it.second.toInt()
                    )
                }
                result.add(
                    mapOf(
                        "description" to microphone.description,
                        "id" to microphone.id,
                        "type" to microphone.type,
                        "address" to microphone.address,
                        "location" to microphone.location,
                        "group" to microphone.group,
                        "indexInTheGroup" to microphone.indexInTheGroup,
                        "position" to coordinate3fToList(microphone.position),
                        "orientation" to coordinate3fToList(microphone.orientation),
                        "frequencyResponse" to frequencyResponse,
                        "channelMapping" to channelMapping,
                        "sensitivity" to microphone.sensitivity,
                        "maxSpl" to microphone.maxSpl,
                        "minSpl" to microphone.minSpl,
                        "directionality" to microphone.directionality
                    )
                )
            }
            return result
        }

    @get:RequiresApi(29)
    val isHapticPlaybackSupported: Any
        get() {
            return AudioManager.isHapticPlaybackSupported()
        }

    fun registerNoisyReceiver() {
        if (noisyReceiver != null) return
        noisyReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (AudioManager.ACTION_AUDIO_BECOMING_NOISY == intent.action) {
                    invokeMethod("onBecomingNoisy")
                }
            }
        }
        ContextCompat.registerReceiver(
            applicationContext!!,
            noisyReceiver,
            IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY),
            ContextCompat.RECEIVER_EXPORTED
        )
    }

    fun unregisterNoisyReceiver() {
        if (noisyReceiver == null || applicationContext == null) return
        applicationContext!!.unregisterReceiver(noisyReceiver)
        noisyReceiver = null
    }

    fun registerScoReceiver() {
        if (scoReceiver != null) return
        scoReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                // emit [onScoAudioStateUpdated] with current state [EXTRA_SCO_AUDIO_STATE] and previous state [EXTRA_SCO_AUDIO_PREVIOUS_STATE]
                invokeMethod(
                    "onScoAudioStateUpdated",
                    intent.getIntExtra(AudioManager.EXTRA_SCO_AUDIO_STATE, -1),
                    intent.getIntExtra(AudioManager.EXTRA_SCO_AUDIO_PREVIOUS_STATE, -1)
                )
            }
        }
        ContextCompat.registerReceiver(
            applicationContext!!,
            scoReceiver,
            IntentFilter(AudioManager.ACTION_SCO_AUDIO_STATE_UPDATED),
            ContextCompat.RECEIVER_EXPORTED
        )
    }

    fun unregisterScoReceiver() {
        if (scoReceiver == null || applicationContext == null) return
        applicationContext!!.unregisterReceiver(scoReceiver)
        scoReceiver = null
    }

    fun decodeAudioAttributes(attributes: Map<*, *>): AudioAttributesCompat {
        val builder: AudioAttributesCompat.Builder = AudioAttributesCompat.Builder()
        if (attributes["contentType"] != null) {
            builder.setContentType(attributes["contentType"] as Int)
        }
        if (attributes["flags"] != null) {
            builder.setFlags(attributes["flags"] as Int)
        }
        if (attributes["usage"] != null) {
            builder.setUsage(attributes["usage"] as Int)
        }
        return builder.build()
    }

    fun invokeMethod(method: String, vararg args: Any?) {
        for (instance in instances) {
            val list = args.toMutableList()
            instance.channel!!.invokeMethod(method, list)
        }
    }

    fun dispose() {
        abandonAudioFocus()
        if (Build.VERSION.SDK_INT >= 23) {
            disposeAudioDeviceCallback()
        }
        applicationContext = null
        audioManager = null
    }

    @RequiresApi(23)
    fun disposeAudioDeviceCallback() {
        audioManager!!.unregisterAudioDeviceCallback(audioDeviceCallback as AudioDeviceCallback?)
    }

    companion object {
        fun intArrayToList(a: IntArray): ArrayList<Int> {
            return ArrayList(a.toList())
        }

        @RequiresApi(28)
        fun coordinate3fToList(coordinate: MicrophoneInfo.Coordinate3F): ArrayList<Double> {
            return arrayListOf(
                coordinate.x.toDouble(),
                coordinate.y.toDouble(),
                coordinate.z.toDouble()
            )
        }

        fun getLong(o: Any?): Long? {
            return (o as? Long) ?: (o as? Int)?.toLong()
        }

        @RequiresApi(23)
        fun encodeAudioDevices(devices: Array<AudioDeviceInfo>): List<Map<String, Any?>> {
            return devices.map { encodeAudioDevice(it) }
        }

        @RequiresApi(23)
        fun encodeAudioDevice(device: AudioDeviceInfo): Map<String, Any?> {
            var address: String? = null
            if (Build.VERSION.SDK_INT >= 28) {
                address = device.address
            }
            return mapOf(
                "id" to device.id,
                "productName" to device.getProductName(),
                "address" to address,
                "isSource" to device.isSource,
                "isSink" to device.isSink,
                "sampleRates" to intArrayToList(device.sampleRates),
                "channelMasks" to intArrayToList(device.channelMasks),
                "channelIndexMasks" to intArrayToList(device.channelIndexMasks),
                "channelCounts" to intArrayToList(device.getChannelCounts()),
                "encodings" to intArrayToList(device.encodings),
                "type" to device.type
            )
        }
    }
}
