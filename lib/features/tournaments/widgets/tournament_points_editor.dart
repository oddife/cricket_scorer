import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../domain/tournaments/models/tournament_points_rules.dart';
import '../providers/tournament_provider.dart';

class TournamentPointsEditor extends StatefulWidget {
  const TournamentPointsEditor({required this.rules, super.key});

  final TournamentPointsRules rules;

  @override
  State<TournamentPointsEditor> createState() => _TournamentPointsEditorState();
}

class _TournamentPointsEditorState extends State<TournamentPointsEditor> {
  late final TextEditingController _win;
  late final TextEditingController _tie;
  late final TextEditingController _noResult;
  late final TextEditingController _loss;

  @override
  void initState() {
    super.initState();
    _win = TextEditingController(text: '${widget.rules.winPoints}');
    _tie = TextEditingController(text: '${widget.rules.tiePoints}');
    _noResult = TextEditingController(text: '${widget.rules.noResultPoints}');
    _loss = TextEditingController(text: '${widget.rules.lossPoints}');
  }

  @override
  void dispose() {
    _win.dispose();
    _tie.dispose();
    _noResult.dispose();
    _loss.dispose();
    super.dispose();
  }

  int? _value(TextEditingController controller) => int.tryParse(controller.text.trim());

  Future<void> _save() async {
    final values = [_value(_win), _value(_tie), _value(_noResult), _value(_loss)];
    if (values.any((value) => value == null || value < 0 || value > 99)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter whole-number points from 0 to 99.')),
      );
      return;
    }

    final rules = widget.rules.copyWith(
      winPoints: values[0]!,
      tiePoints: values[1]!,
      noResultPoints: values[2]!,
      lossPoints: values[3]!,
    );

    try {
      final container = ProviderScope.containerOf(context, listen: false);
      await container.read(tournamentPointsRepositoryProvider).save(rules);
      container.invalidate(tournamentPointsRulesProvider(widget.rules.tournamentId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Points rules saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save points rules: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Defaults: Win 2 / Tie 1 / No Result 1 / Loss 0.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _PointsField(label: 'Win', controller: _win),
                _PointsField(label: 'Tie', controller: _tie),
                _PointsField(label: 'No Result', controller: _noResult),
                _PointsField(label: 'Loss', controller: _loss),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Points Rules'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointsField extends StatelessWidget {
  const _PointsField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, suffixText: 'pts'),
      ),
    );
  }
}
