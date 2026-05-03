package com.boiaro.app

import android.os.Bundle
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Facebook SDK is initialized in MainApplication.kt
        // flutter_facebook_auth plugin registers its channel automatically
    }
}
