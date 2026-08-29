import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import 'firebase_service.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabasePublishableKey,
      // Pass Firebase JWT so Supabase RLS works with auth.uid()
      accessToken: FirebaseService.isAvailable
          ? () => FirebaseService.getIdToken()
          : null,
    );
  }
}
