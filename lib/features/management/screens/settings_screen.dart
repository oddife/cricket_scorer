import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme_mode_provider.dart';
import '../../../application/sync/sync_provider.dart';
import '../../../core/supabase/supabase_auth_provider.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../matches/providers/match_provider.dart';
import '../../teams/providers/team_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _urlController;
  late final TextEditingController _keyController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _obscureKey = true;
  bool _obscurePassword = true;
  bool _saving = false;
  bool _syncing = false;
  bool _authenticating = false;
  bool? _connected;
  String _connectionLog = 'Not checked yet';

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
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkConnection();
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _checkConnection() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      if (!mounted) return;
      setState(() {
        _connected = false;
        _connectionLog = 'Supabase is not configured';
      });
      return;
    }

    if (mounted) {
      setState(() => _connected = null);
    }

    try {
      await client.from('teams').select('sync_id').limit(1);
      if (!mounted) return;
      setState(() {
        _connected = true;
        final user = ref.read(supabaseAuthServiceProvider).currentUser;
        _connectionLog = user == null
            ? 'Connection successful; not authenticated'
            : 'Connection successful; signed in as ${user.email ?? 'scorer'}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _connected = false;
        _connectionLog = 'Connection failed: $error';
      });
    }
  }

  Future<void> _signIn() async {
    if (_authenticating) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Enter the scorer email and password.');
      return;
    }

    setState(() => _authenticating = true);
    try {
      final auth = ref.read(supabaseAuthServiceProvider);
      await auth.signInWithPassword(email: email, password: password);
      if (!mounted) return;
      _passwordController.clear();
      final user = auth.currentUser;
      setState(() {
        _connectionLog =
            'Signed in as ${user?.email ?? email}. Supabase sync is ready.';
      });
      _showMessage('Signed in successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _connectionLog = 'Sign in failed: $error');
      _showMessage('Sign in failed: $error');
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  Future<void> _signOut() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    try {
      await ref.read(supabaseAuthServiceProvider).signOut();
      if (!mounted) return;
      setState(() => _connectionLog = 'Signed out. Supabase sync requires sign in.');
      _showMessage('Signed out.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _connectionLog = 'Sign out failed: $error');
      _showMessage('Sign out failed: $error');
    } finally {
      if (mounted) setState(() => _authenticating = false);
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
      final worker = ref.read(syncWorkerProvider);
      final synced = await worker.runOnce();
      if (!mounted) return;

      // Catalog and synchronized matches are imported directly into Drift.
      // Bump the shared refresh signal so already-open screens query Drift again.
      ref.read(catalogSyncRefreshProvider.notifier).state++;
      ref.invalidate(teamProvider);
      ref.invalidate(matchProvider);

      final catalogSummary = [
        'catalog synced ${worker.lastCatalogSynced}',
        'failed ${worker.lastCatalogFailed}',
        'blocked ${worker.lastCatalogBlocked}',
      ].join(', ');
      final matchSummary = 'matches pulled ${worker.lastMatchesDownloaded}';
      final errorLines = [
        ...worker.lastCatalogErrors,
        ...worker.lastMatchErrors,
      ];
      final errorSummary = errorLines.isEmpty
          ? ''
          : '\n${errorLines.join('\n')}';

      setState(() {
        _connectionLog =
            'Sync successful: $synced ball event(s); $matchSummary; $catalogSummary$errorSummary';
      });
      _showMessage(
        'Sync completed: $synced ball event(s); $matchSummary; $catalogSummary.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _connectionLog = 'Sync failed: $error');
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

  Widget _connectionStatus(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color color;
    final IconData icon;
    final String label;

    if (_connected == null) {
      color = colorScheme.onSurfaceVariant;
      icon = Icons.sync_outlined;
      label = 'Checking...';
    } else if (_connected == true) {
      color = Colors.green;
      icon = Icons.check_circle_outline;
      label = 'Connected';
    } else {
      color = colorScheme.error;
      icon = Icons.error_outline;
      label = 'Offline';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final auth = ref.watch(supabaseAuthServiceProvider);
    final currentUser = auth.currentUser;

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
                  Text(
                    'Scorer authentication',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentUser == null
                        ? 'Sign in with a Supabase Auth account before using synchronization.'
                        : 'Signed in as ${currentUser.email ?? 'scorer'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  if (currentUser == null) ...[
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _authenticating ? null : _signIn,
                      icon: _authenticating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login_outlined),
                      label: Text(_authenticating ? 'Signing in...' : 'Sign In'),
                    ),
                  ] else
                    OutlinedButton.icon(
                      onPressed: _authenticating ? null : _signOut,
                      icon: _authenticating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout_outlined),
                      label: Text(_authenticating ? 'Signing out...' : 'Sign Out'),
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
                      _connectionStatus(context),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _connectionLog,
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
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
