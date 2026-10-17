import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/sync/sync_provider.dart';
import '../features/matches/providers/match_provider.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_provider.dart';

class CricketScorerApp extends ConsumerWidget {
  const CricketScorerApp({super.key});

  static const appVersion = 'v1.0.1 (Build 3)';

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
            const _AutomaticSync(),
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

/// Keeps local scoring changes and the synchronized match catalog moving
/// without requiring the scorer to open Settings and press Sync Now.
class _AutomaticSync extends ConsumerStatefulWidget {
  const _AutomaticSync();

  @override
  ConsumerState<_AutomaticSync> createState() => _AutomaticSyncState();
}

class _AutomaticSyncState extends ConsumerState<_AutomaticSync> {
  Timer? _timer;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _sync());
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  Future<void> _sync() async {
    if (_running || !mounted) return;
    _running = true;
    try {
      final worker = ref.read(syncWorkerProvider);
      final synced = await worker.runOnce();
      if (!mounted) return;

      final errorLines = [
        ...worker.lastCatalogErrors,
        ...worker.lastMatchErrors,
        ...worker.lastBallErrors,
      ];
      final counts =
          'catalog pulled ${worker.lastCatalogDownloaded}, '
          'catalog upload failed ${worker.lastCatalogFailed}, '
          'blocked ${worker.lastCatalogBlocked}; '
          'matches pulled ${worker.lastMatchesDownloaded}; '
          'balls uploaded $synced, failed ${worker.lastBallFailed}; player references repaired ${worker.lastBallReferencesBackfilled}';
      final hasFailures = worker.lastCatalogFailed > 0 ||
          worker.lastBallFailed > 0 ||
          errorLines.isNotEmpty;
      final errorDetail = errorLines.take(3).join(' | ');
      final statusSuffix = errorDetail.isEmpty ? '' : ' | $errorDetail';
      ref.read(automaticSyncStatusProvider.notifier).state = hasFailures
          ? 'Needs attention — $counts$statusSuffix'
          : 'OK — $counts';

      ref.read(catalogSyncRefreshProvider.notifier).state++;
      ref.invalidate(matchProvider);
    } catch (error) {
      if (mounted) {
        ref.read(automaticSyncStatusProvider.notifier).state =
            'Sync failed: $error';
      }
      debugPrint('Automatic Supabase sync failed: $error');
    } finally {
      _running = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
