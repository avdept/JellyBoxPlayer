package com.prodigytech.jellybox

import android.content.Context
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object CrashLog {
    private const val FILE_NAME = "jellybox.log"
    private const val MAX_FRAMES = 40
    private var installed = false

    fun install(context: Context) {
        if (installed) return
        installed = true
        val app = context.applicationContext
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, error ->
            runCatching { append(app, thread, error) }
            previous?.uncaughtException(thread, error)
        }
    }

    private fun append(context: Context, thread: Thread, error: Throwable) {
        val dir = context.getExternalFilesDir(null) ?: context.filesDir
        val stamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US).format(Date())
        val trace = StringWriter().also { error.printStackTrace(PrintWriter(it)) }
            .toString()
            .lineSequence()
            .take(MAX_FRAMES)
            .joinToString("\n")
        File(dir, FILE_NAME).appendText(
            "$stamp [crash] uncaught on thread ${thread.name}: $trace\n",
        )
    }
}
