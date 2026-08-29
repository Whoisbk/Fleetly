abstract final class AppConstants {
  static const appName = 'Fleetly';
  static const currencySymbol = 'R';

  static const supabaseUrl = 'https://jtykzxckmegndmsmsibx.supabase.co';
  static const supabasePublishableKey =
      'sb_publishable_uml4BNJtqtYetZrSS9MrCw_8yKp3uRM';

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
