import 'package:flutter/material.dart';

import '../../../domain/scoring/enums/delivery_type.dart';
import '../../../domain/scoring/enums/run_out_end.dart';
import '../../../domain/scoring/enums/wicket_type.dart';
import '../../../domain/scoring/models/wicket_input.dart';

class DeliveryAwareWicketDialog {
  const DeliveryAwareWicketDialog._();

  static Future<WicketInput?> show({
    required BuildContext context,
    required String Function(int) name,
    required int strikerId,
    required int nonStrikerId,
    required List<int> fielders,
    required List<int> replacements,
  }) {
    return showDialog<WicketInput>(
      context: context,
      builder: (dialogContext) => _Dialog(
        name: name,
        strikerId: strikerId,
        nonStrikerId: nonStrikerId,
        fielders: fielders,
        replacements: replacements,
      ),
    );
  }
}

class _Dialog extends StatefulWidget {
  const _Dialog({
    required this.name,
    required this.strikerId,
    required this.nonStrikerId,
    required this.fielders,
    required this.replacements,
  });

  final String Function(int) name;
  final int strikerId;
  final int nonStrikerId;
  final List<int> fielders;
  final List<int> replacements;

  @override
  State<_Dialog> createState() => _DialogState();
}

class _DialogState extends State<_Dialog> {
  DeliveryType deliveryType = DeliveryType.normal;
  WicketType type = WicketType.bowled;
  late int dismissed = widget.strikerId;
  int? fielder;
  RunOutEnd? runOutEnd;
  int completedRuns = 0;
  bool crossed = false;
  int? replacement;
  int wideRuns = 1;
  int noBallExtraRuns = 0;
  int noBallExtraType = 0; // 0 none, 1 bat, 2 bye, 3 leg-bye

  bool get isRunOut => type == WicketType.runOut;
  bool get isNoBall => deliveryType == DeliveryType.noBall;
  bool get isWide => deliveryType == DeliveryType.wide;

  List<WicketType> get allowedWickets {
    if (isNoBall) {
      return const [WicketType.runOut, WicketType.obstructingField];
    }
    if (isWide) {
      return const [
        WicketType.stumped,
        WicketType.runOut,
        WicketType.hitWicket,
        WicketType.obstructingField,
      ];
    }
    return const [
      WicketType.bowled,
      WicketType.caught,
      WicketType.lbw,
      WicketType.runOut,
      WicketType.stumped,
      WicketType.hitWicket,
      WicketType.obstructingField,
      WicketType.overFence,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final needsFielder = type == WicketType.caught ||
        type == WicketType.runOut ||
        type == WicketType.stumped;
    final canChooseBatter = isRunOut || type == WicketType.obstructingField;

    return AlertDialog(
      title: const Text('Record Wicket'),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<DeliveryType>(
                initialValue: deliveryType,
                decoration: const InputDecoration(
                  labelText: 'Delivery',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: DeliveryType.normal, child: Text('Normal')),
                  DropdownMenuItem(value: DeliveryType.wide, child: Text('Wide')),
                  DropdownMenuItem(value: DeliveryType.noBall, child: Text('No-Ball')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    deliveryType = value;
                    final allowed = allowedWickets;
                    if (!allowed.contains(type)) type = allowed.first;
                    if (!isRunOut) {
                      runOutEnd = null;
                      completedRuns = 0;
                      crossed = false;
                    }
                    if (!isWide) wideRuns = 1;
                  });
                },
              ),
              if (isWide) ...[
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: '$wideRuns',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total wide runs',
                    helperText: 'Includes the one-run wide penalty and any additional wide runs.',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => wideRuns = int.tryParse(value) ?? 0,
                ),
              ],
              if (isNoBall) ...[
                const SizedBox(height: 12),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('No-ball penalty'),
                  trailing: Text('+1'),
                  subtitle: Text('The one-run no-ball penalty is fixed.'),
                ),
                DropdownButtonFormField<int>(
                  initialValue: noBallExtraType,
                  decoration: const InputDecoration(
                    labelText: 'Additional runs',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('No additional runs')),
                    DropdownMenuItem(value: 1, child: Text('Bat runs')),
                    DropdownMenuItem(value: 2, child: Text('Bye runs')),
                    DropdownMenuItem(value: 3, child: Text('Leg-bye runs')),
                  ],
                  onChanged: (value) => setState(() => noBallExtraType = value ?? 0),
                ),
                if (noBallExtraType != 0) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: '$noBallExtraRuns',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Additional runs',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => noBallExtraRuns = int.tryParse(value) ?? 0,
                  ),
                ],
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<WicketType>(
                initialValue: type,
                decoration: const InputDecoration(
                  labelText: 'Dismissal',
                  border: OutlineInputBorder(),
                ),
                items: allowedWickets
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(_label(value)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() {
                  if (value != null) {
                    type = value;
                    if (type != WicketType.runOut) {
                      runOutEnd = null;
                      completedRuns = 0;
                      crossed = false;
                    }
                    if (type != WicketType.caught && type != WicketType.stumped) {
                      fielder = null;
                    }
                  }
                }),
              ),
              const SizedBox(height: 12),
              if (canChooseBatter)
                DropdownButtonFormField<int>(
                  initialValue: dismissed,
                  decoration: const InputDecoration(
                    labelText: 'Dismissed batter',
                    border: OutlineInputBorder(),
                  ),
                  items: [widget.strikerId, widget.nonStrikerId]
                      .map((id) => DropdownMenuItem(value: id, child: Text(widget.name(id))))
                      .toList(),
                  onChanged: (value) => setState(() {
                    if (value != null) dismissed = value;
                  }),
                ),
              if (needsFielder) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: fielder,
                  decoration: const InputDecoration(
                    labelText: 'Fielder / wicketkeeper',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.fielders
                      .map((id) => DropdownMenuItem(value: id, child: Text(widget.name(id))))
                      .toList(),
                  onChanged: (value) => setState(() => fielder = value),
                ),
              ],
              if (isRunOut) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<RunOutEnd>(
                  initialValue: runOutEnd,
                  decoration: const InputDecoration(
                    labelText: 'Wicket broken at',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: RunOutEnd.striker, child: Text("Striker's End")),
                    DropdownMenuItem(value: RunOutEnd.nonStriker, child: Text("Non-Striker's End")),
                  ],
                  onChanged: (value) => setState(() => runOutEnd = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: completedRuns,
                  decoration: const InputDecoration(
                    labelText: 'Completed runs',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(7, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
                  onChanged: (value) => setState(() => completedRuns = value ?? 0),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Crossed before wicket was broken'),
                  value: crossed,
                  onChanged: (value) => setState(() => crossed = value),
                ),
              ],
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                initialValue: replacement,
                decoration: const InputDecoration(
                  labelText: 'Replacement batter',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Select later')),
                  ...widget.replacements.map((id) => DropdownMenuItem<int?>(
                        value: id,
                        child: Text(widget.name(id)),
                      )),
                ],
                onChanged: (value) => setState(() => replacement = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Confirm Wicket'),
        ),
      ],
    );
  }

  void _confirm() {
    if (isWide && wideRuns < 1) return;
    if (isRunOut && (runOutEnd == null || fielder == null)) return;
    if (noBallExtraRuns < 0 || wideRuns < 1) return;

    Navigator.pop(
      context,
      WicketInput(
        type: type,
        dismissedPlayerId: dismissed,
        fielderId: fielder,
        runOutEnd: runOutEnd,
        completedRuns: completedRuns,
        crossedBeforeWicket: crossed,
        replacementBatterId: replacement,
        deliveryType: deliveryType,
        batterRuns: isNoBall && noBallExtraType == 1 ? noBallExtraRuns : 0,
        byeRuns: isNoBall && noBallExtraType == 2 ? noBallExtraRuns : 0,
        legByeRuns: isNoBall && noBallExtraType == 3 ? noBallExtraRuns : 0,
        wideRuns: isWide ? wideRuns : 0,
        noBallRuns: isNoBall ? 1 : 0,
      ),
    );
  }

  static String _label(WicketType type) => switch (type) {
        WicketType.bowled => 'Bowled',
        WicketType.caught => 'Caught',
        WicketType.lbw => 'LBW',
        WicketType.runOut => 'Run Out',
        WicketType.stumped => 'Stumped',
        WicketType.hitWicket => 'Hit Wicket',
        WicketType.retired => 'Retired',
        WicketType.obstructingField => 'Obstructing the Field',
        WicketType.overFence => 'Over Fence',
      };
}
