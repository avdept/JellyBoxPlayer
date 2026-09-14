package com.prodigytech.jellybox

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import java.io.File
import java.io.FileNotFoundException

class CoverArtProvider : ContentProvider() {
    override fun onCreate(): Boolean = true

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        if (mode != "r") throw FileNotFoundException("Read-only provider")
        val albumId = uri.pathSegments.singleOrNull()
            ?: throw FileNotFoundException(uri.toString())
        val context = context ?: throw FileNotFoundException("No context")
        val musicRoot = File(context.getDir("flutter", 0), "music").canonicalFile
        val cover = File(File(musicRoot, albumId), "cover.jpg").canonicalFile
        val insideRoot = cover.parentFile?.parentFile == musicRoot
        if (!insideRoot || !cover.isFile) throw FileNotFoundException(uri.toString())
        return ParcelFileDescriptor.open(cover, ParcelFileDescriptor.MODE_READ_ONLY)
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
}
