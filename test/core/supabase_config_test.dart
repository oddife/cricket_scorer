import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cricket_scorer/core/supabase/supabase_config.dart';

void main() {
  test('uses saved Supabase settings when configured', () async {
    SharedPreferences.setMockInitialValues({
      SupabaseConfig.urlPreferenceKey: ' https://supabase.example.com ',
      SupabaseConfig.publishableKeyPreferenceKey: ' saved-key ',
    });
    final preferences = await SharedPreferences.getInstance();

    expect(
      SupabaseConfig.resolveUrl(preferences),
      'https://supabase.example.com',
    );
    expect(SupabaseConfig.resolvePublishableKey(preferences), 'saved-key');
    expect(SupabaseConfig.isConfiguredWith(preferences), isTrue);
  });

  test('empty saved values intentionally keep the app offline', () async {
    SharedPreferences.setMockInitialValues({
      SupabaseConfig.urlPreferenceKey: '',
      SupabaseConfig.publishableKeyPreferenceKey: '',
    });
    final preferences = await SharedPreferences.getInstance();

    expect(SupabaseConfig.resolveUrl(preferences), isEmpty);
    expect(SupabaseConfig.resolvePublishableKey(preferences), isEmpty);
    expect(SupabaseConfig.isConfiguredWith(preferences), isFalse);
  });
}
