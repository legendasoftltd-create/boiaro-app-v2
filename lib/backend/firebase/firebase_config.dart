import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyB89OZnFM0sc4l3Teir4bDxmsdNl9Im8mI",
            authDomain: "ebook-c5445.firebaseapp.com",
            projectId: "ebook-c5445",
            storageBucket: "ebook-c5445.firebasestorage.app",
            messagingSenderId: "961638140230",
            appId: "1:961638140230:web:71729ef7f5b2bffb097d47", // Estimated from project number
            measurementId: "G-XXXXXXXXXX"));
  } else {
    await Firebase.initializeApp();
  }
}
