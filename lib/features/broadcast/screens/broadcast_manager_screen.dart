import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/broadcast_snapshot.dart';
import '../providers/broadcast_server_controller_provider.dart';
import '../providers/broadcast_state_provider.dart';
import '../state/broadcast_state_coordinator.dart';

class BroadcastManagerScreen extends ConsumerStatefulWidget {
  const BroadcastManagerScreen({super.key});

  @override
  ConsumerState<BroadcastManagerScreen> createState() =>
      _BroadcastManagerScreenState();
}

class _BroadcastManagerScreenState
    extends ConsumerState<BroadcastManagerScreen> {
  final _tickerController = TextEditingController();
  final _tickerDurationController = TextEditingController(text: '12');
  final _lowerTitleController = TextEditingController();
  final _lowerDetailController = TextEditingController();
  final _lowerDurationController = TextEditingController(text: '8');
  final _eventDetailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final server = ref.read(broadcastServerControllerProvider);
      if (server.isSupported && !server.isRunning) {
        unawaited(server.start());
      }
    });
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _tickerDurationController.dispose();
    _lowerTitleController.dispose();
    _lowerDetailController.dispose();
    _lowerDurationController.dispose();
    _eventDetailController.dispose();
    super.dispose();
  }

  Future<void> _copy(String value, {required String label}) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard.')),
    );
  }

  int _duration(TextEditingController controller, int fallback) {
    final parsed = int.tryParse(controller.text.trim()) ?? fallback;
    return parsed.clamp(1, 120).toInt();
  }

  void _sendTicker(BroadcastStateCoordinator coordinator) {
    coordinator.showTicker(
      _tickerController.text,
      duration: Duration(seconds: _duration(_tickerDurationController, 12)),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ticker sent to browser sources.')),
    );
  }

  void _sendLowerThird(BroadcastStateCoordinator coordinator) {
    final title = _lowerTitleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a lower-third title first.')),
      );
      return;
    }
    coordinator.showLowerThird(
      title: title,
      detail: _lowerDetailController.text,
      duration: Duration(seconds: _duration(_lowerDurationController, 8)),
    );
  }

  void _showEvent(BroadcastStateCoordinator coordinator, String kind) {
    final detail = _eventDetailController.text.trim();
    if (kind == 'CUSTOM' && detail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a custom event message first.')),
      );
      return;
    }
    coordinator.triggerEvent(
      kind: kind,
      detail: detail.isEmpty ? null : detail,
    );
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = ref.watch(broadcastStateCoordinatorProvider);
    final server = ref.watch(broadcastServerControllerProvider);
    final snapshot = coordinator.snapshot;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast Manager'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ServerStatusCard(
                server: server,
                onStart: server.isStarting ? null : () => unawaited(server.start()),
                onStop: server.isRunning ? () => unawaited(server.stop()) : null,
                onCopy: _copy,
              ),
              const SizedBox(height: 16),
              _MatchPreviewCard(snapshot: snapshot),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 850;
                  final visibility = _VisibilityCard(coordinator: coordinator);
                  final events = _EventCard(
                    detailController: _eventDetailController,
                    onShow: (kind) => _showEvent(coordinator, kind),
                    onClear: coordinator.clearEvent,
                  );
                  final ticker = _TickerCard(
                    textController: _tickerController,
                    durationController: _tickerDurationController,
                    onSend: () => _sendTicker(coordinator),
                    onClear: coordinator.clearTicker,
                  );
                  final lower = _LowerThirdCard(
                    titleController: _lowerTitleController,
                    detailController: _lowerDetailController,
                    durationController: _lowerDurationController,
                    onSend: () => _sendLowerThird(coordinator),
                    onClear: coordinator.clearLowerThird,
                  );

                  if (!wide) {
                    return Column(
                      children: [
                        visibility,
                        const SizedBox(height: 12),
                        events,
                        const SizedBox(height: 12),
                        ticker,
                        const SizedBox(height: 12),
                        lower,
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: visibility),
                          const SizedBox(width: 12),
                          Expanded(child: events),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: ticker),
                          const SizedBox(width: 12),
                          Expanded(child: lower),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Graphics are presentation-only. They read local scoring state and never record deliveries. '
                'When taking over scoring from Android, stop scoring there first to avoid competing event sequences.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServerStatusCard extends StatelessWidget {
  const _ServerStatusCard({
    required this.server,
    required this.onStart,
    required this.onStop,
    required this.onCopy,
  });

  final BroadcastServerController server;
  final VoidCallback? onStart;
  final VoidCallback? onStop;
  final Future<void> Function(String value, {required String label}) onCopy;

  Uri? _atPath(String path) => server.baseUri?.replace(path: path);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRunning = server.isRunning;
    final baseUri = server.baseUri;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isRunning ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  color: isRunning
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Local broadcast server',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(
                        !server.isSupported
                            ? 'Native Windows app required'
                            : server.isStarting
                                ? 'Starting server…'
                                : isRunning
                                    ? 'Running · loopback only'
                                    : 'Stopped',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isRunning)
                  OutlinedButton.icon(
                    onPressed: onStop,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Stop'),
                  )
                else
                  FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start server'),
                  ),
              ],
            ),
            if (server.error != null) ...[
              const SizedBox(height: 10),
              Text(
                server.error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            if (isRunning && baseUri != null) ...[
              const Divider(height: 28),
              _UrlRow(
                title: 'Browser Manager fallback',
                url: _atPath('/broadcast/manage')!,
                onCopy: onCopy,
              ),
              const SizedBox(height: 4),
              _UrlRow(
                title: 'Health check',
                url: _atPath('/healthz')!,
                onCopy: onCopy,
              ),
              const SizedBox(height: 4),
              Text(
                'The server listens on 127.0.0.1. OBS/vMix browser sources on this PC can connect; other computers cannot connect by default.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (server.isSupported) ...[
              const SizedBox(height: 8),
              Text(
                'Opening this manager starts the local browser-source server. If port 3113 is occupied, the app tries ports 3114–3118 and displays the actual URLs here.',
                style: theme.textTheme.bodySmall,
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'The Windows loopback server is not started on Android or Flutter Web.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UrlRow extends StatelessWidget {
  const _UrlRow({
    required this.title,
    required this.url,
    required this.onCopy,
  });

  final String title;
  final Uri url;
  final Future<void> Function(String value, {required String label}) onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              SelectableText(url.toString()),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Copy $title URL',
          onPressed: () => unawaited(onCopy(url.toString(), label: title)),
          icon: const Icon(Icons.copy_outlined),
        ),
      ],
    );
  }
}

class _MatchPreviewCard extends StatelessWidget {
  const _MatchPreviewCard({required this.snapshot});

  final BroadcastSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final snap = snapshot;
    final ready = snap?.ready == true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.scoreboard_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    snap?.matchName ?? 'Match preview',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(ready ? snap!.matchStatus : 'Waiting for match'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!ready)
              Text(
                'Start a match in Scoring. The Broadcast Manager reads the current local match snapshot.',
                style: theme.textTheme.bodyMedium,
              )
            else ...[
              Text(
                '${snap!.battingTeamName ?? 'Batting'}  vs  ${snap.bowlingTeamName ?? 'Bowling'}',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 3),
              Text(
                '${snap.runs}/${snap.wickets}',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
              Text(
                'Overs ${snap.oversText}   •   Innings ${snap.inningsNumber}',
                style: theme.textTheme.bodyMedium,
              ),
              if (snap.target != null)
                Text(
                  'Target ${snap.target}  •  ${snap.runsRequired ?? '—'} needed  •  ${snap.ballsRemaining ?? '—'} balls remaining',
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final ball in snap.currentOver)
                    Chip(
                      label: Text(ball.label),
                      backgroundColor: ball.isWicket
                          ? colors.errorContainer
                          : ball.totalRuns == 4 || ball.totalRuns == 6
                              ? colors.primaryContainer
                              : colors.surfaceContainerHighest,
                    ),
                ],
              ),
            ],
            const Divider(height: 28),
            Text(
              'Sync telemetry: ${snap?.lastSyncAt == null ? 'last-sync timestamp not connected yet' : snap!.lastSyncAt!.toLocal().toString()} · '
              'source: ${snap?.scoringSource == BroadcastScoringSource.unknown ? 'not identified yet' : snap!.scoringSource.wireValue}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityCard extends StatelessWidget {
  const _VisibilityCard({required this.coordinator});

  final BroadcastStateCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const labels = {
      BroadcastOverlay.scorecard: 'Scorecard',
      BroadcastOverlay.ticker: 'Ticker',
      BroadcastOverlay.lowerThird: 'Lower third',
      BroadcastOverlay.lastBall: 'Last-ball / event graphic',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Graphic visibility', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final overlay in BroadcastOverlay.values)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(labels[overlay]!),
                value: coordinator.isOverlayEnabled(overlay),
                onChanged: (enabled) =>
                    coordinator.setOverlayEnabled(overlay, enabled),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => coordinator.setAllOverlaysEnabled(false),
                  icon: const Icon(Icons.visibility_off_outlined),
                  label: const Text('Hide all'),
                ),
                FilledButton.icon(
                  onPressed: () => coordinator.setAllOverlaysEnabled(true),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Show all'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.detailController,
    required this.onShow,
    required this.onClear,
  });

  final TextEditingController detailController;
  final ValueChanged<String> onShow;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event graphic', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: detailController,
              maxLength: 180,
              decoration: const InputDecoration(
                labelText: 'Optional player/detail text',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => onShow('FOUR'),
                  child: const Text('FOUR'),
                ),
                FilledButton(
                  onPressed: () => onShow('SIX'),
                  child: const Text('SIX'),
                ),
                FilledButton.tonal(
                  onPressed: () => onShow('WICKET'),
                  child: const Text('WICKET'),
                ),
                OutlinedButton(
                  onPressed: () => onShow('CUSTOM'),
                  child: const Text('Custom'),
                ),
                TextButton(
                  onPressed: onClear,
                  child: const Text('Clear event'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TickerCard extends StatelessWidget {
  const _TickerCard({
    required this.textController,
    required this.durationController,
    required this.onSend,
    required this.onClear,
  });

  final TextEditingController textController;
  final TextEditingController durationController;
  final VoidCallback onSend;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manual ticker', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: textController,
              maxLength: 280,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ticker message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            _DurationField(controller: durationController),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onSend,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Send ticker'),
                ),
                OutlinedButton(
                  onPressed: onClear,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LowerThirdCard extends StatelessWidget {
  const _LowerThirdCard({
    required this.titleController,
    required this.detailController,
    required this.durationController,
    required this.onSend,
    required this.onClear,
  });

  final TextEditingController titleController;
  final TextEditingController detailController;
  final TextEditingController durationController;
  final VoidCallback onSend;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Player lower-third', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Title / player name',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: detailController,
              maxLength: 180,
              decoration: const InputDecoration(
                labelText: 'Detail',
                hintText: '48 off 32 balls · Kings',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            _DurationField(controller: durationController),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onSend,
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Show lower-third'),
                ),
                OutlinedButton(
                  onPressed: onClear,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationField extends StatelessWidget {
  const _DurationField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 150,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Seconds (1–120)',
            border: OutlineInputBorder(),
          ),
        ),
      );
}
