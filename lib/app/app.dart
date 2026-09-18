import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_provider.dart';

class CricketScorerApp extends ConsumerWidget {
  const CricketScorerApp({super.key});

  static const appVersion = 'v1.0.1 (Build 2)';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'New Castle Cricket Scorer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            Positioned(
              right: 10,
              bottom: 6,
              child: IgnorePointer(
                child: Text(
                  appVersion,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.55),
                        fontSize: 10,
                      ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
