import 'package:flutter/material.dart';

import '../../../domain/scoring/enums/delivery_type.dart';
import '../../../domain/scoring/enums/run_out_end.dart';
import '../../../domain/scoring/enums/wicket_type.dart';
import '../../../domain/scoring/models/delivery_input.dart';
import '../../../domain/scoring/models/wicket_input.dart';

class DeliveryAwareScoringResult {
  const DeliveryAwareScoringResult({
    required this.delivery,
    this.wicketInput,
  });

  final DeliveryInput delivery;
  final WicketInput? wicketInput;
}

class DeliveryAwareWicketDialog {
  const DeliveryAwareWicketDialog._();

  static Future<DeliveryAwareScoringResult?> show({
    required BuildContext context,
    required String Function(int) name,
    required int strikerId,
    required int nonStrikerId,
    required List<int> fielders,
    required List<int> replacements,
    DeliveryType initialDeliveryType = DeliveryType.normal,
  }) {
    return showDialog<DeliveryAwareScoringResult>(
      context: context,
      builder: (dialogContext) => _Dialog(
        name: name,
        strikerId: strikerId,
        nonStrikerId: nonStrikerId,
        fielders: fielders,
        replacements: replacements,
        initialDeliveryType: initialDeliveryType,
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
    required this.initialDeliveryType,
  });

  final String Function(int) name;
  final int strikerId;
  final int nonStrikerId;
  final List<int> fielders;
  final List<int> replacements;
  final DeliveryType initialDeliveryType;

  @override
  State<_Dialog> createState() => _DialogState();
}

class _DialogState extends State<_Dialog> {
  late DeliveryType deliveryType;
  WicketType? type;
  late int dismissed = widget.strikerId;
  int? fielder;
  RunOutEnd? runOutEnd;
  int completedRuns = 0;
  bool crossed = false;
  int? replacement;
  int wideRuns = 1;
  int byeRuns = 1;
  int legByeRuns = 1;
  int noBallExtraRuns = 0;
  int noBallExtraType = 0;

  @override
  void initState() {
    super.initState();
    deliveryType = widget.initialDeliveryType;
    type = null;
  }

  bool get hasWicket => type != null;
  bool get isRunOut => type == WicketType.runOut;
  bool get isNoBall => deliveryType == DeliveryType.noBall;
  bool get isWide => deliveryType == DeliveryType.wide;
  bool get isBye => deliveryType == DeliveryType.bye;
  bool get isLegBye => deliveryType == DeliveryType.legBye;

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
    if (isBye || isLegBye) {
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
      title: Text(hasWicket ? 'Record Wicket' : 'Record Delivery'),
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
                  DropdownMenuItem(value: DeliveryType.bye, child: Text('Bye')),
                  DropdownMenuItem(value: DeliveryType.legBye, child: Text('Leg-Bye')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    deliveryType = value;
                    type = null;
                    fielder = null;
                    runOutEnd = null;
                    completedRuns = 0;
                    crossed = false;
                    wideRuns = 1;
                    byeRuns = 1;
                    legByeRuns = 1;
                    noBallExtraRuns = 0;
                    noBallExtraType = 0;
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
              if (isBye) ...[
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: '$byeRuns',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Bye runs',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => byeRuns = int.tryParse(value) ?? 0,
                ),
              ],
              if (isLegBye) ...[
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: '$legByeRuns',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Leg-bye runs',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => legByeRuns = int.tryParse(value) ?? 0,
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
              DropdownButtonFormField<WicketType?>(
                initialValue: type,
                decoration: const InputDecoration(
                  labelText: 'Wicket (optional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<WicketType?>(
                    value: null,
                    child: Text('No wicket'),
                  ),
                  ...allowedWickets.map(
                    (value) => DropdownMenuItem<WicketType?>(
                      value: value,
                      child: Text(_label(value)),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() {
                  type = value;
                  if (type != WicketType.runOut) {
                    runOutEnd = null;
                    completedRuns = 0;
                    crossed = false;
                  }
                  if (type != WicketType.caught &&
                      type != WicketType.stumped &&
                      type != WicketType.runOut) {
                    fielder = null;
                  }
                }),
              ),
              if (hasWicket && canChooseBatter)
                DropdownButtonFormField<int>(
                  initialValue: dismissed,
                  decoration: const InputDecoration(
                    labelText: 'Dismissed batter',
                    border: OutlineInputBorder(),
                  ),
                  items: [widget.strikerId, widget.nonStrikerId]
                      .map((id) => DropdownMenuItem(
                            value: id,
                            child: Text(widget.name(id)),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() {
                    if (value != null) dismissed = value;
                  }),
                ),
              if (hasWicket && needsFielder) ...[
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
              if (hasWicket && isRunOut) ...[
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
              if (hasWicket) ...[
                const SizedBox(height: 12),
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
          child: Text(hasWicket ? 'Confirm Wicket' : 'Confirm Delivery'),
        ),
      ],
    );
  }

  void _confirm() {
    if (isWide && wideRuns < 1) return;
    if (isBye && byeRuns < 1) return;
    if (isLegBye && legByeRuns < 1) return;
    if (isRunOut && (runOutEnd == null || fielder == null)) return;
    if (needsFielderFor(type) && fielder == null) return;
    if (isNoBall && noBallExtraRuns < 0) return;

    final wicketInput = type == null
        ? null
        : WicketInput(
            type: type!,
            dismissedPlayerId: dismissed,
            fielderId: fielder,
            runOutEnd: runOutEnd,
            completedRuns: completedRuns,
            crossedBeforeWicket: crossed,
            replacementBatterId: replacement,
            deliveryType: deliveryType,
            batterRuns: isNoBall && noBallExtraType == 1 ? noBallExtraRuns : 0,
            byeRuns: isBye ? byeRuns : (isNoBall && noBallExtraType == 2 ? noBallExtraRuns : 0),
            legByeRuns: isLegBye ? legByeRuns : (isNoBall && noBallExtraType == 3 ? noBallExtraRuns : 0),
            wideRuns: isWide ? wideRuns : 0,
            noBallRuns: isNoBall ? 1 : 0,
          );

    final delivery = DeliveryInput(
      deliveryType: deliveryType,
      batterRuns: isNoBall && noBallExtraType == 1 ? noBallExtraRuns : 0,
      byeRuns: isBye ? byeRuns : (isNoBall && noBallExtraType == 2 ? noBallExtraRuns : 0),
      legByeRuns: isLegBye ? legByeRuns : (isNoBall && noBallExtraType == 3 ? noBallExtraRuns : 0),
      wideRuns: isWide ? wideRuns : 0,
      noBallRuns: isNoBall ? 1 : 0,
    );

    Navigator.pop(
      context,
      DeliveryAwareScoringResult(
        delivery: delivery,
        wicketInput: wicketInput,
      ),
    );
  }

  bool needsFielderFor(WicketType? value) =>
      value == WicketType.caught ||
      value == WicketType.runOut ||
      value == WicketType.stumped;

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
