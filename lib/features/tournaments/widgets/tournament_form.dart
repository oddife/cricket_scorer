import 'package:flutter/material.dart';

import '../../../domain/tournaments/enums/tournament_type.dart';
import 'tournament_type_selector.dart';

class TournamentForm extends StatefulWidget {
  const TournamentForm({required this.onSave, super.key});

  final void Function({
    required String name,
    required TournamentType type,
  }) onSave;

  @override
  State<TournamentForm> createState() => _TournamentFormState();
}

class _TournamentFormState extends State<TournamentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  TournamentType _type = TournamentType.league;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(name: _nameController.text, type: _type);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Tournament name',
              hintText: 'Enter tournament name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter a tournament name';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Text('Tournament type', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TournamentTypeSelector(
            value: _type,
            onChanged: (value) => setState(() => _type = value),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Create Tournament'),
            ),
          ),
        ],
      ),
    );
  }
}