package com.example.rapiddo.rapid_do

import io.flutter.plugin.common.EventChannel

object FloatingOcrBridge {
    @Volatile
    var eventSink: EventChannel.EventSink? = null

    fun emit(status: String, message: String? = null, text: String? = null) {
        val payload = mutableMapOf<String, Any?>("status" to status)
        if (message != null) payload["message"] = message
        if (text != null) payload["text"] = text
        eventSink?.success(payload)
    }
}
