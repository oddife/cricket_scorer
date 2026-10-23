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
    late Directory mediaDirectory;
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
      mediaDirectory = await Directory.systemTemp.createTemp(
        'cricket-scorer-broadcast-media-test-',
      );
      server = BroadcastHttpServer(mediaDirectoryPath: mediaDirectory.path);
      client = HttpClient();
      baseUri = await server.start(coordinator, port: 0);
    });

    tearDown(() async {
      client.close(force: true);
      await server.close();
      coordinator.dispose();
      if (await mediaDirectory.exists()) {
        await mediaDirectory.delete(recursive: true);
      }
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
      final (managerStatus, managerHtml) = await getPath('/broadcast/manage');
      expect(managerStatus, HttpStatus.ok);
      expect(managerHtml, contains('Compact scorecard style'));
      expect(managerHtml, contains('broadcast/scorecard-style'));
      expect(managerHtml, contains('Choose & upload'));
      expect(managerHtml, contains('Custom Event 1'));
      expect(managerHtml, contains('Custom Event 2'));
      expect(managerHtml, contains('Custom Event 3'));
      expect(managerHtml, contains('/api/v1/broadcast/media/upload'));

      expect((await getPath('/broadcast/output')).$1, HttpStatus.ok);
      final (_, combinedOutput) = await getPath('/broadcast/output');
      expect(combinedOutput, contains('Combined Broadcast Output'));
      expect(combinedOutput, contains('batter1Name'));
      expect(combinedOutput, contains('bowlerFigures'));
      expect(combinedOutput, contains('recentBalls'));
      expect(combinedOutput, contains('eventMediaImage'));
      expect(combinedOutput, contains('eventMediaVideo'));
      expect(combinedOutput, contains('renderEventMedia'));
      expect(combinedOutput, contains('broadcastPageStartedAt'));
      expect(combinedOutput, contains('data-style="minimal"'));
      expect(combinedOutput, contains('data-style="detailed"'));
      expect(combinedOutput, contains('TEAM'));
      expect(combinedOutput, contains('top:82.5%;width:94%;height:8%'));
      expect(combinedOutput, contains('scorecard:{width:94,height:8}'));
      expect(combinedOutput, contains('font-size:40cqh'));
      expect(combinedOutput, contains('font-size:26cqh'));
      expect(combinedOutput, contains('font-size:20cqh'));
      expect(combinedOutput, contains('padding:2.5cqh .85cqw'));
      expect(combinedOutput, isNot(contains('.bar-section{padding:2%}')));
      expect(combinedOutput, contains('padding:.12em 0'));
      expect(combinedOutput, contains('container-type:size'));
      expect(combinedOutput, contains("el.style.transform='none'"));
      expect(combinedOutput, contains('applyLayout(state.layout,layerSettings)'));
      expect(combinedOutput, contains('layerSettings.scorecard?.visible!==false'));
      expect(combinedOutput, contains('el.style.zIndex=String('));
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

    test('scorecard style control updates shared broadcast state', () async {
      expect(
        await postJson('/api/v1/broadcast/scorecard-style', {'style': 'minimal'}),
        HttpStatus.noContent,
      );

      final (_, body) = await getPath('/api/v1/broadcast/state');
      final state = jsonDecode(body) as Map<String, dynamic>;
      expect(state['scorecardStyle'], 'minimal');
      expect(state['scorecardGeometries'], isA<Map<String, dynamic>>());

      expect(
        await postJson('/api/v1/broadcast/scorecard-style', {'style': 'detailed'}),
        HttpStatus.noContent,
      );
      final (_, detailedBody) = await getPath('/api/v1/broadcast/state');
      expect(
        (jsonDecode(detailedBody) as Map<String, dynamic>)['scorecardStyle'],
        'detailed',
      );
    });

    test('rejects unknown scorecard style', () async {
      expect(
        await postJson('/api/v1/broadcast/scorecard-style', {'style': 'unknown'}),
        HttpStatus.badRequest,
      );
    });

    test('serialized layer settings match coordinator state', () async {
      coordinator.setLayerVisible('ticker', false);
      coordinator.setLayerLocked('lastBall', true);
      coordinator.bringLayerForward('scorecard');
      coordinator.bringLayerForward('scorecard');
      coordinator.bringLayerForward('scorecard');

      final (_, body) = await getPath('/api/v1/broadcast/state');
      final state = jsonDecode(body) as Map<String, dynamic>;
      final settings = state['layerSettings'] as Map<String, dynamic>;
      expect((settings['ticker'] as Map<String, dynamic>)['visible'], isFalse);
      expect((settings['lastBall'] as Map<String, dynamic>)['locked'], isTrue);
      expect((settings['scorecard'] as Map<String, dynamic>)['zIndex'], 3);
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

    test('uploads and serves local event media for a named custom slot', () async {
      // A small PNG payload. Binary content is stored outside the project and
      // can then be served directly to a transparent browser-source output.
      final pngBytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j1NsAAAAASUVORK5CYII=',
      );
      final uploadRequest = await client.postUrl(
        baseUri!.resolve('/api/v1/broadcast/media/upload?name=tiny.png'),
      );
      uploadRequest.headers.contentType = ContentType('image', 'png');
      uploadRequest.headers.set('origin', baseUri!.origin);
      uploadRequest.add(pngBytes);
      final uploadResponse = await uploadRequest.close();
      final uploadBody = await utf8.decoder.bind(uploadResponse).join();

      expect(uploadResponse.statusCode, HttpStatus.created);
      final uploaded = jsonDecode(uploadBody) as Map<String, dynamic>;
      expect(uploaded['mediaType'], 'image');
      expect(uploaded['name'], 'tiny.png');
      expect(uploaded['url'], startsWith('/broadcast/media/asset_'));

      final mediaRequest =
          await client.getUrl(baseUri!.resolve(uploaded['url'] as String));
      final mediaResponse = await mediaRequest.close();
      final servedBytes = <int>[];
      await for (final chunk in mediaResponse) {
        servedBytes.addAll(chunk);
      }
      expect(mediaResponse.statusCode, HttpStatus.ok);
      expect(servedBytes, equals(pngBytes));

      expect(
        await postJson('/api/v1/broadcast/event-settings', {
          'slot': 'CUSTOM_3',
          'name': 'Super Over',
          'mediaId': uploaded['mediaId'],
          'mediaName': uploaded['name'],
          'mediaUrl': uploaded['url'],
          'mediaType': uploaded['mediaType'],
          'loop': true,
          'durationSeconds': 9,
        }),
        HttpStatus.noContent,
      );
      expect(
        await postJson('/api/v1/broadcast/event', {
          'kind': 'CUSTOM_3',
          'detail': 'Playoff moment',
        }),
        HttpStatus.noContent,
      );

      final (_, stateBody) = await getPath('/api/v1/broadcast/state');
      final state = jsonDecode(stateBody) as Map<String, dynamic>;
      final settings =
          (state['eventMediaSettings'] as Map<String, dynamic>)['CUSTOM_3']
              as Map<String, dynamic>;
      expect(settings['name'], 'Super Over');
      expect(settings['mediaUrl'], uploaded['url']);
      expect(settings['durationSeconds'], 9);
      expect(settings['loop'], isTrue);

      final event = state['event'] as Map<String, dynamic>;
      expect(event['title'], 'Super Over');
      expect(event['mediaUrl'], uploaded['url']);
      expect(event['mediaType'], 'image');
      expect(event['loop'], isTrue);
      expect(event['slot'], 'CUSTOM_3');

      expect(
        await postJson('/api/v1/broadcast/event-settings', {
          'slot': 'CUSTOM_3',
          'name': 'Custom Event 3',
          'clearMedia': true,
          'loop': false,
          'durationSeconds': 5,
        }),
        HttpStatus.noContent,
      );
    });

    test('rejects unsupported or corrupt event media uploads', () async {
      final unsupported = await client.postUrl(
        baseUri!.resolve('/api/v1/broadcast/media/upload?name=clip.avi'),
      );
      unsupported.headers.contentType = ContentType.binary;
      unsupported.headers.set('origin', baseUri!.origin);
      unsupported.add([1, 2, 3, 4]);
      final unsupportedResponse = await unsupported.close();
      final unsupportedBody =
          await utf8.decoder.bind(unsupportedResponse).join();
      expect(
        unsupportedResponse.statusCode,
        HttpStatus.unsupportedMediaType,
      );
      expect(unsupportedBody, contains('convert it to MP4'));

      final corrupt = await client.postUrl(
        baseUri!.resolve('/api/v1/broadcast/media/upload?name=not-a-png.png'),
      );
      corrupt.headers.contentType = ContentType('image', 'png');
      corrupt.headers.set('origin', baseUri!.origin);
      corrupt.add([1, 2, 3, 4]);
      final corruptResponse = await corrupt.close();
      final corruptBody = await utf8.decoder.bind(corruptResponse).join();
      expect(corruptResponse.statusCode, HttpStatus.badRequest);
      expect(corruptBody, contains('does not look like a valid'));
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
