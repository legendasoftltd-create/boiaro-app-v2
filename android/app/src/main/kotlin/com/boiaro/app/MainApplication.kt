package com.boiaro.app

import android.app.Application
import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsLogger

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        FacebookSdk.setApplicationId("1107222701362204")
        FacebookSdk.setClientToken("2e69f0944977c1702d11c745449c2e1c")
        FacebookSdk.sdkInitialize(applicationContext)
        AppEventsLogger.activateApp(this)
    }
}
