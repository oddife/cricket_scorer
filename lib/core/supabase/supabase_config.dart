import 'package:shared_preferences/shared_preferences.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static const urlPreferenceKey = 'supabase_url';
  static const publishableKeyPreferenceKey = 'supabase_publishable_key';

  static String resolveUrl(SharedPreferences preferences) {
    return preferences.getString(urlPreferenceKey)?.trim() ?? url;
  }

  static String resolvePublishableKey(SharedPreferences preferences) {
    return preferences.getString(publishableKeyPreferenceKey)?.trim() ??
        publishableKey;
  }

  static bool isConfiguredWith(SharedPreferences preferences) {
    return resolveUrl(preferences).isNotEmpty &&
        resolvePublishableKey(preferences).isNotEmpty;
  }

  static bool get isConfigured =>
      url.isNotEmpty && publishableKey.isNotEmpty;
}
