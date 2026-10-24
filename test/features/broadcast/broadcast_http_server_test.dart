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
      expect(managerHtml, contains('eventLibrarySearch'));
      expect(managerHtml, contains('eventMediaLibrary'));
      expect(managerHtml, contains('Delete asset'));
      expect(managerHtml, contains('deleteEventAsset'));
      expect(managerHtml, contains('/api/v1/broadcast/media/delete'));
      expect(managerHtml, contains('eventCategory'));
      expect(managerHtml, contains('refreshEventLibrary'));
      expect(managerHtml, contains('Enable automatic event playback'));
      expect(managerHtml, contains('/api/v1/broadcast/event-playback'));
      expect(managerHtml, contains('Full-screen Scorecard'));
      expect(managerHtml, contains('fullScreenView'));
      expect(
        managerHtml,
        contains('/api/v1/broadcast/full-screen-scorecard'),
      );

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
      expect(combinedOutput, contains('fullScreenScorecard'));
      expect(combinedOutput, contains('renderFullScreenScorecard'));
      expect(combinedOutput, contains('fullBattingScorecard'));
      expect(combinedOutput, contains('fullBowlingScorecard'));
      expect(combinedOutput, contains('playingXiTeams'));
      expect(combinedOutput, contains("cfg.style==='tvBroadcast'"));
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

      // Identical bytes are detected by SHA-256 and never silently create a
      // second catalog record.
      final duplicateRequest = await client.postUrl(
        baseUri!.resolve('/api/v1/broadcast/media/upload?name=tiny-copy.png&category=Sponsors'),
      );
      duplicateRequest.headers.contentType = ContentType('image', 'png');
      duplicateRequest.headers.set('origin', baseUri!.origin);
      duplicateRequest.add(pngBytes);
      final duplicateResponse = await duplicateRequest.close();
      final duplicateBody = await utf8.decoder.bind(duplicateResponse).join();
      expect(duplicateResponse.statusCode, HttpStatus.conflict);
      final duplicateJson = jsonDecode(duplicateBody) as Map<String, dynamic>;
      expect(duplicateJson['duplicate'], isTrue);
      expect(
        (duplicateJson['existing'] as Map<String, dynamic>)['mediaId'],
        uploaded['mediaId'],
      );

      final skipUri = baseUri!.resolve('/api/v1/broadcast/media/upload').replace(
        queryParameters: {
          'name': 'tiny-copy.png',
          'category': 'Sponsors',
          'duplicateAction': 'skip',
        },
      );
      final skipRequest = await client.postUrl(skipUri);
      skipRequest.headers.contentType = ContentType('image', 'png');
      skipRequest.headers.set('origin', baseUri!.origin);
      skipRequest.add(pngBytes);
      final skipResponse = await skipRequest.close();
      final skipBody = await utf8.decoder.bind(skipResponse).join();
      expect(skipResponse.statusCode, HttpStatus.ok);
      expect((jsonDecode(skipBody) as Map<String, dynamic>)['skipped'], isTrue);

      expect(
        await postJson('/api/v1/broadcast/media/category', {
          'mediaId': uploaded['mediaId'],
          'category': 'Sponsors',
        }),
        HttpStatus.ok,
      );

      // Replacing the bytes at the same library URL must retain the slot link,
      // timer and loop setting.
      final replacementBytes = List<int>.of(pngBytes);
      replacementBytes[replacementBytes.length - 1] =
          replacementBytes.last ^ 1;
      final replacementUri = baseUri!.resolve('/api/v1/broadcast/media/upload').replace(
        queryParameters: {
          'name': 'scorebug-replacement.png',
          'category': 'Sponsors',
          'replaceMediaId': uploaded['mediaId'] as String,
        },
      );
      final replacementRequest = await client.postUrl(replacementUri);
      replacementRequest.headers.contentType = ContentType('image', 'png');
      replacementRequest.headers.set('origin', baseUri!.origin);
      replacementRequest.add(replacementBytes);
      final replacementResponse = await replacementRequest.close();
      final replacementBody = await utf8.decoder.bind(replacementResponse).join();
      expect(replacementResponse.statusCode, HttpStatus.ok);
      final replacement = jsonDecode(replacementBody) as Map<String, dynamic>;
      expect(replacement['mediaId'], uploaded['mediaId']);
      expect(replacement['url'], uploaded['url']);
      expect(replacement['sha256'], isNot(uploaded['sha256']));
      expect(replacement['name'], 'scorebug-replacement.png');

      final (_, libraryBody) = await getPath('/api/v1/broadcast/media/library');
      final library = jsonDecode(libraryBody) as Map<String, dynamic>;
      final assets = library['assets'] as List<dynamic>;
      expect(assets, hasLength(1));
      final catalogued = assets.single as Map<String, dynamic>;
      expect(catalogued['category'], 'Sponsors');
      expect(catalogued['mediaId'], uploaded['mediaId']);
      expect(catalogued['assignedSlots'], contains('CUSTOM_3'));

      // The media catalog and event assignment survive a broadcast server restart.
      await server.close();
      coordinator.dispose();
      coordinator = BroadcastStateCoordinator();
      server = BroadcastHttpServer(mediaDirectoryPath: mediaDirectory.path);
      baseUri = await server.start(coordinator, port: 0);
      final (_, restartedLibraryBody) = await getPath('/api/v1/broadcast/media/library');
      final restartedLibrary = jsonDecode(restartedLibraryBody) as Map<String, dynamic>;
      expect((restartedLibrary['assets'] as List<dynamic>), hasLength(1));
      final (_, restartedStateBody) = await getPath('/api/v1/broadcast/state');
      final restartedState = jsonDecode(restartedStateBody) as Map<String, dynamic>;
      final restartedEventMedia =
          (restartedState['eventMediaSettings'] as Map<String, dynamic>)['CUSTOM_3']
              as Map<String, dynamic>;
      expect(restartedEventMedia['mediaUrl'], uploaded['url']);
      expect(restartedEventMedia['mediaName'], 'scorebug-replacement.png');
      expect(restartedEventMedia['durationSeconds'], 9);
      expect(restartedEventMedia['loop'], isTrue);

      final mediaFile = File(
        '${mediaDirectory.path}${Platform.pathSeparator}${uploaded['mediaId']}',
      );
      expect(await mediaFile.exists(), isTrue);

      // The first delete request only prepares a confirmation summary. It
      // must not delete the file or change the event assignment.
      final previewRequest = await client.postUrl(
        baseUri!.resolve('/api/v1/broadcast/media/delete'),
      );
      previewRequest.headers.contentType = ContentType.json;
      previewRequest.headers.set('origin', baseUri!.origin);
      previewRequest.write(jsonEncode({'mediaId': uploaded['mediaId']}));
      final previewResponse = await previewRequest.close();
      final previewBody = await utf8.decoder.bind(previewResponse).join();
      expect(previewResponse.statusCode, HttpStatus.conflict);
      final deletionPreview = jsonDecode(previewBody) as Map<String, dynamic>;
      expect(deletionPreview['requiresConfirmation'], isTrue);
      expect(deletionPreview['assignedSlots'], ['CUSTOM_3']);
      expect(await mediaFile.exists(), isTrue);

      final (_, beforeConfirmationBody) =
          await getPath('/api/v1/broadcast/state');
      final beforeConfirmation =
          jsonDecode(beforeConfirmationBody) as Map<String, dynamic>;
      final unchangedSlot =
          (beforeConfirmation['eventMediaSettings'] as Map<String, dynamic>)['CUSTOM_3']
              as Map<String, dynamic>;
      expect(unchangedSlot['mediaUrl'], uploaded['url']);

      // A stale confirmation must be refused without touching the file.
      final staleDeleteRequest = await client.postUrl(
        baseUri!.resolve('/api/v1/broadcast/media/delete'),
      );
      staleDeleteRequest.headers.contentType = ContentType.json;
      staleDeleteRequest.headers.set('origin', baseUri!.origin);
      staleDeleteRequest.write(jsonEncode({
        'mediaId': uploaded['mediaId'],
        'confirm': true,
        'expectedAssignedSlots': <String>[],
      }));
      final staleDeleteResponse = await staleDeleteRequest.close();
      final staleDeleteBody =
          await utf8.decoder.bind(staleDeleteResponse).join();
      expect(staleDeleteResponse.statusCode, HttpStatus.conflict);
      expect(
        (jsonDecode(staleDeleteBody) as Map<String, dynamic>)['assignmentsChanged'],
        isTrue,
      );
      expect(await mediaFile.exists(), isTrue);

      // Only an explicit confirmation for the exact reviewed assignment list
      // can delete the file and clear its slot.
      final deleteRequest = await client.postUrl(
        baseUri!.resolve('/api/v1/broadcast/media/delete'),
      );
      deleteRequest.headers.contentType = ContentType.json;
      deleteRequest.headers.set('origin', baseUri!.origin);
      deleteRequest.write(jsonEncode({
        'mediaId': uploaded['mediaId'],
        'confirm': true,
        'expectedAssignedSlots': ['CUSTOM_3'],
      }));
      final deleteResponse = await deleteRequest.close();
      final deleteBody = await utf8.decoder.bind(deleteResponse).join();
      expect(deleteResponse.statusCode, HttpStatus.ok);
      final deleted = jsonDecode(deleteBody) as Map<String, dynamic>;
      expect(deleted['deleted'], isTrue);
      expect(deleted['clearedAssignments'], ['CUSTOM_3']);
      expect(await mediaFile.exists(), isFalse);

      final (_, afterDeletionLibraryBody) =
          await getPath('/api/v1/broadcast/media/library');
      final afterDeletionLibrary =
          jsonDecode(afterDeletionLibraryBody) as Map<String, dynamic>;
      expect(afterDeletionLibrary['assets'], isEmpty);

      final (_, afterDeletionStateBody) =
          await getPath('/api/v1/broadcast/state');
      final afterDeletionState =
          jsonDecode(afterDeletionStateBody) as Map<String, dynamic>;
      final clearedSlot =
          (afterDeletionState['eventMediaSettings'] as Map<String, dynamic>)['CUSTOM_3']
              as Map<String, dynamic>;
      expect(clearedSlot['mediaUrl'], isNull);
      expect(clearedSlot['mediaName'], isNull);
      expect(clearedSlot['name'], 'Super Over');
      expect(clearedSlot['durationSeconds'], 9);
      expect(clearedSlot['loop'], isTrue);
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

    test('persists event playback and full-screen settings across server restart', () async {
      expect(
        await postJson('/api/v1/broadcast/event-playback', {'enabled': false}),
        HttpStatus.noContent,
      );
      expect(
        await postJson('/api/v1/broadcast/full-screen-scorecard', {
          'enabled': true,
          'view': 'combined',
          'style': 'tvBroadcast',
          'transparent': true,
          'showCompactScorecard': true,
          'playingXiMode': 'single',
          'playingXiTeam': 'teamB',
        }),
        HttpStatus.noContent,
      );
      final (_, beforeRestartBody) = await getPath('/api/v1/broadcast/state');
      final beforeRestart =
          jsonDecode(beforeRestartBody) as Map<String, dynamic>;
      expect(beforeRestart['automaticEventPlaybackEnabled'], isFalse);
      expect(
        beforeRestart['fullScreenScorecardSettings'],
        {
          'enabled': true,
          'view': 'combined',
          'style': 'tvBroadcast',
          'transparent': true,
          'showCompactScorecard': true,
          'playingXiMode': 'single',
          'playingXiTeam': 'teamB',
        },
      );

      await server.close();
      coordinator.dispose();
      coordinator = BroadcastStateCoordinator();
      server = BroadcastHttpServer(mediaDirectoryPath: mediaDirectory.path);
      baseUri = await server.start(coordinator, port: 0);

      final (_, afterRestartBody) = await getPath('/api/v1/broadcast/state');
      final afterRestart =
          jsonDecode(afterRestartBody) as Map<String, dynamic>;
      expect(afterRestart['automaticEventPlaybackEnabled'], isFalse);
      expect(
        afterRestart['fullScreenScorecardSettings'],
        {
          'enabled': true,
          'view': 'combined',
          'style': 'tvBroadcast',
          'transparent': true,
          'showCompactScorecard': true,
          'playingXiMode': 'single',
          'playingXiTeam': 'teamB',
        },
      );
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
