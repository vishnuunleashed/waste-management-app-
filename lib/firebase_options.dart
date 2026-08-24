import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Hand-written Firebase configuration sourced from
/// `android/app/google-services.json` (project `waste-management-app-505810`).
///
/// Only Android is configured today. iOS/web have no Firebase app registered
/// in the console yet (no `GoogleService-Info.plist` / web app), so those
/// platforms intentionally throw until they're set up — either by adding the
/// platform in the Firebase console and re-running `flutterfire configure`,
/// or by hand-adding an options block here the same way this one was built.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web. '
        'Add a web app in the Firebase console and configure options here.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for '
          '$defaultTargetPlatform. Only Android is configured today.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCRlZNsprIaQkhj4GrlqSYTmxUx7LdYDzI',
    appId: '1:836913278630:android:4b31aac0198aec8b078e67',
    messagingSenderId: '836913278630',
    projectId: 'waste-management-app-505810',
    storageBucket: 'waste-management-app-505810.firebasestorage.app',
  );
}
