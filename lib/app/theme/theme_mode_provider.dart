import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _preferenceKey = 'theme_mode';

  late final SharedPreferences _preferences;

  @override
  ThemeMode build() {
    _preferences = ref.watch(sharedPreferencesProvider);
    return _readMode();
  }

  void setMode(ThemeMode mode) {
    state = mode;
    _preferences.setString(_preferenceKey, mode.name);
  }

  ThemeMode _readMode() {
    final value = _preferences.getString(_preferenceKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});
