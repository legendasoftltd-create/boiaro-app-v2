package com.boiaro.app

import com.example.epub_reader_kit.reader.EpubReaderKitApp
import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsLogger

// MainApplication extends EpubReaderKitApp so that the epub_reader_kit plugin's
// `application as? EpubReaderKitApp` cast succeeds (required for native EPUB reader).
// EpubReaderKitApp extends Application and initializes Readium, BookRepository, etc. via super.onCreate().
class MainApplication : EpubReaderKitApp() {
    override fun onCreate() {
        super.onCreate() // Initializes Readium, BookRepository, ReaderRepository, Coil
        FacebookSdk.setApplicationId("893488806736240")
        FacebookSdk.setClientToken("20166a09915e3e4c03bb6c4632931c25")
        FacebookSdk.sdkInitialize(applicationContext)
        AppEventsLogger.activateApp(this)
    }
}
