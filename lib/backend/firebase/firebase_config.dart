import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyAXVH1YStxW-eMyR5j-2CJDNabvWf9DyIw",
            authDomain: "boiaro.firebaseapp.com",
            projectId: "boiaro",
            storageBucket: "boiaro.firebasestorage.app",
            messagingSenderId: "37005664714",
            appId: "1:37005664714:web:743e281379bae04d6e2f33"));
  } else {
    await Firebase.initializeApp();
  }
}
