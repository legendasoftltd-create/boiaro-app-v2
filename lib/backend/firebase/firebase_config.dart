import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyAnjWS0l49VkX8p0sCo_xDuEjGHCaQQh7g",
            authDomain: "a-i-ebook-app-nth7ef.firebaseapp.com",
            projectId: "a-i-ebook-app-nth7ef",
            storageBucket: "a-i-ebook-app-nth7ef.appspot.com",
            messagingSenderId: "299024357634",
            appId: "1:299024357634:web:c441e24bf2b71efeaaca1b",
            measurementId: "G-C2GD7924BL"));
  } else {
    await Firebase.initializeApp();
  }
}
