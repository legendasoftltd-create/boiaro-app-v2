package com.boiaro.app.readium

import android.app.Activity
import android.content.Intent
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object ReadiumChannelHandler {
    const val CHANNEL_NAME = "com.boiaro.app/readium_reader"

    fun handleCall(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "openEpubReader" -> {
                val epubPath = call.argument<String>("epubPath")
                val bookTitle = call.argument<String>("bookTitle")
                val bookId = call.argument<String>("bookId")

                if (epubPath.isNullOrBlank()) {
                    result.error("invalid_args", "epubPath is required", null)
                    return
                }

                try {
                    val intent = Intent(activity, ReadiumReaderActivity::class.java).apply {
                        putExtra(ReadiumReaderActivity.EXTRA_EPUB_PATH, epubPath)
                        putExtra(ReadiumReaderActivity.EXTRA_BOOK_TITLE, bookTitle ?: "Reader")
                        putExtra(ReadiumReaderActivity.EXTRA_BOOK_ID, bookId ?: epubPath)
                    }
                    activity.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error(
                        "launch_failed",
                        "Failed to open Readium reader: ${e.message}",
                        null
                    )
                }
            }

            else -> result.notImplemented()
        }
    }
}
