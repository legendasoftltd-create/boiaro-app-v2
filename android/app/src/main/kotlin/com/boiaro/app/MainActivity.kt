package com.boiaro.app

import com.boiaro.app.readium.ReadiumChannelHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ReadiumChannelHandler.CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                ReadiumChannelHandler.handleCall(this, call, result)
            }
    }
}
