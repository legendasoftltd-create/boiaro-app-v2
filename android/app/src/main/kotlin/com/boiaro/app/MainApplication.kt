package com.boiaro.app

import android.app.Application
import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsLogger

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        FacebookSdk.setApplicationId("893488806736240")
        FacebookSdk.setClientToken("20166a09915e3e4c03bb6c4632931c25")
        FacebookSdk.sdkInitialize(applicationContext)
        AppEventsLogger.activateApp(this)
    }
}
