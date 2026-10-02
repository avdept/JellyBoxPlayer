package com.felnanuke.google_cast.extensions


import android.net.Uri
import com.google.android.gms.cast.MediaMetadata
import com.google.android.gms.common.images.WebImage
import java.util.*

class GoogleCastMetadataBuilder {
    companion object {
        fun fromMap(args: Map<String, Any?>): MediaMetadata? {

            val map = args.toMutableMap()
            if (map.isEmpty()) return null
            val type = (args["metadataType"] as? Number)?.toInt() ?: return null
            val metadata = MediaMetadata(type)


            for (item in map) {
                val datesKey = listOf(
                    "releaseDate",
                    "broadcastDate",
                    "creationDateTime",
                    "creationDate"
                )
                if (item.key == "metadataType" || item.key == "images") continue
                if (item.value == null) continue

                if (item.key in datesKey) {
                    val millis = (item.value as? Number)?.toLong()
                    if (millis == null) continue

                    val calendar = Calendar.getInstance()
                    calendar.timeInMillis = millis
                    when (item.key) {
                        "releaseDate" -> metadata.putDate(MediaMetadata.KEY_RELEASE_DATE, calendar)
                        "broadcastDate" -> metadata.putDate(
                            MediaMetadata.KEY_BROADCAST_DATE, calendar
                        )
                        "creationDateTime" -> metadata.putDate(
                            MediaMetadata.KEY_CREATION_DATE, calendar
                        )
                        "creationDate" -> metadata.putDate(
                            MediaMetadata.KEY_CREATION_DATE, calendar
                        )
                    }


                } else {
                    val value = item.value
                    when (value) {
                        is String -> metadata.putString(item.key, value)
                        is Int -> metadata.putInt(
                            item.key, value
                        )
                        is Long -> metadata.putInt(item.key, value.toInt())
                        is Float -> metadata.putDouble(item.key, value.toDouble())
                        is Double -> metadata.putDouble(item.key, value)

                    }
                }

            }
            val imagesData = map["images"] as List<Map<String, Any?>>?
            if (imagesData != null) {
                val images = imagesData.map {
                    imageFromMap(it)
                }
                for (image in images) {
                    metadata.addImage(image)
                }
            }
            return metadata
        }

        private fun imageFromMap(args: Map<String, Any?>): WebImage {
            val url = args["url"] as String
            val width = args["width"] as Int?
            val height = args["height"] as Int?
            return WebImage(Uri.parse(url), width ?: 250, height ?: 250)
        }


    }
}

fun MediaMetadata.toMap(): Map<String, Any?> {
    val map = mutableMapOf<String, Any?>()
   for ( key in  this.keySet() ){
       MediaMetadata.getTypeForKey(key)
   }
    return map
}