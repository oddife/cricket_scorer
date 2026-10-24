import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/features/broadcast/models/broadcast_snapshot.dart';
import 'package:cricket_scorer/features/broadcast/state/broadcast_state_coordinator.dart';

void main() {
  group('BroadcastStateCoordinator', () {
    late BroadcastStateCoordinator coordinator;

    setUp(() => coordinator = BroadcastStateCoordinator());
    tearDown(() => coordinator.dispose());

    BroadcastSnapshot eventSnapshot({
      required DateTime capturedAt,
      String context = '1/10',
      String? latestIdentity,
      String? kind,
      String? detail,
      Set<String> activeIdentities = const <String>{},
      List<BroadcastScoringEvent> candidates =
          const <BroadcastScoringEvent>[],
      bool eligible = true,
    }) =>
        BroadcastSnapshot(
          ready: true,
          matchId: '1',
          capturedAt: capturedAt,
          scoringContextIdentity: context,
          latestScoringEventIdentity: latestIdentity,
          latestScoringEventKind: kind,
          latestScoringEventDetail: detail,
          activeScoringEventIdentities: activeIdentities,
          scoringEventCandidates: candidates,
          automaticEventsEligible: eligible,
        );

    test('keeps snapshot, visibility and messages in one state document', () {
      final now = DateTime.now();
      coordinator.updateSnapshot(
        BroadcastSnapshot(
          ready: true,
          matchName: 'Sunday Final',
          runs: 124,
          wickets: 4,
          totalLegalBalls: 77,
          capturedAt: now,
        ),
      );
      coordinator.setOverlayEnabled(BroadcastOverlay.scorecard, true);
      coordinator.setOverlayEnabled(BroadcastOverlay.ticker, true);
      coordinator.showTicker(
        'Thanks to our sponsor',
        duration: const Duration(seconds: 20),
      );
      coordinator.triggerEvent(
        kind: 'SIX',
        detail: 'Audrin clears the boundary',
        duration: const Duration(seconds: 5),
      );

      final json = coordinator.toJson();
      expect(json['version'], 1);
      expect(
        (json['snapshot'] as Map<String, Object?>)['matchName'],
        'Sunday Final',
      );
      expect(
        (json['overlays'] as Map<String, Object?>)['scorecard'],
        isTrue,
      );
      expect(
        (json['overlays'] as Map<String, Object?>)['lowerThird'],
        isFalse,
      );
      expect(
        (json['ticker'] as Map<String, Object?>)['title'],
        'Thanks to our sponsor',
      );
      expect(
        (json['event'] as Map<String, Object?>)['title'],
        'SIX',
      );
      expect(
        (json['event'] as Map<String, Object?>)['detail'],
        'Audrin clears the boundary',
      );
    });

    test('persists full-screen scorecard view and layout settings', () {
      coordinator.setFullScreenScorecardSettings(
        enabled: true,
        view: 'playingXi',
        style: 'tvBroadcast',
        transparent: true,
        showCompactScorecard: true,
        playingXiMode: 'single',
        playingXiTeam: 'teamB',
      );

      final serialized =
          coordinator.toJson()['fullScreenScorecardSettings']
              as Map<String, Object?>;
      expect(serialized['enabled'], isTrue);
      expect(serialized['view'], 'playingXi');
      expect(serialized['style'], 'tvBroadcast');
      expect(serialized['transparent'], isTrue);
      expect(serialized['showCompactScorecard'], isTrue);
      expect(serialized['playingXiMode'], 'single');
      expect(serialized['playingXiTeam'], 'teamB');

      coordinator.setFullScreenScorecardSettings(
        enabled: false,
        view: 'combined',
        style: 'traditional',
        transparent: false,
        showCompactScorecard: false,
        playingXiMode: 'both',
        playingXiTeam: 'teamA',
      );
      coordinator.restoreFullScreenScorecardSettings(serialized);

      expect(
        coordinator.fullScreenScorecardSettings,
        serialized,
      );
      expect(
        () => coordinator.setFullScreenScorecardSettings(view: 'unknown'),
        throwsArgumentError,
      );
    });

    test('selects and serializes scorecard display styles', () {
      expect(
        coordinator.scorecardStyle,
        BroadcastScorecardStyle.fullBroadcastBar,
      );
      expect(coordinator.toJson()['scorecardStyle'], 'fullBroadcastBar');

      coordinator.setScorecardStyle(BroadcastScorecardStyle.minimal);
      expect(coordinator.toJson()['scorecardStyle'], 'minimal');

      coordinator.setScorecardStyle(BroadcastScorecardStyle.detailed);
      expect(coordinator.toJson()['scorecardStyle'], 'detailed');
    });

    test('remembers independent geometry for each scorecard style', () {
      coordinator.setLayout({
        'scorecard': {'x': 4, 'y': 81, 'width': 90, 'height': 9},
      });

      coordinator.setScorecardStyle(BroadcastScorecardStyle.minimal);
      expect(coordinator.layout['scorecard'], {
        'x': 3.0,
        'y': 82.5,
        'width': 94.0,
        'height': 8.0,
      });
      coordinator.setLayout({
        'scorecard': {'x': 5, 'y': 84, 'width': 90, 'height': 6},
      });

      coordinator.setScorecardStyle(BroadcastScorecardStyle.detailed);
      expect(coordinator.layout['scorecard']!['height'], 8.0);
      coordinator.setLayout({
        'scorecard': {'x': 10, 'y': 80, 'width': 85, 'height': 10},
      });

      coordinator.setScorecardStyle(BroadcastScorecardStyle.fullBroadcastBar);
      expect(coordinator.layout['scorecard'], {
        'x': 4.0,
        'y': 81.0,
        'width': 90.0,
        'height': 9.0,
      });
      coordinator.setScorecardStyle(BroadcastScorecardStyle.minimal);
      expect(coordinator.layout['scorecard'], {
        'x': 5.0,
        'y': 84.0,
        'width': 90.0,
        'height': 6.0,
      });
      final json = coordinator.toJson();
      expect(
        (json['scorecardGeometries'] as Map<String, dynamic>)['minimal'],
        {'x': 5.0, 'y': 84.0, 'width': 90.0, 'height': 6.0},
      );
    });

    test('restores saved scorecard geometry map', () {
      coordinator.setScorecardGeometries({
        BroadcastScorecardStyle.minimal: {
          'x': 7,
          'y': 85,
          'width': 88,
          'height': 5,
        },
      });
      coordinator.setScorecardStyle(BroadcastScorecardStyle.minimal);
      expect(coordinator.layout['scorecard'], {
        'x': 7.0,
        'y': 85.0,
        'width': 88.0,
        'height': 5.0,
      });
    });

    test('rejects invalid saved scorecard geometry', () {
      expect(
        () => coordinator.setScorecardGeometries({
          BroadcastScorecardStyle.minimal: {
            'x': 90,
            'y': 90,
            'width': 20,
            'height': 8,
          },
        }),
        throwsArgumentError,
      );
    });

    test('supports layer visibility, locking and draw order', () {
      expect(coordinator.layerOrder, defaultBroadcastLayerOrder);
      expect(coordinator.isLayerVisible('scorecard'), isTrue);
      expect(coordinator.isLayerLocked('scorecard'), isFalse);

      coordinator.setLayerVisible('ticker', false);
      coordinator.setLayerLocked('scorecard', true);
      coordinator.bringLayerForward('scorecard');
      expect(coordinator.layerOrder[1], 'scorecard');
      coordinator.bringLayerForward('scorecard');
      coordinator.bringLayerForward('scorecard');
      expect(coordinator.layerOrder.last, 'scorecard');
      expect(coordinator.isLayerVisible('ticker'), isFalse);
      expect(coordinator.isLayerLocked('scorecard'), isTrue);

      coordinator.sendLayerBackward('scorecard');
      expect(coordinator.layerOrder[2], 'scorecard');
      final json = coordinator.toJson();
      final layers = json['layerSettings'] as Map<String, dynamic>;
      expect((layers['ticker'] as Map<String, dynamic>)['visible'], isFalse);
      expect((layers['scorecard'] as Map<String, dynamic>)['locked'], isTrue);
      expect((layers['scorecard'] as Map<String, dynamic>)['zIndex'], 2);
    });

    test('restores layer settings from workspace values', () {
      coordinator.restoreLayerSettings(
        visibility: {'lowerThird': false},
        locked: {'lastBall': true},
        order: ['ticker', 'scorecard', 'lowerThird', 'lastBall'],
      );
      expect(coordinator.isLayerVisible('lowerThird'), isFalse);
      expect(coordinator.isLayerLocked('lastBall'), isTrue);
      expect(coordinator.layerOrder.first, 'ticker');
    });

    test('rejects incomplete layer order', () {
      expect(
        () => coordinator.restoreLayerSettings(order: ['scorecard', 'ticker']),
        throwsArgumentError,
      );
    });

    test('serializes the complete workspace state for saved presets', () {
      coordinator.setScorecardStyle(BroadcastScorecardStyle.minimal);
      coordinator.setScorecardGeometries({
        BroadcastScorecardStyle.minimal: {
          'x': 8,
          'y': 86,
          'width': 88,
          'height': 6,
        },
        BroadcastScorecardStyle.detailed: {
          'x': 5,
          'y': 82,
          'width': 90,
          'height': 8,
        },
        BroadcastScorecardStyle.fullBroadcastBar: {
          'x': 3,
          'y': 82.5,
          'width': 94,
          'height': 8,
        },
      });
      coordinator.setLayerVisible('ticker', false);
      coordinator.setLayerLocked('lowerThird', true);
      coordinator.bringLayerForward('scorecard');

      final serialized =
          jsonDecode(jsonEncode(coordinator.toJson())) as Map<String, dynamic>;
      expect(serialized['scorecardStyle'], 'minimal');
      final geometries =
          serialized['scorecardGeometries'] as Map<String, dynamic>;
      expect(
        (geometries['minimal'] as Map<String, dynamic>)['height'],
        6.0,
      );
      final layers = serialized['layerSettings'] as Map<String, dynamic>;
      expect((layers['ticker'] as Map<String, dynamic>)['visible'], isFalse);
      expect((layers['lowerThird'] as Map<String, dynamic>)['locked'], isTrue);
      expect((layers['scorecard'] as Map<String, dynamic>)['zIndex'], 1);
    });

    test('assigns media and independent settings to custom event slots', () {
      coordinator.setEventMediaSettings(
        slot: 'CUSTOM_3',
        name: 'Super Over',
        mediaId: 'asset_123.gif',
        mediaName: 'super-over.gif',
        mediaUrl: '/broadcast/media/asset_123.gif',
        mediaType: 'image',
        loop: true,
        durationSeconds: 9,
      );

      final settings =
          coordinator.eventMediaSettings['CUSTOM_3']!;
      expect(settings['name'], 'Super Over');
      expect(settings['mediaName'], 'super-over.gif');
      expect(settings['mediaType'], 'image');
      expect(settings['loop'], isTrue);
      expect(settings['durationSeconds'], 9);

      coordinator.triggerEvent(kind: 'CUSTOM_3', detail: 'Second chance');
      final event = coordinator.toJson()['event'] as Map<String, Object?>;
      expect(event['title'], 'Super Over');
      expect(event['slot'], 'CUSTOM_3');
      expect(event['mediaUrl'], '/broadcast/media/asset_123.gif');
      expect(event['mediaType'], 'image');
      expect(event['loop'], isTrue);
      expect(
        DateTime.parse(event['expiresAt'] as String)
            .difference(DateTime.parse(event['createdAt'] as String))
            .inSeconds,
        9,
      );

      coordinator.setEventMediaSettings(
        slot: 'CUSTOM_3',
        clearMedia: true,
      );
      expect(
        coordinator.eventMediaSettings['CUSTOM_3']!['mediaUrl'],
        isNull,
      );
      expect(
        coordinator.eventMediaSettings['CUSTOM_3']!['mediaName'],
        isNull,
      );
      expect(
        coordinator.eventMediaSettings['CUSTOM_3']!['name'],
        'Super Over',
      );
    });

    test('plays only unseen scoring events and does not replay refreshes', () {
      final now = DateTime(2026, 10, 24, 12);
      coordinator.updateSnapshot(eventSnapshot(
        capturedAt: now,
        latestIdentity: '1/10/1',
        kind: 'FOUR',
        activeIdentities: const {'1/10/1'},
      ));
      expect(coordinator.event, isNull);

      coordinator.updateSnapshot(eventSnapshot(
        capturedAt: now.add(const Duration(seconds: 1)),
        latestIdentity: '1/10/2',
        kind: 'SIX',
        detail: 'Hitter',
        activeIdentities: const {'1/10/1', '1/10/2'},
      ));
      expect(coordinator.event?.title, 'SIX');
      expect(coordinator.event?.detail, 'Hitter');
      expect(coordinator.event?.toJson()['triggeringEventIdentity'], '1/10/2');
      final startedAt = coordinator.event!.createdAt;

      coordinator.updateSnapshot(eventSnapshot(
        capturedAt: now.add(const Duration(seconds: 2)),
        latestIdentity: '1/10/2',
        kind: 'SIX',
        detail: 'Hitter',
        activeIdentities: const {'1/10/1', '1/10/2'},
      ));
      expect(coordinator.event!.createdAt, startedAt);

      coordinator.updateSnapshot(eventSnapshot(
        capturedAt: now.add(const Duration(seconds: 3)),
        latestIdentity: '1/10/3',
        kind: 'WICKET',
        activeIdentities: const {'1/10/1', '1/10/2', '1/10/3'},
      ));
      expect(coordinator.event?.title, 'WICKET');
      expect(coordinator.event?.toJson()['triggeringEventIdentity'], '1/10/3');
    });

    test('disabled and historical scoring events are not auto-played', () {
      final now = DateTime(2026, 10, 24, 12);
      coordinator.updateSnapshot(eventSnapshot(capturedAt: now));
      coordinator.setAutomaticEventPlaybackEnabled(false);
      coordinator.updateSnapshot(eventSnapshot(
        capturedAt: now.add(const Duration(seconds: 1)),
        latestIdentity: '1/10/1',
        kind: 'FOUR',
        activeIdentities: const {'1/10/1'},
      ));
      expect(coordinator.event, isNull);
      expect(coordinator.toJson()['automaticEventPlaybackEnabled'], isFalse);

      coordinator.setAutomaticEventPlaybackEnabled(true);
      coordinator.updateSnapshot(eventSnapshot(
        capturedAt: now.add(const Duration(seconds: 2)),
        latestIdentity: '1/10/1',
        kind: 'FOUR',
        activeIdentities: const {'1/10/1'},
      ));
      expect(coordinator.event, isNull);

      coordinator.updateSnapshot(eventSnapshot(
        capturedAt: now.add(const Duration(seconds: 3)),
        context: '1/9',
        latestIdentity: '1/9/7',
        kind: 'SIX',
        activeIdentities: const {'1/9/7'},
        eligible: false,
      ));
      expect(coordinator.event, isNull);
      coordinator.updateSnapshot(eventSnapshot(
        capturedAt: now.add(const Duration(seconds: 4)),
        latestIdentity: '1/10/1',
        kind: 'FOUR',
        activeIdentities: const {'1/10/1'},
      ));
      expect(coordinator.event, isNull);
    });

    test('undo clears only the animation tied to the removed ball', () {
      final now = DateTime(2026, 10, 24, 12);
      coordinator.updateSnapshot(eventSnapshot(capturedAt: now));
      coordinator.updateSnapshot(eventSnapshot(
        capturedAt: now.add(const Duration(seconds: 1)),
        latestIdentity: '1/10/1',
        kind: 'FOUR',
        detail: 'Batter',
        activeIdentities: const {'1/10/1'},
      ));
      expect(coordinator.event?.title, 'FOUR');

      // An unrelated later ball and its Undo do not remove the event ball.
      coordinator.updateSnapshot(eventSnapshot(
        capturedAt: now.add(const Duration(seconds: 2)),
        latestIdentity: '1/10/2',
        activeIdentities: const {'1/10/1', '1/10/2'},
      ));
      final startedAt = coordinator.event!.createdAt;
      coordinator.updateSnapshot(eventSnapshot(
        capturedAt: now.add(const Duration(seconds: 3)),
        latestIdentity: '1/10/1',
        kind: 'FOUR',
        detail: 'Batter',
        activeIdentities: const {'1/10/1'},
      ));
      expect(coordinator.event?.title, 'FOUR');
      expect(coordinator.event!.createdAt, startedAt);

      // Undoing the actual trigger removes its identity and stops playback.
      coordinator.updateSnapshot(eventSnapshot(
        capturedAt: now.add(const Duration(seconds: 4)),
      ));
      expect(coordinator.event, isNull);
    });

    test('detects a boundary earlier in a batched sync refresh', () {
      final now = DateTime(2026, 10, 24, 12);
      coordinator.updateSnapshot(eventSnapshot(capturedAt: now));

      final batchedSnapshot = eventSnapshot(
        capturedAt: now.add(const Duration(seconds: 1)),
        latestIdentity: '1/10/3',
        activeIdentities: const {'1/10/1', '1/10/2', '1/10/3'},
        // The last received ball is ordinary, but the same sync refresh also
        // imported a FOUR before it.
        candidates: const [
          BroadcastScoringEvent(
            identity: '1/10/1',
            kind: 'FOUR',
            detail: 'Batter',
          ),
        ],
      );
      coordinator.updateSnapshot(batchedSnapshot);
      expect(coordinator.event?.title, 'FOUR');
      expect(
        coordinator.event?.toJson()['triggeringEventIdentity'],
        '1/10/1',
      );
      final startedAt = coordinator.event!.createdAt;

      coordinator.updateSnapshot(eventSnapshot(
        capturedAt: now.add(const Duration(seconds: 2)),
        latestIdentity: '1/10/3',
        activeIdentities: const {'1/10/1', '1/10/2', '1/10/3'},
        candidates: const [
          BroadcastScoringEvent(
            identity: '1/10/1',
            kind: 'FOUR',
            detail: 'Batter',
          ),
        ],
      ));
      expect(coordinator.event!.createdAt, startedAt);
    });

    test('stores broadcast layer geometry as percentages', () {
      coordinator.setLayout({
        'scorecard': {
          'x': 8.0,
          'y': 6.0,
          'width': 55.0,
          'height': 28.0,
        },
      });

      final state = coordinator.toJson();
      final layout = state['layout'] as Map<String, Map<String, double>>;
      expect(layout['scorecard']!['x'], 8.0);
      expect(layout['scorecard']!['width'], 55.0);
      expect(layout['ticker']!['x'], 3.0);
    });

    test('defaults compact scorecard above ticker at the bottom', () {
      final layout = coordinator.layout;
      final scorecard = layout['scorecard']!;
      final ticker = layout['ticker']!;

      expect(scorecard['y'], greaterThan(50));
      expect(scorecard['y']! + scorecard['height']!, lessThan(ticker['y']!));
      expect(ticker['y']! + ticker['height']!, lessThanOrEqualTo(100));
      expect(scorecard['width'], 94);
      expect(scorecard['height'], 8);
      expect(scorecard['y'], 82.5);
      expect(ticker['width'], 94);
    });

    test('clearing messages does not alter score snapshot or visibility', () {
      final now = DateTime.now();
      coordinator.updateSnapshot(
        BroadcastSnapshot(
          ready: true,
          runs: 42,
          wickets: 1,
          capturedAt: now,
        ),
      );
      coordinator.setOverlayEnabled(BroadcastOverlay.scorecard, true);
      coordinator.showTicker('Temporary notice');
      coordinator.clearMessages();

      final json = coordinator.toJson();
      expect(
        (json['snapshot'] as Map<String, Object?>)['runs'],
        42,
      );
      expect(
        (json['overlays'] as Map<String, Object?>)['scorecard'],
        isTrue,
      );
      expect(json['ticker'], isNull);
      expect(json['event'], isNull);
    });

    test('temporary ticker expires without touching scoring snapshot', () async {
      final now = DateTime.now();
      coordinator.updateSnapshot(
        BroadcastSnapshot(
          ready: true,
          runs: 7,
          capturedAt: now,
        ),
      );
      coordinator.showTicker(
        'Short message',
        duration: const Duration(milliseconds: 25),
      );

      await Future<void>.delayed(const Duration(milliseconds: 80));

      final json = coordinator.toJson();
      expect(json['ticker'], isNull);
      expect(
        (json['snapshot'] as Map<String, Object?>)['runs'],
        7,
      );
    });
  });
}
