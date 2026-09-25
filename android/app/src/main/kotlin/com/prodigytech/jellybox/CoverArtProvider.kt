package com.prodigytech.jellybox

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import com.ryanheise.audioservice.AudioServicePlugin
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileNotFoundException
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

class CoverArtProvider : ContentProvider() {
    override fun onCreate(): Boolean = true

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        if (mode != "r") throw FileNotFoundException("Read-only provider")
        val segments = uri.pathSegments
        if (segments.size == 2 && segments[0] == REMOTE) return remoteCover(segments[1])
        val albumId = segments.singleOrNull()
            ?: throw FileNotFoundException(uri.toString())
        val context = context ?: throw FileNotFoundException("No context")
        val musicRoot = File(context.getDir("flutter", 0), "music").canonicalFile
        val cover = File(File(musicRoot, albumId), "cover.jpg").canonicalFile
        val insideRoot = cover.parentFile?.parentFile == musicRoot
        if (!insideRoot || !cover.isFile) throw FileNotFoundException(uri.toString())
        return ParcelFileDescriptor.open(cover, ParcelFileDescriptor.MODE_READ_ONLY)
    }

    private fun remoteCover(key: String): ParcelFileDescriptor {
        if (Looper.myLooper() == Looper.getMainLooper()) throw FileNotFoundException(key)
        val engine = FlutterEngineCache.getInstance().get(AudioServicePlugin.getFlutterEngineId())
            ?: throw FileNotFoundException(key)
        val latch = CountDownLatch(1)
        var path: String? = null
        Handler(Looper.getMainLooper()).post {
            MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).invokeMethod(
                "artwork",
                key,
                object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        path = result as? String
                        latch.countDown()
                    }

                    override fun error(code: String, message: String?, details: Any?) {
                        latch.countDown()
                    }

                    override fun notImplemented() {
                        latch.countDown()
                    }
                },
            )
        }
        if (!latch.await(TIMEOUT_SECONDS, TimeUnit.SECONDS)) throw FileNotFoundException(key)
        val file = path?.let(::File)?.takeIf { it.isFile } ?: throw FileNotFoundException(key)
        return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
    }

    override fun getType(uri: Uri): String = "image/jpeg"

    override fun query(
        uri: Uri,
        projection: Array<String>?,
        selection: String?,
        selectionArgs: Array<String>?,
        sortOrder: String?,
    ): Cursor? = null

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<String>?): Int = 0

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<String>?,
    ): Int = 0

    private companion object {
        const val REMOTE = "remote"
        const val CHANNEL = "com.prodigytech.jellybox/cover_art"
        const val TIMEOUT_SECONDS = 10L
    }
}
