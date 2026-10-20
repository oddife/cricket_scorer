import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/features/broadcast/models/broadcast_snapshot.dart';
import 'package:cricket_scorer/features/broadcast/server/broadcast_http_server.dart';
import 'package:cricket_scorer/features/broadcast/state/broadcast_state_coordinator.dart';

void main() {
  group('BroadcastHttpServer', () {
    late BroadcastStateCoordinator coordinator;
    late BroadcastHttpServer server;
    late HttpClient client;
    Uri? baseUri;

    setUp(() async {
      coordinator = BroadcastStateCoordinator();
      coordinator.updateSnapshot(
        BroadcastSnapshot(
          ready: true,
          matchName: 'Server Test',
          runs: 12,
          wickets: 1,
          capturedAt: DateTime.now(),
        ),
      );
      server = BroadcastHttpServer();
      client = HttpClient();
      baseUri = await server.start(coordinator, port: 0);
    });

    tearDown(() async {
      client.close(force: true);
      await server.close();
      coordinator.dispose();
    });

    Future<(int, String)> getPath(String path) async {
      final request = await client.getUrl(baseUri!.resolve(path));
      final response = await request.close();
      return (
        response.statusCode,
        await utf8.decoder.bind(response).join(),
      );
    }

    Future<int> postJson(String path, Map<String, Object?> payload) async {
      final request = await client.postUrl(baseUri!.resolve(path));
      request.headers.contentType = ContentType.json;
      request.headers.set('origin', baseUri!.origin);
      request.write(jsonEncode(payload));
      final response = await request.close();
      await utf8.decoder.bind(response).join();
      return response.statusCode;
    }

    test('serves manager, overlay pages and state JSON', () async {
      expect((await getPath('/broadcast/manage')).$1, HttpStatus.ok);
      expect((await getPath('/broadcast/output')).$1, HttpStatus.ok);
      final (_, combinedOutput) = await getPath('/broadcast/output');
      expect(combinedOutput, contains('Combined Broadcast Output'));
      expect(combinedOutput, contains('batter1Name'));
      expect(combinedOutput, contains('bowlerFigures'));
      expect(combinedOutput, contains('recentBalls'));
      expect(combinedOutput, contains('TEAM'));
      expect(combinedOutput, contains('top:82.5%;width:94%;height:8%'));
      expect(combinedOutput, contains('scorecard:{width:94,height:8}'));
      expect(combinedOutput, contains('font-size:34cqh'));
      expect(combinedOutput, contains('font-size:22cqh'));
      expect(combinedOutput, contains('padding:2.5cqh .85cqw'));
      expect(combinedOutput, isNot(contains('.bar-section{padding:2%}')));
      expect(combinedOutput, contains('padding:.12em 0'));
      expect(combinedOutput, contains('container-type:size'));
      expect(combinedOutput, contains("el.style.transform='none'"));
      expect(combinedOutput, contains("fetch('/api/v1/broadcast/state'"));
      expect((await getPath('/broadcast/scorecard')).$1, HttpStatus.ok);
      expect((await getPath('/broadcast/ticker')).$1, HttpStatus.ok);
      expect((await getPath('/broadcast/lower-third')).$1, HttpStatus.ok);
      expect((await getPath('/broadcast/last-ball')).$1, HttpStatus.ok);

      final (status, body) = await getPath('/api/v1/broadcast/state');
      expect(status, HttpStatus.ok);
      final state = jsonDecode(body) as Map<String, dynamic>;
      expect(
        (state['snapshot'] as Map<String, dynamic>)['matchName'],
        'Server Test',
      );
    });

    test('control routes update the shared coordinator', () async {
      expect(
        await postJson('/api/v1/broadcast/overlay', {
          'overlay': 'scorecard',
          'enabled': true,
        }),
        HttpStatus.noContent,
      );
      expect(
        await postJson('/api/v1/broadcast/ticker', {
          'text': 'Sponsor message',
          'durationSeconds': 15,
        }),
        HttpStatus.noContent,
      );

      final (_, body) = await getPath('/api/v1/broadcast/state');
      final state = jsonDecode(body) as Map<String, dynamic>;
      expect(
        (state['overlays'] as Map<String, dynamic>)['scorecard'],
        isTrue,
      );
      expect(
        (state['ticker'] as Map<String, dynamic>)['title'],
        'Sponsor message',
      );
    });

    test('layout control updates shared output geometry', () async {
      expect(
        await postJson('/api/v1/broadcast/layout', {
          'layout': {
            'scorecard': {'x': 8, 'y': 6, 'width': 55, 'height': 28},
          },
        }),
        HttpStatus.noContent,
      );

      final (_, body) = await getPath('/api/v1/broadcast/state');
      final state = jsonDecode(body) as Map<String, dynamic>;
      final layout = state['layout'] as Map<String, dynamic>;
      final scorecard = layout['scorecard'] as Map<String, dynamic>;
      expect(scorecard['x'], 8);
      expect(scorecard['width'], 55);
    });

    test('rejects unknown paths and cross-origin controls', () async {
      expect((await getPath('/not-a-route')).$1, HttpStatus.notFound);

      final request =
          await client.postUrl(baseUri!.resolve('/api/v1/broadcast/overlays'));
      request.headers.contentType = ContentType.json;
      request.headers.set('origin', 'http://example.invalid');
      request.write(jsonEncode({'enabled': false}));
      final response = await request.close();
      await utf8.decoder.bind(response).join();
      expect(response.statusCode, HttpStatus.forbidden);
    });
  });
}
