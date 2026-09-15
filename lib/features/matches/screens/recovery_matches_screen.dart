import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/sync/supabase_recovery_importer_provider.dart';
import '../providers/recovery_provider.dart';

class RecoveryMatchesScreen extends ConsumerWidget {
  const RecoveryMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(remoteMatchesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recover Match'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(remoteMatchesProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: matches.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Message(
          icon: Icons.cloud_off_outlined,
          message: _friendlyError(error),
          action: TextButton(
            onPressed: () => ref.invalidate(remoteMatchesProvider),
            child: const Text('Retry'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _Message(
              icon: Icons.cloud_done_outlined,
              message: 'No synchronized matches are available for recovery.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final row = items[index];
              return _RemoteMatchTile(row: row);
            },
          );
        },
      ),
    );
  }

  static String _friendlyError(Object error) {
    final text = error.toString();
    return text.startsWith('StateError: ')
        ? text.substring('StateError: '.length)
        : 'Unable to load synchronized matches: $text';
  }
}

class _RemoteMatchTile extends ConsumerStatefulWidget {
  const _RemoteMatchTile({required this.row});
  final Map<String, dynamic> row;

  @override
  ConsumerState<_RemoteMatchTile> createState() => _RemoteMatchTileState();
}

class _RemoteMatchTileState extends ConsumerState<_RemoteMatchTile> {
  bool _busy = false;

  Future<void> _recover() async {
    final syncId = widget.row['sync_id'] as String?;
    if (syncId == null || syncId.isEmpty) {
      _showError('This synchronized match has no sync ID and cannot be recovered.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recover match?'),
        content: const Text(
          'The complete synchronized match will be reconciled into local SQLite. '
          'Existing matching data is kept; divergent local data will stop the recovery. '
          'Nothing will be overwritten blindly.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Recover')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final snapshot = await ref.read(supabaseRecoveryTransportProvider).pullMatch(syncId);
      final localMatchId = await ref.read(supabaseRecoveryImporterProvider).importMatch(snapshot);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match recovered successfully.')),
      );
      ref.invalidate(remoteMatchesProvider);
      context.go('/matches/$localMatchId/live');
    } catch (error) {
      if (mounted) _showError(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  static String _friendlyError(Object error) {
    final text = error.toString();
    return text.startsWith('StateError: ')
        ? text.substring('StateError: '.length)
        : 'Recovery failed: $text';
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final name = row['name'] as String? ?? 'Unnamed match';
    final venue = row['venue'] as String?;
    final status = _status(row['status']);
    final updated = _date(row['updated_at']);
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.cloud_download_outlined)),
        title: Text(name),
        subtitle: Text([
          if (venue != null && venue.isNotEmpty) venue,
          status,
          if (updated != null) 'Updated $updated',
        ].join('  |  ')),
        trailing: _busy
            ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5))
            : FilledButton.icon(
                onPressed: _recover,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Recover'),
              ),
        onTap: _busy ? null : _recover,
      ),
    );
  }

  static String _status(Object? value) {
    switch (value) {
      case 0:
        return 'Setup';
      case 1:
        return 'Live';
      case 2:
        return 'Completed';
      case 3:
        return 'Abandoned';
      default:
        return 'Unknown status';
    }
  }

  static String? _date(Object? value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return null;
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.message, this.action});
  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              if (action != null) ...[const SizedBox(height: 12), action!],
            ],
          ),
        ),
      );
}
