import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/matches/enums/toss_decision.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/match_setup_provider.dart';

class NormalMatchSetupScreen extends ConsumerStatefulWidget {
  const NormalMatchSetupScreen({super.key});
  @override
  ConsumerState<NormalMatchSetupScreen> createState() => _NormalMatchSetupScreenState();
}

class _NormalMatchSetupScreenState extends ConsumerState<NormalMatchSetupScreen> {
  late final TextEditingController _name;
  late final TextEditingController _venue;
  @override
  void initState() {
    super.initState();
    final s = ref.read(matchSetupProvider);
    _name = TextEditingController(text: s.name)..addListener(() => ref.read(matchSetupProvider.notifier).setName(_name.text));
    _venue = TextEditingController(text: s.venue)..addListener(() => ref.read(matchSetupProvider.notifier).setVenue(_venue.text));
  }
  @override
  void dispose() { _name.dispose(); _venue.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(matchSetupProvider);
    final teams = ref.watch(teamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Normal Match Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Card(title: 'Match Details', icon: Icons.info_outline, children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Match name', hintText: 'e.g. Sunday League Final')),
            const SizedBox(height: 16),
            TextField(controller: _venue, decoration: const InputDecoration(labelText: 'Venue', hintText: 'Optional')),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_today_outlined), title: const Text('Match date'), subtitle: Text(_date(s.date)), onTap: () async { final d = await showDatePicker(context: context, initialDate: s.date ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d != null) ref.read(matchSetupProvider.notifier).setDate(d); }),
          ]),
          const SizedBox(height: 16),
          _Card(title: 'Match Format', icon: Icons.tune, children: [
            DropdownButtonFormField<int>(initialValue: s.inningsCount, decoration: const InputDecoration(labelText: 'Number of innings'), items: const [DropdownMenuItem(value: 2, child: Text('2 innings')), DropdownMenuItem(value: 4, child: Text('4 innings'))], onChanged: (v) { if (v != null) ref.read(matchSetupProvider.notifier).setInningsCount(v); }),
            const SizedBox(height: 16),
            _NumberField(label: 'Overs per innings', value: s.oversPerInnings, onChanged: ref.read(matchSetupProvider.notifier).setOversPerInnings),
            const SizedBox(height: 16),
            _NumberField(label: 'Players per team', value: s.playersPerTeam, onChanged: ref.read(matchSetupProvider.notifier).setPlayersPerTeam),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('2-Bowler Mode'), subtitle: const Text('Two bowlers alternate every legal delivery'), value: s.twoBowlerMode, onChanged: ref.read(matchSetupProvider.notifier).setTwoBowlerMode),
          ]),
          const SizedBox(height: 16),
          _Card(title: 'Teams', icon: Icons.groups_outlined, children: [teams.when(loading: () => const LinearProgressIndicator(), error: (e, _) => Text('Unable to load teams: $e'), data: (items) => Column(children: [_TeamDropdown(label: 'Team A', value: s.teamAId, teams: items, onChanged: ref.read(matchSetupProvider.notifier).setTeamA), const SizedBox(height: 16), _TeamDropdown(label: 'Team B', value: s.teamBId, teams: items, onChanged: ref.read(matchSetupProvider.notifier).setTeamB), if (items.isEmpty) const Padding(padding: EdgeInsets.only(top: 12), child: Text('No teams yet. Create them from Management → Teams.'))]))]),
          const SizedBox(height: 16),
          _Card(title: 'Toss', icon: Icons.monetization_on_outlined, children: [
            _TeamDropdown(label: 'Toss winner', value: s.tossWinnerTeamId, teams: teams.value ?? const [], onChanged: ref.read(matchSetupProvider.notifier).setTossWinner),
            const SizedBox(height: 16),
            SegmentedButton<TossDecision>(segments: const [ButtonSegment(value: TossDecision.bat, label: Text('Bat')), ButtonSegment(value: TossDecision.bowl, label: Text('Bowl'))], selected: s.tossDecision == null ? <TossDecision>{} : {s.tossDecision!}, emptySelectionAllowed: true, onSelectionChanged: (v) { if (v.isNotEmpty) ref.read(matchSetupProvider.notifier).setTossDecision(v.first); }),
          ]),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: () { final error = ref.read(matchSetupProvider.notifier).validate(); if (error != null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error))); return; } context.push('/matches/normal/playing-xi'); }, icon: const Icon(Icons.arrow_forward), label: const Text('Continue to Playing XI')),
        ]))),
      ),
    );
  }
  String _date(DateTime? d) => d == null ? 'Select date' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.label, required this.value, required this.onChanged});
  final String label; final int value; final ValueChanged<int> onChanged;
  @override Widget build(BuildContext context) => TextFormField(initialValue: '$value', keyboardType: TextInputType.number, decoration: InputDecoration(labelText: label), onChanged: (v) { final n = int.tryParse(v); if (n != null) onChanged(n); });
}

class _TeamDropdown extends StatelessWidget {
  const _TeamDropdown({required this.label, required this.value, required this.teams, required this.onChanged});
  final String label; final int? value; final List<dynamic> teams; final ValueChanged<int> onChanged;
  @override Widget build(BuildContext context) => DropdownButtonFormField<int>(initialValue: teams.any((t) => t.id == value) ? value : null, decoration: InputDecoration(labelText: label), items: [for (final team in teams) DropdownMenuItem<int>(value: team.id as int, child: Text(team.name as String))], onChanged: (v) { if (v != null) onChanged(v); });
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.icon, required this.children});
  final String title; final IconData icon; final List<Widget> children;
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon), const SizedBox(width: 10), Text(title, style: Theme.of(context).textTheme.titleLarge)]), const SizedBox(height: 20), ...children])));
}
