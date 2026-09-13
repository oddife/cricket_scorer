import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme_mode_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        ],
      ),
    );
  }
}
