package com.prodigytech.jellybox

import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import androidx.tvprovider.media.tv.PreviewChannel
import androidx.tvprovider.media.tv.PreviewChannelHelper
import androidx.tvprovider.media.tv.PreviewProgram
import androidx.tvprovider.media.tv.TvContractCompat
import java.io.File

object TvHomeChannel {
    const val COVER_SEGMENT = "channel"
    const val ALBUM_HOST = "album"
    private const val COVERS_DIR = "tv_channel"
    private const val TAG = "TvHomeChannel"
    private const val LOGO_SIZE = 256
    private val SAFE_ID = Regex("[A-Za-z0-9_-]+")

    fun coverFile(context: Context, albumId: String): File? {
        if (!SAFE_ID.matches(albumId)) return null
        return File(File(context.filesDir, COVERS_DIR), "$albumId.jpg")
    }

    fun publish(context: Context, title: String, albums: List<Map<*, *>>) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        try {
            val helper = PreviewChannelHelper(context)
            val channelId = channelId(context, helper, title)
            context.contentResolver.delete(
                TvContractCompat.buildPreviewProgramsUriForChannel(channelId),
                null,
                null,
            )
            val kept = mutableSetOf<String>()
            albums.forEachIndexed { index, album ->
                val id = album["id"] as? String ?: return@forEachIndexed
                val name = album["title"] as? String ?: return@forEachIndexed
                val builder = PreviewProgram.Builder()
                    .setChannelId(channelId)
                    .setType(TvContractCompat.PreviewPrograms.TYPE_ALBUM)
                    .setTitle(name)
                    .setInternalProviderId(id)
                    .setIntentUri(albumUri(id))
                    .setWeight(albums.size - index)
                (album["artist"] as? String)?.takeIf { it.isNotEmpty() }?.let {
                    builder.setDescription(it).setAuthor(it)
                }
                copyCover(context, id, album["cover"] as? String)?.let { file ->
                    kept += file.name
                    builder
                        .setPosterArtUri(coverUri(context, id))
                        .setPosterArtAspectRatio(TvContractCompat.PreviewPrograms.ASPECT_RATIO_1_1)
                }
                helper.publishPreviewProgram(builder.build())
            }
            File(context.filesDir, COVERS_DIR).listFiles()
                ?.filter { it.name !in kept }
                ?.forEach { it.delete() }
        } catch (error: Exception) {
            Log.w(TAG, "could not publish home channel", error)
        }
    }

    fun clear(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        try {
            existingChannelId(context)?.let { id ->
                context.contentResolver.delete(
                    TvContractCompat.buildPreviewProgramsUriForChannel(id),
                    null,
                    null,
                )
            }
        } catch (error: Exception) {
            Log.w(TAG, "could not clear home channel", error)
        }
        File(context.filesDir, COVERS_DIR).deleteRecursively()
    }

    fun albumIdFrom(uri: Uri?): String? {
        if (uri == null || uri.scheme != SCHEME || uri.host != ALBUM_HOST) return null
        return uri.pathSegments.singleOrNull()
    }

    private const val SCHEME = "jellybox"

    private fun albumUri(id: String): Uri =
        Uri.Builder().scheme(SCHEME).authority(ALBUM_HOST).appendPath(id).build()

    private fun coverUri(context: Context, id: String): Uri =
        Uri.Builder()
            .scheme("content")
            .authority("${context.packageName}.covers")
            .appendPath(COVER_SEGMENT)
            .appendPath(id)
            .build()

    private fun copyCover(context: Context, id: String, path: String?): File? {
        if (path == null) return null
        val source = File(path).takeIf { it.isFile } ?: return null
        val target = coverFile(context, id) ?: return null
        target.parentFile?.mkdirs()
        source.copyTo(target, overwrite = true)
        return target
    }

    private fun channelId(context: Context, helper: PreviewChannelHelper, title: String): Long {
        existingChannelId(context)?.let { id ->
            val values = ContentValues().apply {
                put(TvContractCompat.Channels.COLUMN_DISPLAY_NAME, title)
                put(TvContractCompat.Channels.COLUMN_DESCRIPTION, title)
            }
            context.contentResolver.update(TvContractCompat.buildChannelUri(id), values, null, null)
            return id
        }
        val channel = PreviewChannel.Builder()
            .setDisplayName(title)
            .setDescription(title)
            .setAppLinkIntentUri(
                Uri.Builder().scheme(SCHEME).authority("home").build(),
            )
            .setLogo(launcherLogo(context))
            .build()
        val id = helper.publishDefaultChannel(channel)
        try {
            TvContractCompat.requestChannelBrowsable(context, id)
        } catch (error: Exception) {
            Log.w(TAG, "could not make channel browsable", error)
        }
        return id
    }

    private fun existingChannelId(context: Context): Long? =
        context.contentResolver.query(
            TvContractCompat.Channels.CONTENT_URI,
            arrayOf(TvContractCompat.Channels._ID),
            null,
            null,
            null,
        )?.use { cursor -> if (cursor.moveToFirst()) cursor.getLong(0) else null }

    private fun launcherLogo(context: Context): Bitmap {
        val bitmap = Bitmap.createBitmap(LOGO_SIZE, LOGO_SIZE, Bitmap.Config.ARGB_8888)
        ContextCompat.getDrawable(context, R.mipmap.ic_launcher)?.let { icon ->
            icon.setBounds(0, 0, LOGO_SIZE, LOGO_SIZE)
            icon.draw(Canvas(bitmap))
        }
        return bitmap
    }
}
