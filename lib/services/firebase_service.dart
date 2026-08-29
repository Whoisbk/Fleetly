import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseService {
  static bool _initialized = false;

  static bool get isAvailable => _initialized;
  static FirebaseAuth get auth => FirebaseAuth.instance;

  static Future<void> initialize() async {
    if (!DefaultFirebaseOptions.isConfigured) {
      debugPrint(
        'Firebase not configured. Run: flutterfire configure\n'
        'Demo auth mode will be used until Firebase is set up.',
      );
      return;
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _initialized = true;
  }

  /// Refresh token so Supabase receives the `role: authenticated` custom claim.
  static Future<String?> getIdToken({bool forceRefresh = false}) async {
    return auth.currentUser?.getIdToken(forceRefresh);
  }
}
