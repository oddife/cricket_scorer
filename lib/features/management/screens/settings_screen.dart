import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme_mode_provider.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/database/database_provider.dart';
import '../../../application/sync/sync_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _urlController;
  late final TextEditingController _keyController;
  bool _obscureKey = true;
  bool _saving = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    final preferences = ref.read(sharedPreferencesProvider);
    _urlController = TextEditingController(
      text: preferences.getString(SupabaseConfig.urlPreferenceKey) ??
          SupabaseConfig.url,
    );
    _keyController = TextEditingController(
      text: preferences
              .getString(SupabaseConfig.publishableKeyPreferenceKey) ??
          SupabaseConfig.publishableKey,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _saveSupabaseSettings() async {
    final url = _urlController.text.trim();
    final key = _keyController.text.trim();

    if (url.isNotEmpty && Uri.tryParse(url)?.hasScheme != true) {
      _showMessage('Enter a valid Supabase URL, including https://.');
      return;
    }
    if ((url.isEmpty) != (key.isEmpty)) {
      _showMessage(
        'Enter both Supabase values, or leave both empty for offline mode.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final preferences = ref.read(sharedPreferencesProvider);
      await preferences.setString(SupabaseConfig.urlPreferenceKey, url);
      await preferences.setString(
        SupabaseConfig.publishableKeyPreferenceKey,
        key,
      );
      if (!mounted) return;
      _showMessage(
        url.isEmpty
            ? 'Supabase settings cleared. Restart the app to apply offline mode.'
            : 'Supabase settings saved. Restart the app to connect to the new server.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _syncNow() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      final client = ref.read(supabaseClientProvider);
      if (client == null) {
        _showMessage('Supabase is not configured. Configure it first.');
        return;
      }
      await ref.read(syncWorkerProvider).runOnce();
      if (!mounted) return;
      _showMessage('Sync completed.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Sync failed: $error');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: RadioGroup<ThemeMode>(
              groupValue: themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setMode(value);
                }
              },
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    secondary: const Icon(Icons.light_mode_outlined),
                    title: const Text('Light'),
                    subtitle: const Text('Always use light mode'),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Dark'),
                    subtitle: const Text('Always use dark mode'),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    secondary: const Icon(Icons.brightness_auto_outlined),
                    title: const Text('Follow system'),
                    subtitle: const Text('Use the device or Windows theme'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Supabase',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backend connection',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Configure the self-hosted Supabase server used for synchronization and match recovery. Leave both fields empty to keep the app offline-only.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'SUPABASE_URL',
                      hintText: 'https://supabase.example.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cloud_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _keyController,
                    obscureText: _obscureKey,
                    decoration: InputDecoration(
                      labelText: 'SUPABASE_PUBLISHABLE_KEY',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.key_outlined),
                      suffixIcon: IconButton(
                        tooltip: _obscureKey ? 'Show key' : 'Hide key',
                        onPressed: () =>
                            setState(() => _obscureKey = !_obscureKey),
                        icon: Icon(
                          _obscureKey
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.end,
                    children: [
                      FilledButton.icon(
                        onPressed: _saving ? null : _saveSupabaseSettings,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Save Supabase Settings'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _syncing ? null : _syncNow,
                        icon: _syncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync_outlined),
                        label: Text(_syncing ? 'Syncing...' : 'Sync Now'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A restart is required after changing these values because the Supabase client is initialized when the app starts.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
