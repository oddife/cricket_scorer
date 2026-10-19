import 'package:flutter/material.dart';

import '../../../domain/scoring/enums/delivery_type.dart';
import '../../../domain/scoring/enums/run_out_end.dart';
import '../../../domain/scoring/enums/wicket_type.dart';
import '../../../domain/scoring/models/delivery_input.dart';
import '../../../domain/scoring/models/wicket_input.dart';
import '../../../domain/scoring/services/wicket_workflow_service.dart';

class DeliveryWicketDialog {
  static Future<DeliveryInput?> show({
    required BuildContext context,
    required String Function(int) name,
    required DeliveryType deliveryType,
    required int strikerId,
    required int nonStrikerId,
    required List<int> fielders,
    required List<int> replacements,
  }) {
    return showDialog<DeliveryInput>(
      context: context,
      builder: (_) => _Dialog(
        name: name,
        deliveryType: deliveryType,
        strikerId: strikerId,
        nonStrikerId: nonStrikerId,
        fielders: fielders,
        replacements: replacements,
      ),
    );
  }
}

class _Dialog extends StatefulWidget {
  const _Dialog({required this.name, required this.deliveryType, required this.strikerId, required this.nonStrikerId, required this.fielders, required this.replacements});
  final String Function(int) name;
  final DeliveryType deliveryType;
  final int strikerId;
  final int nonStrikerId;
  final List<int> fielders;
  final List<int> replacements;
  @override State<_Dialog> createState() => _DialogState();
}

class _DialogState extends State<_Dialog> {
  late DeliveryType deliveryType = widget.deliveryType;
  int runs = 1;
  int noBallExtraType = 0;
  int noBallExtraRuns = 0;
  bool wicket = false;
  WicketType wicketType = WicketType.runOut;
  int dismissed = 0;
  int? fielder;
  RunOutEnd? runOutEnd;
  int completedRuns = 0;
  bool crossed = false;
  int? replacement;

  @override
  void initState() { super.initState(); dismissed = widget.strikerId; }

  List<WicketType> get allowedWickets => switch (deliveryType) {
    DeliveryType.wide => const [WicketType.stumped, WicketType.runOut, WicketType.hitWicket, WicketType.obstructingField],
    DeliveryType.noBall => const [WicketType.runOut, WicketType.obstructingField],
    DeliveryType.bye || DeliveryType.legBye => const [WicketType.stumped, WicketType.runOut, WicketType.hitWicket, WicketType.obstructingField],
    DeliveryType.normal => const [WicketType.bowled, WicketType.caught, WicketType.lbw, WicketType.runOut, WicketType.stumped, WicketType.hitWicket, WicketType.obstructingField, WicketType.overFence],
  };

  @override
  Widget build(BuildContext context) {
    final needsFielder = wicketType == WicketType.caught || wicketType == WicketType.runOut || wicketType == WicketType.stumped;
    return AlertDialog(
      title: Text('${_labelDelivery(deliveryType)} Delivery'),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (deliveryType == DeliveryType.wide || deliveryType == DeliveryType.bye || deliveryType == DeliveryType.legBye)
            TextFormField(initialValue: '1', keyboardType: TextInputType.number, decoration: InputDecoration(labelText: deliveryType == DeliveryType.wide ? 'Total wide runs' : 'Total ${deliveryType == DeliveryType.bye ? 'bye' : 'leg-bye'} runs', border: const OutlineInputBorder()), onChanged: (v) => runs = int.tryParse(v) ?? 0),
          if (deliveryType == DeliveryType.noBall) ...[
            const ListTile(contentPadding: EdgeInsets.zero, title: Text('No-ball penalty'), trailing: Text('+1')),
            DropdownButtonFormField<int>(initialValue: noBallExtraType, decoration: const InputDecoration(labelText: 'Additional runs', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 0, child: Text('None')), DropdownMenuItem(value: 1, child: Text('Bat runs')), DropdownMenuItem(value: 2, child: Text('Bye runs')), DropdownMenuItem(value: 3, child: Text('Leg-bye runs'))], onChanged: (v) => setState(() => noBallExtraType = v ?? 0)),
            if (noBallExtraType != 0) TextFormField(initialValue: '0', keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Additional runs', border: OutlineInputBorder()), onChanged: (v) => noBallExtraRuns = int.tryParse(v) ?? 0),
          ],
          const SizedBox(height: 12),
          SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('No wicket')), ButtonSegment(value: true, label: Text('Wicket'))], selected: {wicket}, onSelectionChanged: (v) => setState(() => wicket = v.first)),
          if (wicket) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<WicketType>(initialValue: wicketType, decoration: const InputDecoration(labelText: 'Dismissal', border: OutlineInputBorder()), items: allowedWickets.map((t) => DropdownMenuItem(value: t, child: Text(_labelWicket(t)))).toList(), onChanged: (v) => setState(() { if (v != null) wicketType = v; })),
            if (wicketType == WicketType.runOut || wicketType == WicketType.obstructingField)
              DropdownButtonFormField<int>(initialValue: dismissed, decoration: const InputDecoration(labelText: 'Dismissed batter', border: OutlineInputBorder()), items: [widget.strikerId, widget.nonStrikerId].map((id) => DropdownMenuItem(value: id, child: Text(widget.name(id)))).toList(), onChanged: (v) => setState(() { if (v != null) dismissed = v; })),
            if (needsFielder) DropdownButtonFormField<int>(initialValue: fielder, decoration: const InputDecoration(labelText: 'Fielder / wicketkeeper', border: OutlineInputBorder()), items: widget.fielders.map((id) => DropdownMenuItem(value: id, child: Text(widget.name(id)))).toList(), onChanged: (v) => setState(() => fielder = v)),
            if (wicketType == WicketType.runOut) ...[
              DropdownButtonFormField<RunOutEnd>(initialValue: runOutEnd, decoration: const InputDecoration(labelText: 'Wicket broken at', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: RunOutEnd.striker, child: Text("Striker's End")), DropdownMenuItem(value: RunOutEnd.nonStriker, child: Text("Non-Striker's End"))], onChanged: (v) => setState(() => runOutEnd = v)),
              DropdownButtonFormField<int>(initialValue: completedRuns, decoration: const InputDecoration(labelText: 'Completed runs', border: OutlineInputBorder()), items: List.generate(8, (i) => DropdownMenuItem(value: i, child: Text('$i'))), onChanged: (v) => setState(() => completedRuns = v ?? 0)),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Crossed before wicket was broken'), value: crossed, onChanged: (v) => setState(() => crossed = v)),
            ],
            DropdownButtonFormField<int?>(initialValue: replacement, decoration: const InputDecoration(labelText: 'Replacement batter', border: OutlineInputBorder()), items: [const DropdownMenuItem<int?>(value: null, child: Text('Select later')), ...widget.replacements.map((id) => DropdownMenuItem<int?>(value: id, child: Text(widget.name(id)))], onChanged: (v) => setState(() => replacement = v)),
          ],
        ])),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: _confirm, child: const Text('Confirm'))],
    );
  }

  void _confirm() {
    if (deliveryType != DeliveryType.noBall && runs < 1) return;
    if (deliveryType == DeliveryType.noBall && noBallExtraRuns < 0) return;
    if (!wicket) {
      Navigator.pop(context, DeliveryInput(deliveryType: deliveryType, wideRuns: deliveryType == DeliveryType.wide ? runs : 0, byeRuns: deliveryType == DeliveryType.bye ? runs : (deliveryType == DeliveryType.noBall && noBallExtraType == 2 ? noBallExtraRuns : 0), legByeRuns: deliveryType == DeliveryType.legBye ? runs : (deliveryType == DeliveryType.noBall && noBallExtraType == 3 ? noBallExtraRuns : 0), batterRuns: deliveryType == DeliveryType.noBall && noBallExtraType == 1 ? noBallExtraRuns : 0, noBallRuns: deliveryType == DeliveryType.noBall ? 1 : 0));
      return;
    }
    try {
      final input = WicketInput(type: wicketType, dismissedPlayerId: dismissed, fielderId: fielder, runOutEnd: runOutEnd, completedRuns: completedRuns, crossedBeforeWicket: crossed, replacementBatterId: replacement, deliveryType: deliveryType, batterRuns: deliveryType == DeliveryType.noBall && noBallExtraType == 1 ? noBallExtraRuns : 0, byeRuns: deliveryType == DeliveryType.bye ? runs : (deliveryType == DeliveryType.noBall && noBallExtraType == 2 ? noBallExtraRuns : 0), legByeRuns: deliveryType == DeliveryType.legBye ? runs : (deliveryType == DeliveryType.noBall && noBallExtraType == 3 ? noBallExtraRuns : 0), wideRuns: deliveryType == DeliveryType.wide ? runs : 0, noBallRuns: deliveryType == DeliveryType.noBall ? 1 : 0);
      final w = const WicketWorkflowService().create(input: input, strikerId: widget.strikerId, nonStrikerId: widget.nonStrikerId, deliveryType: deliveryType, eligibleFielderIds: widget.fielders.toSet());
      Navigator.pop(context, DeliveryInput(deliveryType: deliveryType, batterRuns: input.batterRuns, byeRuns: input.byeRuns, legByeRuns: input.legByeRuns, wideRuns: input.wideRuns, noBallRuns: input.noBallRuns, wicket: w));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Invalid argument(s): ', ''))));
    }
  }

  static String _labelDelivery(DeliveryType t) => switch (t) { DeliveryType.wide => 'Wide', DeliveryType.noBall => 'No-Ball', DeliveryType.bye => 'Bye', DeliveryType.legBye => 'Leg-Bye', DeliveryType.normal => 'Normal' };
  static String _labelWicket(WicketType t) => switch (t) { WicketType.bowled => 'Bowled', WicketType.caught => 'Caught', WicketType.lbw => 'LBW', WicketType.runOut => 'Run Out', WicketType.stumped => 'Stumped', WicketType.hitWicket => 'Hit Wicket', WicketType.retired => 'Retired', WicketType.obstructingField => 'Obstructing the Field', WicketType.overFence => 'Over Fence' };
}
