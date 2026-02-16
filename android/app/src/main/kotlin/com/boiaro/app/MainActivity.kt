package com.boiaro.app

import android.os.Bundle
import com.boiaro.app.readium.ReadiumChannelHandler
import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsLogger
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        FacebookSdk.setApplicationId("893488806736240")
        FacebookSdk.setClientToken("20166a09915e3e4c03bb6c4632931c25")
        FacebookSdk.sdkInitialize(applicationContext)
        AppEventsLogger.activateApp(application)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ReadiumChannelHandler.CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                ReadiumChannelHandler.handleCall(this, call, result)
            }
    }
}
