import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;

/// Firebase Configuration Class
/// Derived from the HejApp .NET MAUI project credentials.
class HejAppFirebaseConfig {
  static const String apiKey = 'AIzaSyCdI1i8toUh_5BedSz5ISf_L5930tdg6Z8';
  static const String appId = '1:278299747848:android:eec00e7e588903b3ad93bd'; // Android ID as default
  static const String messagingSenderId = '278299747848';
  static const String projectId = 'hejapp-a6614';
  static const String databaseUrl = 'https://hejapp-a6614-default-rtdb.firebaseio.com/';
  static const String storageBucket = 'hejapp-a6614.firebasestorage.app';

  // AI Keys
  static const String geminiApiKey = 'AIzaSyAlqsf_4zeJsMkedobAzYU-RVkk1lN8nqM';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: apiKey,
        appId: '1:278299747848:web:some_web_id', // Would need web ID if we grow
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        authDomain: 'hejapp-a6614.firebaseapp.com',
        databaseURL: databaseUrl,
        storageBucket: storageBucket,
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          databaseURL: databaseUrl,
          storageBucket: storageBucket,
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: apiKey,
          appId: '1:278299747848:ios:5ec0df17cdf82de6ad93bd', // Updated with correct ID
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          databaseURL: databaseUrl,
          storageBucket: storageBucket,
          iosBundleId: 'com.companyname.hejapp',
        );
      default:
        throw UnsupportedError(
          'FirebaseOptions are not supported for this platform.',
        );
    }
  }
}
