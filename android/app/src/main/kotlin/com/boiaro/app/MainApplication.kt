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
        FacebookSdk.setApplicationId("1107222701362204")
        FacebookSdk.setClientToken("2e69f0944977c1702d11c745449c2e1c")
        FacebookSdk.sdkInitialize(applicationContext)
        AppEventsLogger.activateApp(this)
    }
}
