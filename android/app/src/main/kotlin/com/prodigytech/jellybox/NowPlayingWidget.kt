package com.prodigytech.jellybox

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.browse.MediaBrowser
import android.media.session.MediaController
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.KeyEvent
import android.view.View
import android.widget.RemoteViews
import com.prodigytech.home_screen_widgets.HomeScreenWidgetsPlugin
import com.ryanheise.audioservice.AudioService
import com.ryanheise.audioservice.MediaButtonReceiver
import org.json.JSONObject
import java.io.File

class NowPlayingWidget : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_CUSTOM) {
            intent.getStringExtra(EXTRA_CUSTOM_ACTION)?.let {
                sendCustomAction(context, it, goAsync())
            }
            return
        }
        super.onReceive(context, intent)
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val state = WidgetState.read(context)
        for (id in ids) manager.updateAppWidget(id, views(context, manager, id, state))
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        id: Int,
        options: Bundle,
    ) {
        manager.updateAppWidget(id, views(context, manager, id, WidgetState.read(context)))
    }

    private fun views(
        context: Context,
        manager: AppWidgetManager,
        id: Int,
        state: WidgetState?,
    ): RemoteViews {
        if (WidgetState.isSignedOut(context)) return renderSignedOut(context)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return RemoteViews(
                mapOf(
                    SizeF(COMPACT_MIN_WIDTH, 40f) to render(context, state, full = false),
                    SizeF(FULL_MIN_WIDTH, 40f) to render(context, state, full = true),
                ),
            )
        }
        val width = manager.getAppWidgetOptions(id)
            .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        return render(context, state, full = width >= FULL_MIN_WIDTH)
    }

    private fun render(context: Context, state: WidgetState?, full: Boolean): RemoteViews {
        val background = state?.background ?: DEFAULT_BACKGROUND
        val foreground = state?.foreground ?: DEFAULT_FOREGROUND

        return RemoteViews(context.packageName, R.layout.widget_now_playing).apply {
            setInt(R.id.widget_background, "setColorFilter", background)

            setTextViewText(
                R.id.widget_title,
                state?.title ?: context.getString(R.string.widget_idle_title),
            )
            setTextViewText(
                R.id.widget_artist,
                state?.artist ?: context.getString(R.string.widget_idle_subtitle),
            )
            setTextColor(R.id.widget_title, foreground)
            setTextColor(R.id.widget_artist, withAlpha(foreground, SECONDARY_ALPHA))

            val open = openApp(context)
            setOnClickPendingIntent(R.id.widget_root, open)
            setOnClickPendingIntent(R.id.widget_cover, open)
            setOnClickPendingIntent(R.id.widget_info, open)
            setViewVisibility(R.id.widget_controls, View.VISIBLE)

            val cover = state?.cover
            if (cover != null) {
                setImageViewBitmap(R.id.widget_cover, cover)
            } else {
                setImageViewResource(R.id.widget_cover, R.drawable.ic_widget_logo)
            }

            val playing = state?.playing ?: false
            setImageViewResource(
                R.id.widget_play_pause,
                if (playing) R.drawable.ic_widget_pause else R.drawable.ic_widget_play,
            )
            setContentDescription(
                R.id.widget_play_pause,
                context.getString(if (playing) R.string.widget_pause else R.string.widget_play),
            )
            for ((id, keyCode) in MEDIA_BUTTONS) {
                setInt(id, "setColorFilter", foreground)
                setOnClickPendingIntent(id, mediaButton(context, keyCode))
            }

            setViewVisibility(R.id.widget_like, if (state != null) View.VISIBLE else View.GONE)
            if (state != null) {
                val liked = state.liked
                setImageViewResource(
                    R.id.widget_like,
                    if (liked) R.drawable.ic_auto_favourite else R.drawable.ic_auto_favourite_border,
                )
                setContentDescription(
                    R.id.widget_like,
                    context.getString(if (liked) R.string.widget_unlike else R.string.widget_like),
                )
                setInt(R.id.widget_like, "setColorFilter", foreground)
                setOnClickPendingIntent(R.id.widget_like, customAction(context, FAVOURITE_ACTION))
            }

            val toggles = if (full) View.VISIBLE else View.GONE
            setViewVisibility(R.id.widget_shuffle, toggles)
            setViewVisibility(R.id.widget_repeat, toggles)
            if (full) {
                val shuffle = state?.shuffle ?: false
                setImageViewResource(
                    R.id.widget_shuffle,
                    if (shuffle) R.drawable.ic_widget_shuffle_on else R.drawable.ic_widget_shuffle,
                )
                setToggleColor(R.id.widget_shuffle, foreground, on = shuffle)
                setOnClickPendingIntent(R.id.widget_shuffle, customAction(context, SHUFFLE_ACTION))

                val repeat = state?.repeat ?: "off"
                setImageViewResource(
                    R.id.widget_repeat,
                    when (repeat) {
                        "all" -> R.drawable.ic_widget_repeat_on
                        "one" -> R.drawable.ic_widget_repeat_one_on
                        else -> R.drawable.ic_widget_repeat
                    },
                )
                setToggleColor(R.id.widget_repeat, foreground, on = repeat != "off")
                setOnClickPendingIntent(R.id.widget_repeat, customAction(context, REPEAT_ACTION))
            }
        }
    }

    private fun renderSignedOut(context: Context): RemoteViews =
        RemoteViews(context.packageName, R.layout.widget_now_playing).apply {
            setInt(R.id.widget_background, "setColorFilter", DEFAULT_BACKGROUND)
            setTextViewText(R.id.widget_title, context.getString(R.string.widget_idle_title))
            setTextViewText(
                R.id.widget_artist,
                context.getString(R.string.widget_signed_out_subtitle),
            )
            setTextColor(R.id.widget_title, DEFAULT_FOREGROUND)
            setTextColor(R.id.widget_artist, withAlpha(DEFAULT_FOREGROUND, SECONDARY_ALPHA))
            setImageViewResource(R.id.widget_cover, R.drawable.ic_widget_logo)
            setViewVisibility(R.id.widget_like, View.GONE)
            setViewVisibility(R.id.widget_controls, View.GONE)
            setOnClickPendingIntent(R.id.widget_root, openApp(context))
        }

    private fun RemoteViews.setToggleColor(id: Int, foreground: Int, on: Boolean) {
        setInt(id, "setColorFilter", if (on) foreground else withAlpha(foreground, OFF_ALPHA))
    }

    private fun mediaButton(context: Context, keyCode: Int): PendingIntent {
        val intent = Intent(Intent.ACTION_MEDIA_BUTTON)
            .setComponent(ComponentName(context, MediaButtonReceiver::class.java))
            .putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
        return PendingIntent.getBroadcast(context, keyCode, intent, PENDING_FLAGS)
    }

    private fun customAction(context: Context, action: String): PendingIntent {
        val intent = Intent(context, NowPlayingWidget::class.java)
            .setAction(ACTION_CUSTOM)
            .putExtra(EXTRA_CUSTOM_ACTION, action)
        return PendingIntent.getBroadcast(context, action.hashCode(), intent, PENDING_FLAGS)
    }

    private fun sendCustomAction(receiverContext: Context, action: String, pending: PendingResult) {
        val context = receiverContext.applicationContext
        var finished = false
        lateinit var browser: MediaBrowser
        fun finish() {
            if (finished) return
            finished = true
            browser.disconnect()
            pending.finish()
        }
        browser = MediaBrowser(
            context,
            ComponentName(context, AudioService::class.java),
            object : MediaBrowser.ConnectionCallback() {
                override fun onConnected() {
                    MediaController(context, browser.sessionToken)
                        .transportControls
                        .sendCustomAction(action, null)
                    finish()
                }

                override fun onConnectionFailed() = finish()

                override fun onConnectionSuspended() = finish()
            },
            null,
        )
        browser.connect()
    }

    private fun openApp(context: Context): PendingIntent? {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: return null
        return PendingIntent.getActivity(context, 0, intent, PENDING_FLAGS)
    }

    private fun withAlpha(color: Int, alpha: Int): Int = (color and 0x00FFFFFF) or (alpha shl 24)

    private class WidgetState(
        val title: String,
        val artist: String,
        val playing: Boolean,
        val liked: Boolean,
        val shuffle: Boolean,
        val repeat: String,
        val cover: Bitmap?,
        val background: Int?,
        val foreground: Int?,
    ) {
        companion object {
            fun isSignedOut(context: Context): Boolean =
                snapshot(context)?.optBoolean("signedOut") ?: false

            fun read(context: Context): WidgetState? {
                val json = snapshot(context) ?: return null
                val title = json.stringOrNull("title") ?: return null
                return WidgetState(
                    title = title,
                    artist = json.stringOrNull("artist").orEmpty(),
                    playing = json.optBoolean("playing"),
                    liked = json.optBoolean("liked"),
                    shuffle = json.optBoolean("shuffle"),
                    repeat = json.stringOrNull("repeat") ?: "off",
                    cover = json.stringOrNull("cover")?.let(::decodeCover),
                    background = json.colorOrNull("background"),
                    foreground = json.colorOrNull("foreground"),
                )
            }

            private fun snapshot(context: Context): JSONObject? {
                val file = File(HomeScreenWidgetsPlugin.directory(context), SNAPSHOT_FILE)
                if (!file.isFile) return null
                return runCatching { JSONObject(file.readText()) }.getOrNull()
            }

            private fun decodeCover(path: String): Bitmap? =
                File(path).takeIf { it.isFile }?.let { BitmapFactory.decodeFile(it.path) }

            private fun JSONObject.stringOrNull(key: String): String? =
                if (isNull(key)) null else optString(key).takeIf { it.isNotEmpty() }

            private fun JSONObject.colorOrNull(key: String): Int? =
                if (isNull(key)) null else optLong(key).toInt()
        }
    }

    private companion object {
        const val SNAPSHOT_FILE = "now_playing.json"
        const val ACTION_CUSTOM = "com.prodigytech.jellybox.widget.CUSTOM_ACTION"
        const val EXTRA_CUSTOM_ACTION = "action"
        const val SHUFFLE_ACTION = "jellybox.shuffle"
        const val REPEAT_ACTION = "jellybox.repeat"
        const val FAVOURITE_ACTION = "jellybox.favourite"
        const val COMPACT_MIN_WIDTH = 180f
        const val FULL_MIN_WIDTH = 300f
        const val DEFAULT_BACKGROUND = 0xFF2B2B30.toInt()
        const val DEFAULT_FOREGROUND = 0xFFFFFFFF.toInt()
        const val SECONDARY_ALPHA = 0xB3
        const val OFF_ALPHA = 0x73
        const val PENDING_FLAGS = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT

        val MEDIA_BUTTONS = listOf(
            R.id.widget_previous to KeyEvent.KEYCODE_MEDIA_PREVIOUS,
            R.id.widget_play_pause to KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE,
            R.id.widget_next to KeyEvent.KEYCODE_MEDIA_NEXT,
        )
    }
}
