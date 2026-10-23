import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    // The operator explicitly starts broadcasting from the status card.
    // Opening this screen must not unexpectedly put graphics on air.
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
    if (_tickerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a ticker message first.')),
      );
      return;
    }
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
                onStart: server.isStarting
                    ? null
                    : () {
                        // Every server session starts clean. Keep saved layout,
                        // themes and settings; do not put stale messages back on air.
                        coordinator.clearMessages();
                        coordinator.setAllOverlaysEnabled(false);
                        unawaited(server.start());
                      },
                onStop: server.isRunning ? () => unawaited(server.stop()) : null,
                onCopy: _copy,
              ),
              const SizedBox(height: 16),
              _MatchPreviewCard(snapshot: snapshot),
              const SizedBox(height: 16),
              _BroadcastLayoutEditor(coordinator: coordinator),
              const SizedBox(height: 16),
              _BroadcastControlsSection(
                child: LayoutBuilder(
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

class _BroadcastControlsSection extends StatefulWidget {
  const _BroadcastControlsSection({required this.child});

  final Widget child;

  @override
  State<_BroadcastControlsSection> createState() =>
      _BroadcastControlsSectionState();
}

class _BroadcastControlsSectionState extends State<_BroadcastControlsSection> {
  static const _expandedKey = 'cricket_scorer.broadcast.controls.expanded.v1';
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadExpanded());
  }

  Future<void> _loadExpanded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() => _expanded = prefs.getBool(_expandedKey) ?? false);
    } catch (_) {
      // Keep the default collapsed state if preferences are unavailable.
    }
  }

  Future<void> _toggleExpanded() async {
    final expanded = !_expanded;
    setState(() => _expanded = expanded);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_expandedKey, expanded);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save settings visibility: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.tune_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Broadcast settings & controls',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        _expanded
                            ? 'Manage on-air graphics, events, ticker and lower-thirds.'
                            : 'Minimized to save space. Expand to access broadcast controls.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => unawaited(_toggleExpanded()),
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  label: Text(_expanded ? 'Minimize' : 'Expand'),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 12),
          widget.child,
        ],
      ],
    );
  }
}

enum _PresetSwitchChoice {
  updateCurrentAndSwitch,
  keepWorkspace,
  discardAndSwitch,
}

class _BroadcastLayoutEditor extends StatefulWidget {
  const _BroadcastLayoutEditor({required this.coordinator});

  final BroadcastStateCoordinator coordinator;

  @override
  State<_BroadcastLayoutEditor> createState() => _BroadcastLayoutEditorState();
}

class _BroadcastLayoutEditorState extends State<_BroadcastLayoutEditor> {
  static const _currentKey = 'cricket_scorer.broadcast.layout.current.v1';
  static const _presetsKey = 'cricket_scorer.broadcast.layout.presets.v1';
  static const _expandedKey = 'cricket_scorer.broadcast.layout.editorExpanded.v1';
  static const _scorecardStyleKey = 'cricket_scorer.broadcast.scorecardStyle.v1';
  static const _scorecardGeometriesKey =
      'cricket_scorer.broadcast.scorecardGeometries.v1';
  static const _layerSettingsKey = 'cricket_scorer.broadcast.layerSettings.v1';

  static const _layerNames = <String, String>{
    'scorecard': 'Compact scorecard',
    'ticker': 'Ticker',
    'lowerThird': 'Lower third',
    'lastBall': 'Event / Media',
  };

  final _presetName = TextEditingController(text: 'Standard TV');
  final _x = TextEditingController();
  final _y = TextEditingController();
  final _width = TextEditingController();
  final _height = TextEditingController();

  String _selectedLayer = 'scorecard';
  String? _selectedPreset = 'Standard TV';
  Map<String, Map<String, Map<String, double>>> _presets = {};
  Map<String, Map<String, Object?>> _presetSettings = {};
  bool _loaded = false;
  bool _expanded = false;
  BroadcastScorecardStyle? _lastObservedStyle;

  @override
  void initState() {
    super.initState();
    _lastObservedStyle = widget.coordinator.scorecardStyle;
    widget.coordinator.addListener(_onCoordinatorChanged);
    _syncFields();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant _BroadcastLayoutEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coordinator != widget.coordinator) {
      oldWidget.coordinator.removeListener(_onCoordinatorChanged);
      _lastObservedStyle = widget.coordinator.scorecardStyle;
      widget.coordinator.addListener(_onCoordinatorChanged);
    }
  }

  void _onCoordinatorChanged() {
    final currentStyle = widget.coordinator.scorecardStyle;
    final changed = currentStyle != _lastObservedStyle;
    _lastObservedStyle = currentStyle;
    if (_loaded && changed) {
      unawaited(_persistSelectedStyleAndGeometry());
      if (mounted) setState(_syncFields);
    }
  }

  Future<void> _persistSelectedStyleAndGeometry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _scorecardStyleKey,
        widget.coordinator.scorecardStyle.wireValue,
      );
      await _saveCurrent();
    } catch (error) {
      _message('Unable to save scorecard style geometry: $error');
    }
  }

  @override
  void dispose() {
    widget.coordinator.removeListener(_onCoordinatorChanged);
    _presetName.dispose();
    _x.dispose();
    _y.dispose();
    _width.dispose();
    _height.dispose();
    super.dispose();
  }

  Map<String, Map<String, double>> _copyLayout(
    Map<String, Map<String, double>> source,
  ) => {
        for (final entry in source.entries)
          entry.key: Map<String, double>.of(entry.value),
      };

  bool _matchesLegacyDefaultLayout(
    Map<String, Map<String, double>> layout,
  ) {
    const knownDefaults = <Map<String, Map<String, double>>>[
      {
        'scorecard': {'x': 3, 'y': 3, 'width': 61, 'height': 32},
        'ticker': {'x': 3, 'y': 89, 'width': 94, 'height': 7.5},
        'lowerThird': {'x': 3, 'y': 70, 'width': 58, 'height': 17},
        'lastBall': {'x': 65, 'y': 4, 'width': 32, 'height': 17},
      },
      {
        'scorecard': {'x': 3, 'y': 70, 'width': 94, 'height': 20},
        'ticker': {'x': 3, 'y': 91.5, 'width': 94, 'height': 6.5},
        'lowerThird': {'x': 3, 'y': 51, 'width': 58, 'height': 17},
        'lastBall': {'x': 25, 'y': 22, 'width': 50, 'height': 42},
      },
    ];

    for (final knownDefault in knownDefaults) {
      if (layout.length != knownDefault.length) continue;
      var matches = true;
      for (final entry in knownDefault.entries) {
        final actual = layout[entry.key];
        if (actual == null) {
          matches = false;
          break;
        }
        for (final field in ['x', 'y', 'width', 'height']) {
          final actualValue = actual[field];
          if (actualValue == null ||
              (actualValue - entry.value[field]!).abs() > 0.001) {
            matches = false;
            break;
          }
        }
        if (!matches) break;
      }
      if (matches) return true;
    }
    return false;
  }

  Map<BroadcastScorecardStyle, Map<String, double>> _parseScorecardGeometries(
    Object? raw,
  ) {
    if (raw is! Map) return {};
    final result = <BroadcastScorecardStyle, Map<String, double>>{};
    for (final entry in raw.entries) {
      if (entry.key is! String) continue;
      final style = BroadcastScorecardStyleJson.fromWireValue(entry.key as String);
      if (style == null) continue;
      final parsed = _parseLayout({'scorecard': entry.value});
      if (parsed != null) result[style] = parsed['scorecard']!;
    }
    return result;
  }

  ({
    Map<String, bool> visibility,
    Map<String, bool> locked,
    List<String>? order,
  })? _parseLayerSettings(Object? raw) {
    if (raw is! Map) return null;
    final visibility = <String, bool>{};
    final locked = <String, bool>{};
    final ordered = <(String, int)>[];
    for (final entry in raw.entries) {
      if (entry.key is! String || !_layerNames.containsKey(entry.key)) {
        continue;
      }
      final value = entry.value;
      if (value is! Map) continue;
      final layer = entry.key as String;
      if (value['visible'] is bool) {
        visibility[layer] = value['visible'] as bool;
      }
      if (value['locked'] is bool) {
        locked[layer] = value['locked'] as bool;
      }
      if (value['zIndex'] is num) {
        ordered.add((layer, (value['zIndex'] as num).toInt()));
      }
    }
    ordered.sort((a, b) => a.$2.compareTo(b.$2));
    final order = ordered.length == _layerNames.length &&
            ordered.map((entry) => entry.$1).toSet().length == _layerNames.length
        ? ordered.map((entry) => entry.$1).toList()
        : null;
    return (visibility: visibility, locked: locked, order: order);
  }

  Map<String, Map<String, double>>? _parseLayout(Object? raw) {
    if (raw is! Map) return null;
    final result = <String, Map<String, double>>{};
    const fields = ['x', 'y', 'width', 'height'];
    for (final entry in raw.entries) {
      if (entry.key is! String || !_layerNames.containsKey(entry.key)) {
        return null;
      }
      if (entry.value is! Map) return null;
      final rect = entry.value as Map;
      if (fields.any((field) => rect[field] is! num)) return null;
      final values = <String, double>{
        for (final field in fields)
          field: (rect[field] as num).toDouble(),
      };
      final x = values['x']!;
      final y = values['y']!;
      final w = values['width']!;
      final h = values['height']!;
      if (![x, y, w, h].every((v) => v.isFinite) ||
          x < 0 || y < 0 || w <= 0 || h <= 0 ||
          x + w > 100.01 || y + h > 100.01) {
        return null;
      }
      result[entry.key as String] = values;
    }
    return result.isEmpty ? null : result;
  }

  Map<String, Object?> _normalizePresetSettings(
    Map? savedSettings,
    Map<String, Map<String, double>> presetLayout,
  ) {
    var style = widget.coordinator.scorecardStyle;
    final savedStyleValue = savedSettings?['scorecardStyle'];
    if (savedStyleValue is String) {
      style = BroadcastScorecardStyleJson.fromWireValue(savedStyleValue) ?? style;
    }

    final geometries = <BroadcastScorecardStyle, Map<String, double>>{
      for (final entry in widget.coordinator.scorecardGeometries.entries)
        entry.key: Map<String, double>.of(entry.value),
    };
    final savedGeometries =
        _parseScorecardGeometries(savedSettings?['scorecardGeometries']);
    geometries.addAll(savedGeometries);
    if (!savedGeometries.containsKey(style) &&
        presetLayout['scorecard'] != null) {
      geometries[style] = Map<String, double>.of(presetLayout['scorecard']!);
    }

    final parsedLayers = _parseLayerSettings(savedSettings?['layerSettings']);
    final layerSettings = <String, Map<String, Object?>>{};
    final order = parsedLayers?.order ?? widget.coordinator.layerOrder;
    final currentLayerSettings = widget.coordinator.layerSettings;
    for (final layer in _layerNames.keys) {
      final current = currentLayerSettings[layer] ?? const <String, Object?>{};
      layerSettings[layer] = {
        'visible': parsedLayers?.visibility[layer] ??
            (current['visible'] as bool? ?? true),
        'locked': parsedLayers?.locked[layer] ??
            (current['locked'] as bool? ?? false),
        'zIndex': order.indexOf(layer) < 0
            ? _layerNames.keys.toList().indexOf(layer)
            : order.indexOf(layer),
      };
    }

    return {
      'scorecardStyle': style.wireValue,
      'scorecardGeometries': {
        for (final entry in geometries.entries)
          entry.key.wireValue: entry.value,
      },
      'layerSettings': layerSettings,
    };
  }

  ({
    Map<String, Map<String, double>> layout,
    Map<String, Object?> settings,
  })? _parsePresetEntry(Object? raw) {
    final rawMap = raw is Map ? raw : null;
    final isWorkspacePreset = rawMap?['layout'] is Map;
    final parsedLayout = _parseLayout(
      isWorkspacePreset ? rawMap!['layout'] : raw,
    );
    if (parsedLayout == null) return null;

    var normalizedLayout = parsedLayout;
    if (_matchesLegacyDefaultLayout(normalizedLayout)) {
      normalizedLayout = _copyLayout(defaultBroadcastLayout);
    }
    final fullLayout = _copyLayout(widget.coordinator.layout)
      ..addAll(_copyLayout(normalizedLayout));
    final settings = _normalizePresetSettings(
      isWorkspacePreset ? rawMap : null,
      fullLayout,
    );
    return (layout: fullLayout, settings: settings);
  }

  Map<String, Object?> _capturePresetSettings({
    Map<String, Map<String, double>>? layout,
  }) {
    return _normalizePresetSettings(null, layout ?? widget.coordinator.layout);
  }

  Map<String, Object?> _captureWorkspaceDocument() {
    final layout = _copyLayout(widget.coordinator.layout);
    return {
      'layout': layout,
      ..._capturePresetSettings(layout: layout),
    };
  }

  Map<String, Object?> _presetDocument(String name) {
    final layout = _presets[name]!;
    return {
      'layout': layout,
      ...(_presetSettings[name] ?? _capturePresetSettings(layout: layout)),
    };
  }

  bool _workspaceMatchesPreset(String name) {
    final savedLayout = _presets[name];
    if (savedLayout == null) return false;
    final current = _captureWorkspaceDocument();
    final saved = _presetDocument(name);
    return jsonEncode(current) == jsonEncode(saved);
  }

  Future<void> _restorePresetSettings(Map<String, Object?> settings) async {
    final styleValue = settings['scorecardStyle'];
    if (styleValue is String) {
      final style = BroadcastScorecardStyleJson.fromWireValue(styleValue);
      if (style != null) widget.coordinator.setScorecardStyle(style);
    }
    final geometries =
        _parseScorecardGeometries(settings['scorecardGeometries']);
    if (geometries.isNotEmpty) {
      widget.coordinator.setScorecardGeometries(geometries);
    }
    final layers = _parseLayerSettings(settings['layerSettings']);
    if (layers != null) {
      widget.coordinator.restoreLayerSettings(
        visibility: layers.visibility,
        locked: layers.locked,
        order: layers.order,
      );
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final editorExpanded = prefs.getBool(_expandedKey) ?? false;
      final savedStyle = prefs.getString(_scorecardStyleKey);
      if (savedStyle != null) {
        final parsedStyle = BroadcastScorecardStyleJson.fromWireValue(savedStyle);
        if (parsedStyle != null) widget.coordinator.setScorecardStyle(parsedStyle);
      }
      final savedGeometries = prefs.getString(_scorecardGeometriesKey);
      if (savedGeometries != null) {
        final parsedGeometries =
            _parseScorecardGeometries(jsonDecode(savedGeometries));
        if (parsedGeometries.isNotEmpty) {
          widget.coordinator.setScorecardGeometries(parsedGeometries);
        }
      }
      final savedLayerSettings = prefs.getString(_layerSettingsKey);
      if (savedLayerSettings != null) {
        final parsedSettings =
            _parseLayerSettings(jsonDecode(savedLayerSettings));
        if (parsedSettings != null) {
          widget.coordinator.restoreLayerSettings(
            visibility: parsedSettings.visibility,
            locked: parsedSettings.locked,
            order: parsedSettings.order,
          );
        }
      }
      final currentText = prefs.getString(_currentKey);
      if (currentText != null) {
        var current = _parseLayout(jsonDecode(currentText));
        if (current != null) {
          // Migrate an untouched starter layout to the improved bottom layout,
          // while preserving any operator-customized workspace.
          if (_matchesLegacyDefaultLayout(current)) {
            current = _copyLayout(defaultBroadcastLayout);
          }
          widget.coordinator.setLayout(current);
        }
      }

      final loaded = <String, Map<String, Map<String, double>>>{};
      final loadedSettings = <String, Map<String, Object?>>{};
      final stored = prefs.getString(_presetsKey);
      if (stored != null) {
        final decoded = jsonDecode(stored);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            if (entry.key is! String) continue;
            final parsed = _parsePresetEntry(entry.value);
            if (parsed == null) continue;
            loaded[entry.key as String] = parsed.layout;
            loadedSettings[entry.key as String] = parsed.settings;
          }
        }
      }
      if (!loaded.containsKey('Standard TV')) {
        final standardLayout = _copyLayout(widget.coordinator.layout);
        loaded['Standard TV'] = standardLayout;
        loadedSettings['Standard TV'] =
            _capturePresetSettings(layout: standardLayout);
      } else {
        loadedSettings.putIfAbsent(
          'Standard TV',
          () => _capturePresetSettings(layout: loaded['Standard TV']!),
        );
      }

      if (!mounted) return;
      setState(() {
        _presets = loaded;
        _presetSettings = loadedSettings;
        _expanded = editorExpanded;
        _selectedPreset = loaded.containsKey('Standard TV')
            ? 'Standard TV'
            : loaded.keys.first;
        _presetName.text = _selectedPreset!;
        _loaded = true;
      });
      await _saveCurrent();
      await _savePresets();
    } catch (error) {
      if (mounted) {
        setState(() => _loaded = true);
        _message('Unable to load layout presets: $error');
      }
    }
  }

  Future<void> _saveCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentKey, jsonEncode(widget.coordinator.layout));
    await prefs.setString(
      _scorecardGeometriesKey,
      jsonEncode({
        for (final entry in widget.coordinator.scorecardGeometries.entries)
          entry.key.wireValue: entry.value,
      }),
    );
    await prefs.setString(
      _layerSettingsKey,
      jsonEncode(widget.coordinator.layerSettings),
    );
  }

  Future<void> _savePresets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _presetsKey,
      jsonEncode({
        for (final entry in _presets.entries)
          entry.key: _presetDocument(entry.key),
      }),
    );
  }

  Future<void> _setScorecardStyle(BroadcastScorecardStyle? style) async {
    if (style == null) return;
    widget.coordinator.setScorecardStyle(style);
    if (mounted) setState(() {});
    await _persistSelectedStyleAndGeometry();
  }

  Future<void> _setExpanded(bool expanded) async {
    setState(() => _expanded = expanded);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_expandedKey, expanded);
    } catch (error) {
      _message('Unable to save editor visibility: $error');
    }
  }

  String _fmt(double value) =>
      value == value.roundToDouble()
          ? value.toStringAsFixed(0)
          : value.toStringAsFixed(1);

  void _syncFields() {
    final rect = widget.coordinator.layout[_selectedLayer];
    if (rect == null) return;
    _x.text = _fmt(rect['x']!);
    _y.text = _fmt(rect['y']!);
    _width.text = _fmt(rect['width']!);
    _height.text = _fmt(rect['height']!);
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  void _setLayer(String layer, Map<String, double> rect) {
    if (widget.coordinator.isLayerLocked(layer)) {
      _message('Unlock this layer before changing its geometry.');
      return;
    }
    try {
      widget.coordinator.setLayout({layer: rect});
      _syncFields();
      unawaited(_saveCurrent());
      if (mounted) setState(() {});
    } on ArgumentError catch (error) {
      _message(error.message?.toString() ?? 'Invalid layer geometry.');
    }
  }

  Future<void> _setSelectedLayerVisibility(bool visible) async {
    widget.coordinator.setLayerVisible(_selectedLayer, visible);
    if (mounted) setState(() {});
    await _saveCurrent();
  }

  Future<void> _setSelectedLayerLock(bool locked) async {
    widget.coordinator.setLayerLocked(_selectedLayer, locked);
    if (mounted) setState(() {});
    await _saveCurrent();
  }

  Future<void> _moveSelectedLayer({required bool forward}) async {
    if (forward) {
      widget.coordinator.bringLayerForward(_selectedLayer);
    } else {
      widget.coordinator.sendLayerBackward(_selectedLayer);
    }
    if (mounted) setState(() {});
    await _saveCurrent();
  }

  void _applyFields() {
    final x = double.tryParse(_x.text.trim());
    final y = double.tryParse(_y.text.trim());
    final w = double.tryParse(_width.text.trim());
    final h = double.tryParse(_height.text.trim());
    if (x == null || y == null || w == null || h == null) {
      _message('Enter numeric X, Y, width and height values.');
      return;
    }
    _setLayer(_selectedLayer, {'x': x, 'y': y, 'width': w, 'height': h});
  }

  void _reset() {
    widget.coordinator.resetLayout();
    _syncFields();
    unawaited(_saveCurrent());
    setState(() {});
  }

  Future<_PresetSwitchChoice?> _confirmPresetSwitch({
    required String targetName,
    required bool canUpdateCurrent,
  }) {
    return showDialog<_PresetSwitchChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unsaved workspace changes'),
        content: Text(
          'The current layout, scorecard style, or layer settings differ from the saved preset. '
          'What should happen before switching to "$targetName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext)
                .pop(_PresetSwitchChoice.keepWorkspace),
            child: const Text('Keep editing'),
          ),
          if (canUpdateCurrent)
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext)
                  .pop(_PresetSwitchChoice.updateCurrentAndSwitch),
              child: const Text('Update current & switch'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext)
                .pop(_PresetSwitchChoice.discardAndSwitch),
            child: const Text('Discard & switch'),
          ),
        ],
      ),
    );
  }

  Future<void> _activatePreset(String name) async {
    final preset = _presets[name];
    if (preset == null) return;
    final settings = _presetSettings[name] ??
        _capturePresetSettings(layout: preset);
    try {
      widget.coordinator.resetLayout();
      widget.coordinator.setLayout(preset);
      await _restorePresetSettings(settings);
      setState(() {
        _selectedPreset = name;
        _presetName.text = name;
      });
      _syncFields();
      await _saveCurrent();
    } on ArgumentError catch (error) {
      _message(error.message?.toString() ?? 'Invalid preset.');
    }
  }

  Future<void> _applyPreset(String name) async {
    if (!_presets.containsKey(name)) return;
    final currentName = _selectedPreset;
    final dirty = currentName == null ||
        !_presets.containsKey(currentName) ||
        !_workspaceMatchesPreset(currentName);
    if (dirty) {
      final choice = await _confirmPresetSwitch(
        targetName: name,
        canUpdateCurrent: currentName != null &&
            _presets.containsKey(currentName),
      );
      if (!mounted) return;
      if (choice == null || choice == _PresetSwitchChoice.keepWorkspace) {
        setState(() {});
        return;
      }
      if (choice == _PresetSwitchChoice.updateCurrentAndSwitch &&
          currentName != null &&
          _presets.containsKey(currentName)) {
        final layout = _copyLayout(widget.coordinator.layout);
        final settings = _capturePresetSettings(layout: layout);
        setState(() {
          _presets[currentName] = layout;
          _presetSettings[currentName] = settings;
        });
        await _savePresets();
      }
    }
    await _activatePreset(name);
  }

  Future<void> _saveAsNew() async {
    final name = _presetName.text.trim();
    if (name.isEmpty) {
      _message('Enter a preset name.');
      return;
    }
    if (_presets.containsKey(name)) {
      _message('That preset already exists. Select it and use Update.');
      return;
    }
    final layout = _copyLayout(widget.coordinator.layout);
    final settings = _capturePresetSettings(layout: layout);
    setState(() {
      _presets[name] = layout;
      _presetSettings[name] = settings;
      _selectedPreset = name;
    });
    await _savePresets();
    await _saveCurrent();
    _message('Saved preset: $name');
  }

  Future<void> _updatePreset() async {
    final name = _selectedPreset;
    if (name == null || !_presets.containsKey(name)) {
      await _saveAsNew();
      return;
    }
    final layout = _copyLayout(widget.coordinator.layout);
    final settings = _capturePresetSettings(layout: layout);
    setState(() {
      _presets[name] = layout;
      _presetSettings[name] = settings;
      _presetName.text = name;
    });
    await _savePresets();
    await _saveCurrent();
    _message('Updated preset: $name');
  }

  Future<void> _renamePreset() async {
    final oldName = _selectedPreset;
    final newName = _presetName.text.trim();
    if (oldName == null || !_presets.containsKey(oldName) ||
        newName.isEmpty || (newName != oldName && _presets.containsKey(newName))) {
      _message('Choose a preset and enter an unused name.');
      return;
    }
    setState(() {
      final value = _presets.remove(oldName)!;
      final settings = _presetSettings.remove(oldName);
      _presets[newName] = value;
      if (settings != null) _presetSettings[newName] = settings;
      _selectedPreset = newName;
    });
    await _savePresets();
    _message('Renamed preset: $newName');
  }

  Future<void> _exportPresets() async {
    final payload = jsonEncode({
      'version': 2,
      'presets': {
        for (final entry in _presets.entries)
          entry.key: _presetDocument(entry.key),
      },
    });
    await Clipboard.setData(ClipboardData(text: payload));
    _message('Preset JSON copied. Save it to a file for backup or transfer.');
  }

  Future<void> _importPresets() async {
    final input = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import layout presets'),
        content: SizedBox(
          width: 620,
          child: TextField(
            controller: input,
            minLines: 8,
            maxLines: 16,
            decoration: const InputDecoration(
              labelText: 'Paste exported preset JSON',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(input.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    input.dispose();
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map ||
          !const [1, 2].contains(decoded['version']) ||
          decoded['presets'] is! Map) {
        throw const FormatException('Unsupported preset JSON.');
      }
      final importedLayouts = <String, Map<String, Map<String, double>>>{};
      final importedSettings = <String, Map<String, Object?>>{};
      final rawPresets = decoded['presets'] as Map;
      for (final entry in rawPresets.entries) {
        if (entry.key is! String) continue;
        final parsed = _parsePresetEntry(entry.value);
        if (parsed == null) {
          throw FormatException(
            'Invalid layout workspace in preset ${entry.key}.',
          );
        }
        importedLayouts[entry.key as String] = parsed.layout;
        importedSettings[entry.key as String] = parsed.settings;
      }
      if (importedLayouts.isEmpty) {
        throw const FormatException('No valid presets found.');
      }
      setState(() {
        for (final entry in importedLayouts.entries) {
          var name = entry.key;
          var suffix = 2;
          while (_presets.containsKey(name)) {
            name = '${entry.key} ($suffix)';
            suffix++;
          }
          _presets[name] = entry.value;
          _presetSettings[name] = importedSettings[entry.key]!;
        }
        _selectedPreset = null;
      });
      await _savePresets();
      _message('Imported ${imported.length} preset(s).');
    } catch (error) {
      _message('Unable to import presets: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final layout = widget.coordinator.layout;
    final selectedLayerLocked = widget.coordinator.isLayerLocked(_selectedLayer);
    final selectedLayerVisible = widget.coordinator.isLayerVisible(_selectedLayer);
    final layerOrder = widget.coordinator.layerOrder;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Layout editor', style: theme.textTheme.titleMedium),
                      Text(
                        _expanded
                            ? 'Select layers from the list, even when another layer covers the canvas.'
                            : 'Minimized to save space. Your last editor state is remembered.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => unawaited(_setExpanded(!_expanded)),
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  label: Text(_expanded ? 'Minimize' : 'Expand'),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 280,
                    child: DropdownButtonFormField<BroadcastScorecardStyle>(
                      key: ValueKey(widget.coordinator.scorecardStyle),
                      initialValue: widget.coordinator.scorecardStyle,
                      decoration: const InputDecoration(
                        labelText: 'Compact scorecard style',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final style in BroadcastScorecardStyle.values)
                          DropdownMenuItem(
                            value: style,
                            child: Text(style.label),
                          ),
                      ],
                      onChanged: (style) =>
                          unawaited(_setScorecardStyle(style)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        switch (widget.coordinator.scorecardStyle) {
                          BroadcastScorecardStyle.minimal =>
                            'Team identity and score only for a clean, unobtrusive overlay.',
                          BroadcastScorecardStyle.detailed =>
                            'Adds current batter figures and bowler details without the ball-by-ball chips.',
                          BroadcastScorecardStyle.fullBroadcastBar =>
                            'Full layout with team, score, batter figures, bowler details and current-over balls.',
                        },
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in _layerNames.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: _selectedLayer == entry.key,
                      onSelected: (selected) {
                        if (!selected) return;
                        setState(() => _selectedLayer = entry.key);
                        _syncFields();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterChip(
                    avatar: Icon(
                      selectedLayerVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                    ),
                    label: Text(
                      selectedLayerVisible ? 'Layer visible' : 'Layer hidden',
                    ),
                    selected: selectedLayerVisible,
                    onSelected: (value) =>
                        unawaited(_setSelectedLayerVisibility(value)),
                  ),
                  FilterChip(
                    avatar: Icon(
                      selectedLayerLocked
                          ? Icons.lock_outline
                          : Icons.lock_open_outlined,
                      size: 18,
                    ),
                    label: Text(selectedLayerLocked ? 'Locked' : 'Unlocked'),
                    selected: selectedLayerLocked,
                    onSelected: (value) =>
                        unawaited(_setSelectedLayerLock(value)),
                  ),
                  OutlinedButton.icon(
                    onPressed: layerOrder.last == _selectedLayer
                        ? null
                        : () => unawaited(_moveSelectedLayer(forward: true)),
                    icon: const Icon(Icons.flip_to_front),
                    label: const Text('Bring forward'),
                  ),
                  OutlinedButton.icon(
                    onPressed: layerOrder.first == _selectedLayer
                        ? null
                        : () => unawaited(_moveSelectedLayer(forward: false)),
                    icon: const Icon(Icons.flip_to_back),
                    label: const Text('Send backward'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                selectedLayerLocked
                    ? 'This layer is locked. Unlock it to drag, resize or apply numeric geometry.'
                    : 'The layer list remains available even when other graphics overlap. Locking prevents accidental moves or resizing.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = w * 9 / 16;
                return Container(
                  width: w,
                  height: h,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: const Color(0xff07110b),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _BroadcastGridPainter(
                            color: colors.outlineVariant.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                      for (final layer in widget.coordinator.layerOrder)
                        if (layout[layer] != null &&
                            widget.coordinator.isLayerVisible(layer))
                          Positioned(
                            left: w * layout[layer]!['x']! / 100,
                            top: h * layout[layer]!['y']! / 100,
                            width: w * layout[layer]!['width']! / 100,
                            height: h * layout[layer]!['height']! / 100,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedLayer = layer);
                                _syncFields();
                              },
                              onPanStart: widget.coordinator.isLayerLocked(layer)
                                  ? null
                                  : (_) {
                                      setState(() => _selectedLayer = layer);
                                      _syncFields();
                                    },
                              onPanUpdate: widget.coordinator.isLayerLocked(layer)
                                  ? null
                                  : (details) {
                                final rect = widget.coordinator.layout[layer]!;
                                final newX = (rect['x']! +
                                        details.delta.dx / w * 100)
                                    .clamp(0.0, 100.0 - rect['width']!)
                                    .toDouble();
                                final newY = (rect['y']! +
                                        details.delta.dy / h * 100)
                                    .clamp(0.0, 100.0 - rect['height']!)
                                    .toDouble();
                                _setLayer(layer, {
                                  ...rect,
                                  'x': newX,
                                  'y': newY,
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: (layer == _selectedLayer
                                          ? colors.primary
                                          : colors.secondary)
                                      .withValues(alpha: 0.25),
                                  border: Border.all(
                                    color: layer == _selectedLayer
                                        ? colors.primary
                                        : colors.secondary,
                                    width: layer == _selectedLayer ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: _BroadcastLayerPreview(
                                          layer: layer,
                                        ),
                                      ),
                                    ),
                                    if (widget.coordinator.isLayerLocked(layer))
                                      const Positioned(
                                        right: 2,
                                        bottom: 2,
                                        child: Icon(Icons.lock_outline, size: 14),
                                      )
                                    else
                                      Positioned(
                                        right: 1,
                                        bottom: 1,
                                        child: GestureDetector(
                                          onPanUpdate: (details) {
                                            final rect = widget.coordinator.layout[layer]!;
                                            final nw = (rect['width']! +
                                                    details.delta.dx / w * 100)
                                                .clamp(5.0, 100.0 - rect['x']!)
                                                .toDouble();
                                            final nh = (rect['height']! +
                                                    details.delta.dy / h * 100)
                                                .clamp(4.0, 100.0 - rect['y']!)
                                                .toDouble();
                                            _setLayer(layer, {
                                              ...rect,
                                              'width': nw,
                                              'height': nh,
                                            });
                                          },
                                          child: Icon(
                                            Icons.open_in_full,
                                            size: 15,
                                            color: colors.onPrimary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedLayer,
                    decoration: const InputDecoration(
                      labelText: 'Selected layer',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final entry in _layerNames.entries)
                        DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedLayer = value);
                      _syncFields();
                    },
                  ),
                ),
                for (final field in [
                  ('X (%)', _x),
                  ('Y (%)', _y),
                  ('Width (%)', _width),
                  ('Height (%)', _height),
                ])
                  SizedBox(
                    width: 115,
                    child: TextField(
                      controller: field.$2,
                      enabled: !selectedLayerLocked,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: field.$1,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                FilledButton(
                  onPressed: selectedLayerLocked ? null : _applyFields,
                  child: const Text('Apply geometry'),
                ),
                OutlinedButton(
                  onPressed: _reset,
                  child: const Text('Reset standard'),
                ),
              ],
            ),
            const Divider(height: 28),
            Text('Named layout presets', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_selectedPreset),
                    initialValue: _presets.containsKey(_selectedPreset) ? _selectedPreset : null,
                    decoration: const InputDecoration(
                      labelText: 'Saved preset',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final name in _presets.keys)
                        DropdownMenuItem(value: name, child: Text(name)),
                    ],
                    onChanged: (name) {
                      if (name != null) unawaited(_applyPreset(name));
                    },
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: TextField(
                    controller: _presetName,
                    decoration: const InputDecoration(
                      labelText: 'Preset name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: _loaded ? () => unawaited(_saveAsNew()) : null,
                  child: const Text('Save as new'),
                ),
                OutlinedButton(
                  onPressed: _loaded ? () => unawaited(_updatePreset()) : null,
                  child: const Text('Update selected'),
                ),
                OutlinedButton(
                  onPressed: _loaded ? () => unawaited(_renamePreset()) : null,
                  child: const Text('Rename'),
                ),
                OutlinedButton(
                  onPressed: _loaded ? () => unawaited(_exportPresets()) : null,
                  child: const Text('Export JSON'),
                ),
                OutlinedButton(
                  onPressed: _loaded ? () => unawaited(_importPresets()) : null,
                  child: const Text('Import JSON'),
                ),
              ],
            ),
            if (!_loaded) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 8),
            Text(
              'The workspace auto-saves geometry and layer settings. Named presets capture geometry, each scorecard style size, layer visibility/locks/order. Switching with unsaved changes asks whether to update the old preset, keep editing, or discard. JSON export/import transfers this workspace configuration, not media files.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BroadcastGridPainter extends CustomPainter {
  const _BroadcastGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;
    for (var i = 1; i < 16; i++) {
      final x = size.width * i / 16;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var i = 1; i < 9; i++) {
      final y = size.height * i / 9;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BroadcastGridPainter oldDelegate) =>
      color != oldDelegate.color;
}

class _ServerStatusCard extends StatefulWidget {
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

  @override
  State<_ServerStatusCard> createState() => _ServerStatusCardState();
}

class _ServerStatusCardState extends State<_ServerStatusCard> {
  static const _expandedKey =
      'cricket_scorer.broadcast.serverCard.expanded.v1';
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadExpanded());
  }

  Future<void> _loadExpanded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() => _expanded = prefs.getBool(_expandedKey) ?? false);
    } catch (_) {
      // The compact default is safe if preferences cannot be read.
    }
  }

  Future<void> _toggleExpanded() async {
    final expanded = !_expanded;
    setState(() => _expanded = expanded);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_expandedKey, expanded);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save server panel visibility: $error')),
      );
    }
  }

  Uri? _atPath(String path) => widget.server.baseUri?.replace(path: path);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final server = widget.server;
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
                    onPressed: widget.onStop,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Stop'),
                  )
                else
                  FilledButton.icon(
                    onPressed: widget.onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Broadcasting'),
                  ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: _expanded ? 'Minimize server details' : 'Expand server details',
                  onPressed: () => unawaited(_toggleExpanded()),
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
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
            if (_expanded && isRunning && baseUri != null) ...[
              const Divider(height: 28),
              _UrlRow(
                title: 'Combined output · one OBS/vMix source',
                url: _atPath('/broadcast/output')!,
                onCopy: widget.onCopy,
              ),
              const SizedBox(height: 4),
              _UrlRow(
                title: 'Broadcast Manager · controls',
                url: _atPath('/broadcast/manage')!,
                onCopy: widget.onCopy,
              ),
              const SizedBox(height: 4),
              _UrlRow(
                title: 'Health check',
                url: _atPath('/healthz')!,
                onCopy: widget.onCopy,
              ),
              const SizedBox(height: 4),
              Text(
                'The server listens on 127.0.0.1. OBS/vMix browser sources on this PC can connect; other computers cannot connect by default.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (_expanded && server.isSupported) ...[
              const SizedBox(height: 8),
              Text(
                'Press Start Broadcasting to start a clean broadcast session. All overlays begin hidden; your saved layouts and media settings remain intact. If port 3113 is occupied, the app tries ports 3114–3118 and displays the actual URLs here.',
                style: theme.textTheme.bodySmall,
              ),
            ] else if (_expanded) ...[
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
      BroadcastOverlay.scorecard: 'Compact scorecard',
      BroadcastOverlay.ticker: 'Ticker',
      BroadcastOverlay.lowerThird: 'Lower third',
      BroadcastOverlay.lastBall: 'Event / Media',
    };
    final anyVisible = BroadcastOverlay.values
        .any(coordinator.isOverlayEnabled);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.live_tv_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('On-air controls',
                      style: theme.textTheme.titleMedium),
                ),
                Text(anyVisible ? 'Graphics enabled' : 'All graphics hidden',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final overlay in BroadcastOverlay.values)
                  FilterChip(
                    avatar: Icon(
                      coordinator.isOverlayEnabled(overlay)
                          ? Icons.visibility
                          : Icons.visibility_off_outlined,
                      size: 18,
                    ),
                    label: Text(labels[overlay]!),
                    selected: coordinator.isOverlayEnabled(overlay),
                    onSelected: (enabled) =>
                        coordinator.setOverlayEnabled(overlay, enabled),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final shouldHide = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Take all graphics off air?'),
                      content: const Text(
                        'This hides every broadcast overlay. It does not delete '
                        'your layouts, presets, themes, media, or match data.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text('Take all off air'),
                        ),
                      ],
                    ),
                  );
                  if (shouldHide == true) {
                    coordinator.setAllOverlaysEnabled(false);
                  }
                },
                icon: const Icon(Icons.visibility_off_outlined),
                label: const Text('Take all graphics off air'),
              ),
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


class _BroadcastLayerPreview extends StatelessWidget {
  const _BroadcastLayerPreview({required this.layer});

  final String layer;

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xff102637);
    const gold = Color(0xffd8b45a);
    const pale = Color(0xffe9f1f8);
    final contents = switch (layer) {
      'scorecard' => Container(
          color: dark,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TEAM',
                  style: TextStyle(
                    color: dark,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '177/2  ·  28.5 OV',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: pale,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'BATTERS  57 (60)  ·  40 (49)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: pale, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'BOWLER  1/24',
                    style: TextStyle(
                      color: gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'LAST OVER  4 · 1 · 0 · 2',
                    style: TextStyle(color: pale, fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
        ),
      'ticker' => Container(
          color: const Color(0xff07130e),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            children: [
              Container(
                color: gold,
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: dark,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'MATCH UPDATE  ·  SCORE 177/2',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: pale,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      'lowerThird' => Container(
          color: const Color(0xff10281b),
          padding: const EdgeInsets.all(8),
          alignment: Alignment.centerLeft,
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MILESTONE',
                  style: TextStyle(
                    color: gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'HALF CENTURY',
                  style: TextStyle(
                    color: pale,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'PLAYER NAME  ·  50 RUNS',
                  style: TextStyle(color: pale, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      _ => Container(
          color: const Color(0xff183a2a),
          alignment: Alignment.center,
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'SIX',
              style: TextStyle(
                color: gold,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ),
        ),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(width: 560, height: 76, child: contents),
      ),
    );
  }
}
