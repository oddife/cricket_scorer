import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import '../state/broadcast_state_coordinator.dart';
import 'broadcast_http_server_stub.dart' show BroadcastHttpServerBase;
import 'broadcast_output_pages.dart';

export 'broadcast_http_server_stub.dart' show BroadcastHttpServerBase;

class _IoBroadcastHttpServer implements BroadcastHttpServerBase {
  _IoBroadcastHttpServer({this.mediaDirectoryPath});

  @override
  final String? mediaDirectoryPath;
  HttpServer? _server;
  BroadcastStateCoordinator? _coordinator;
  Directory? _mediaDirectory;
  final List<Map<String, Object?>> _mediaLibrary = [];

  @override
  Uri? get baseUri => _server == null
      ? null
      : Uri(
          scheme: 'http',
          host: InternetAddress.loopbackIPv4.address,
          port: _server!.port,
        );

  @override
  bool get isRunning => _server != null;

  @override
  Future<Uri> start(
    BroadcastStateCoordinator coordinator, {
    int port = 3113,
  }) async {
    if (_server != null) return baseUri!;
    if (port < 0 || port > 65535) {
      throw ArgumentError.value(port, 'port', 'Must be between 0 and 65535.');
    }

    final mediaDirectory = _resolveMediaDirectory();
    await mediaDirectory.create(recursive: true);
    _mediaDirectory = mediaDirectory;
    await _restoreMediaLibrary();
    await _restoreEventMediaSettings(coordinator);

    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      port,
      shared: false,
    );
    _server = server;
    _coordinator = coordinator;
    server.listen((request) => unawaited(_handle(request)));
    return baseUri!;
  }

  @override
  Future<void> close() async {
    final server = _server;
    _server = null;
    _coordinator = null;
    if (server != null) await server.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      if (!_isLocalHost(request)) {
        await _sendText(request.response, HttpStatus.forbidden, 'Local requests only.');
        return;
      }

      final path = request.uri.path;
      if (request.method == 'GET') {
        if (path == '/healthz') {
          await _sendJson(request.response, HttpStatus.ok, {
            'ok': true,
            'service': 'cricket-scorer-broadcast',
            'version': 1,
          });
          return;
        }
        if (path == '/api/v1/broadcast/state') {
          await _sendJson(request.response, HttpStatus.ok, _coordinator!.toJson());
          return;
        }
        if (path == '/api/v1/broadcast/media/library') {
          await _sendJson(request.response, HttpStatus.ok, _mediaLibraryPayload());
          return;
        }
        if (path.startsWith('/broadcast/media/')) {
          await _serveMedia(request, path);
          return;
        }
        final page = _pageForPath(path);
        if (page != null) {
          await _sendHtml(request.response, page);
          return;
        }
        await _sendText(request.response, HttpStatus.notFound, 'Not found.');
        return;
      }

      if (request.method == 'POST') {
        if (!_isSameOriginMutation(request)) {
          await _sendText(request.response, HttpStatus.forbidden, 'Same-origin control requests only.');
          return;
        }
        if (path == '/api/v1/broadcast/media/upload') {
          await _handleMediaUpload(request);
          return;
        }
        final body = await utf8.decoder.bind(request).join();
        if (body.length > 16000) {
          await _sendText(request.response, 413, 'Request is too large.');
          return;
        }
        final decoded = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
        if (decoded is! Map<String, dynamic>) {
          await _sendText(request.response, HttpStatus.badRequest, 'Expected a JSON object.');
          return;
        }
        await _handleControl(request, decoded);
        return;
      }

      request.response.headers.set('allow', 'GET, POST');
      await _sendText(request.response, HttpStatus.methodNotAllowed, 'Method not allowed.');
    } catch (error, stack) {
      stderr.writeln('Broadcast server request failed: $error\n$stack');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Broadcast request failed.');
        await request.response.close();
      } catch (_) {
        // The browser source may already have disconnected.
      }
    }
  }

  bool _isLocalHost(HttpRequest request) {
    final host = request.headers.value(HttpHeaders.hostHeader)?.toLowerCase();
    final port = _server?.port;
    return port != null && (host == '127.0.0.1:$port' || host == 'localhost:$port');
  }

  bool _isSameOriginMutation(HttpRequest request) {
    final origin = request.headers.value('origin');
    if (origin == null) return true; // Local command-line clients are supported.
    final host = request.headers.value(HttpHeaders.hostHeader)?.toLowerCase();
    return host != null && origin.toLowerCase() == 'http://$host';
  }

  Directory _resolveMediaDirectory() {
    final override = mediaDirectoryPath;
    if (override != null && override.isNotEmpty) return Directory(override);
    final separator = Platform.pathSeparator;
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return Directory('$appData${separator}CricketScorer${separator}broadcast_media');
      }
    }
    final xdgHome = Platform.environment['XDG_DATA_HOME'];
    if (xdgHome != null && xdgHome.isNotEmpty) {
      return Directory('$xdgHome${separator}cricket_scorer${separator}broadcast_media');
    }
    final home = Platform.environment['HOME'] ?? Directory.systemTemp.path;
    return Directory(
      '$home${Platform.pathSeparator}.local${Platform.pathSeparator}share${Platform.pathSeparator}cricket_scorer${Platform.pathSeparator}broadcast_media',
    );
  }

  Future<void> _restoreEventMediaSettings(
    BroadcastStateCoordinator coordinator,
  ) async {
    final directory = _mediaDirectory;
    if (directory == null) return;
    final settingsFile = File(
      '${directory.path}${Platform.pathSeparator}event_media_settings.json',
    );
    if (!await settingsFile.exists()) return;
    try {
      final decoded = jsonDecode(await settingsFile.readAsString());
      if (decoded is Map && decoded['eventMediaSettings'] is Map) {
        coordinator.restoreEventMediaSettings(decoded['eventMediaSettings']);
        coordinator.restoreAutomaticEventPlaybackEnabled(
          decoded['automaticEventPlaybackEnabled'],
        );
      } else {
        // Backward compatibility with the original settings file that stored
        // only the event-slot map at its root.
        coordinator.restoreEventMediaSettings(decoded);
      }
    } catch (error) {
      stderr.writeln('Unable to restore broadcast event media settings: $error');
    }
  }

  Future<void> _persistEventMediaSettings() async {
    final directory = _mediaDirectory;
    final coordinator = _coordinator;
    if (directory == null || coordinator == null) return;
    final settingsFile = File(
      '${directory.path}${Platform.pathSeparator}event_media_settings.json',
    );
    await settingsFile.writeAsString(
      jsonEncode({
        'eventMediaSettings': coordinator.eventMediaSettings,
        'automaticEventPlaybackEnabled':
            coordinator.automaticEventPlaybackEnabled,
      }),
      flush: true,
    );
  }

  Future<void> _refreshAssignedEventMetadata(
    Map<String, Object?> asset,
  ) async {
    final coordinator = _coordinator;
    final mediaId = asset['mediaId'];
    if (coordinator == null || mediaId is! String) return;
    final assignments = coordinator.eventMediaSettings.entries
        .where((entry) => entry.value['mediaId'] == mediaId)
        .map((entry) => MapEntry(
              entry.key,
              Map<String, Object?>.of(entry.value),
            ))
        .toList();
    for (final assignment in assignments) {
      final slot = assignment.key;
      final settings = assignment.value;
      coordinator.setEventMediaSettings(
        slot: slot,
        name: slot.startsWith('CUSTOM_') ? settings['name'] as String? : null,
        mediaId: mediaId,
        mediaName: asset['name'] as String?,
        mediaUrl: asset['url'] as String?,
        mediaType: asset['mediaType'] as String?,
        loop: settings['loop'] as bool?,
        durationSeconds: (settings['durationSeconds'] as num?)?.toInt(),
      );
    }
    await _persistEventMediaSettings();
  }

  static const List<String> _mediaCategories = [
    'FOUR',
    'SIX',
    'WICKET',
    'Custom Events',
    'Team Logos',
    'Sponsors',
  ];

  String _suggestMediaCategory(String name) {
    final value = name.toLowerCase();
    if (value.contains('wicket')) return 'WICKET';
    if (value.contains('six')) return 'SIX';
    if (value.contains('four') || value.contains('boundary')) return 'FOUR';
    if (value.contains('sponsor')) return 'Sponsors';
    if (value.contains('logo') || value.contains('team')) return 'Team Logos';
    return 'Custom Events';
  }

  String _mediaCategory(String? requested, String fileName) {
    final category = requested?.trim();
    if (category == null || category.isEmpty) return _suggestMediaCategory(fileName);
    if (!_mediaCategories.contains(category)) {
      throw ArgumentError.value(category, 'category', 'Choose a supported media category.');
    }
    return category;
  }

  Map<String, Object?> _mediaLibraryPayload() {
    final coordinator = _coordinator;
    final assets = <Map<String, Object?>>[];
    for (final asset in _mediaLibrary) {
      final mediaId = asset['mediaId'];
      final assignedSlots = <String>[];
      if (coordinator != null && mediaId is String) {
        for (final entry in coordinator.eventMediaSettings.entries) {
          if (entry.value['mediaId'] == mediaId) assignedSlots.add(entry.key);
        }
      }
      assets.add({...asset, 'assignedSlots': assignedSlots});
    }
    return {'categories': _mediaCategories, 'assets': assets};
  }

  Future<void> _restoreMediaLibrary() async {
    final directory = _mediaDirectory;
    if (directory == null) return;
    final manifest = File('${directory.path}${Platform.pathSeparator}media_library.json');
    if (await manifest.exists()) {
      try {
        final decoded = jsonDecode(await manifest.readAsString());
        if (decoded is List) {
          _mediaLibrary.clear();
          for (final item in decoded) {
            if (item is! Map) continue;
            final mediaId = item['mediaId'];
            final name = item['name'];
            final category = item['category'];
            final url = item['url'];
            final mediaType = item['mediaType'];
            final digest = item['sha256'];
            if (mediaId is! String ||
                !RegExp(r'^asset_[0-9]+\.(png|jpg|jpeg|gif|webp|apng|mp4|webm)$').hasMatch(mediaId) ||
                name is! String ||
                category is! String ||
                !_mediaCategories.contains(category) ||
                url is! String ||
                mediaType is! String ||
                (mediaType != 'image' && mediaType != 'video')) {
              continue;
            }
            final file = File('${directory.path}${Platform.pathSeparator}$mediaId');
            if (!await file.exists()) continue;
            final bytes = await file.readAsBytes();
            _mediaLibrary.add({
              'mediaId': mediaId,
              'name': name,
              'category': category,
              'url': url,
              'mediaType': mediaType,
              'mimeType': item['mimeType'] is String ? item['mimeType'] : 'application/octet-stream',
              'sizeBytes': item['sizeBytes'] is num ? (item['sizeBytes'] as num).toInt() : bytes.length,
              'sha256': digest is String && digest.isNotEmpty ? digest : sha256.convert(bytes).toString(),
              'createdAt': item['createdAt'] is String ? item['createdAt'] : '',
              'updatedAt': item['updatedAt'] is String ? item['updatedAt'] : '',
            });
          }
        }
      } catch (error) {
        stderr.writeln('Unable to restore broadcast media library: $error');
      }
      return;
    }

    // Migrate media uploaded by the first event-media build into the catalog.
    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      final mediaId = entity.uri.pathSegments.isEmpty ? '' : entity.uri.pathSegments.last;
      final match = RegExp(r'^asset_[0-9]+\.(png|jpg|jpeg|gif|webp|apng|mp4|webm)$').firstMatch(mediaId);
      if (match == null) continue;
      final extension = match.group(1)!;
      final bytes = await entity.readAsBytes();
      if (!_looksLikeMedia(extension, bytes)) continue;
      final now = (await entity.stat()).modified.toIso8601String();
      final mediaType = const {'png','jpg','jpeg','gif','webp','apng'}.contains(extension) ? 'image' : 'video';
      _mediaLibrary.add({
        'mediaId': mediaId,
        'name': mediaId,
        'category': _suggestMediaCategory(mediaId),
        'url': '/broadcast/media/$mediaId',
        'mediaType': mediaType,
        'mimeType': _mediaContentType(extension).mimeType,
        'sizeBytes': bytes.length,
        'sha256': sha256.convert(bytes).toString(),
        'createdAt': now,
        'updatedAt': now,
      });
    }
    if (_mediaLibrary.isNotEmpty) await _persistMediaLibrary();
  }

  Future<void> _persistMediaLibrary() async {
    final directory = _mediaDirectory;
    if (directory == null) return;
    final manifest = File('${directory.path}${Platform.pathSeparator}media_library.json');
    await manifest.writeAsString(jsonEncode(_mediaLibrary), flush: true);
  }

  int _libraryAssetIndex(String mediaId) =>
      _mediaLibrary.indexWhere((asset) => asset['mediaId'] == mediaId);

  Future<void> _handleMediaDelete(
    HttpRequest request,
    Map<String, dynamic> body,
  ) async {
    final mediaId = body['mediaId'];
    if (mediaId is! String ||
        !RegExp(r'^asset_[0-9]+\.(png|jpg|jpeg|gif|webp|apng|mp4|webm)
    final mediaId = body['mediaId'];
    final rawCategory = body['category'];
    if (mediaId is! String || rawCategory is! String) {
      await _sendText(request.response, HttpStatus.badRequest, 'Expected mediaId and category.');
      return;
    }
    final index = _libraryAssetIndex(mediaId);
    if (index < 0) {
      await _sendText(request.response, HttpStatus.notFound, 'Media asset not found.');
      return;
    }
    try {
      _mediaLibrary[index]['category'] =
          _mediaCategory(rawCategory, _mediaLibrary[index]['name'] as String);
    } on ArgumentError catch (error) {
      await _sendText(request.response, HttpStatus.badRequest, error.message?.toString() ?? 'Invalid category.');
      return;
    }
    _mediaLibrary[index]['updatedAt'] = DateTime.now().toIso8601String();
    await _persistMediaLibrary();
    await _sendJson(request.response, HttpStatus.ok, _mediaLibrary[index]);
  }

  Future<void> _handleMediaUpload(HttpRequest request) async {
    final name = request.uri.queryParameters['name'] ?? '';
    final dot = name.lastIndexOf('.');
    final extension = dot >= 0 ? name.substring(dot + 1).toLowerCase() : '';
    const imageExtensions = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'apng'};
    const videoExtensions = {'mp4', 'webm'};
    if (!imageExtensions.contains(extension) &&
        !videoExtensions.contains(extension)) {
      await _sendText(
        request.response,
        HttpStatus.unsupportedMediaType,
        'Unsupported media format. Use PNG, JPG, GIF, WebP, APNG, MP4 or WebM. AVI is not reliably supported by browser sources; convert it to MP4.',
      );
      return;
    }

    final directory = _mediaDirectory;
    if (directory == null) {
      await _sendText(request.response, HttpStatus.serviceUnavailable, 'Media storage is unavailable.');
      return;
    }

    const maxBytes = 50 * 1024 * 1024;
    final builder = BytesBuilder(copy: false);
    var total = 0;
    await for (final chunk in request) {
      total += chunk.length;
      if (total > maxBytes) {
        await _sendText(
          request.response,
          HttpStatus.requestEntityTooLarge,
          'Media files must be 50 MB or smaller.',
        );
        return;
      }
      builder.add(chunk);
    }
    if (total == 0) {
      await _sendText(request.response, HttpStatus.badRequest, 'The selected file is empty.');
      return;
    }

    final bytes = builder.takeBytes();
    if (!_looksLikeMedia(extension, bytes)) {
      await _sendText(
        request.response,
        HttpStatus.badRequest,
        'The selected file does not look like a valid .$extension file. Check the file or convert it to a supported format.',
      );
      return;
    }

    final safeName = name.length > 255 ? name.substring(name.length - 255) : name;
    final digest = sha256.convert(bytes).toString();
    late final String category;
    try {
      category = _mediaCategory(request.uri.queryParameters['category'], safeName);
    } on ArgumentError catch (error) {
      await _sendText(request.response, HttpStatus.badRequest, error.message?.toString() ?? 'Invalid category.');
      return;
    }

    final replaceId = request.uri.queryParameters['replaceMediaId'];
    if (replaceId != null && replaceId.isNotEmpty) {
      final index = _libraryAssetIndex(replaceId);
      if (index < 0) {
        await _sendText(request.response, HttpStatus.notFound, 'The asset selected for replacement no longer exists.');
        return;
      }
      final existing = _mediaLibrary[index];
      final existingId = existing['mediaId'] as String;
      final dotIndex = existingId.lastIndexOf('.');
      final existingExtension = dotIndex >= 0 ? existingId.substring(dotIndex + 1) : '';
      if (existingExtension != extension) {
        await _sendText(
          request.response,
          HttpStatus.badRequest,
          'Replacement must use the same file extension as the existing asset so all assignments keep a valid media URL.',
        );
        return;
      }
      final target = File('${directory.path}${Platform.pathSeparator}$existingId');
      await target.writeAsBytes(bytes, flush: true);
      existing['name'] = safeName;
      existing['category'] = category;
      existing['sizeBytes'] = total;
      existing['sha256'] = digest;
      existing['mimeType'] = _mediaContentType(extension).mimeType;
      existing['updatedAt'] = DateTime.now().toIso8601String();
      await _persistMediaLibrary();
      await _refreshAssignedEventMetadata(existing);
      await _sendJson(request.response, HttpStatus.ok, {...existing, 'replaced': true});
      return;
    }

    final duplicateIndex = _mediaLibrary.indexWhere((asset) => asset['sha256'] == digest);
    if (duplicateIndex >= 0) {
      final existing = _mediaLibrary[duplicateIndex];
      final duplicateAction = request.uri.queryParameters['duplicateAction'];
      if (duplicateAction == 'skip') {
        await _sendJson(request.response, HttpStatus.ok, {
          ...existing,
          'duplicate': true,
          'skipped': true,
        });
        return;
      }
      if (duplicateAction != 'replace' ||
          request.uri.queryParameters['replaceDuplicateId'] != existing['mediaId']) {
        await _sendJson(request.response, HttpStatus.conflict, {
          'duplicate': true,
          'message': 'Identical file content already exists in the media library.',
          'existing': existing,
        });
        return;
      }
      existing['name'] = safeName;
      existing['category'] = category;
      existing['updatedAt'] = DateTime.now().toIso8601String();
      await _persistMediaLibrary();
      await _refreshAssignedEventMetadata(existing);
      await _sendJson(request.response, HttpStatus.ok, {
        ...existing,
        'duplicate': true,
        'replaced': true,
      });
      return;
    }

    final filename = 'asset_${DateTime.now().microsecondsSinceEpoch}.$extension';
    final file = File('${directory.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(bytes, flush: true);
    final now = DateTime.now().toIso8601String();
    final asset = <String, Object?>{
      'mediaId': filename,
      'name': safeName,
      'category': category,
      'url': '/broadcast/media/$filename',
      'mediaType': const {'png','jpg','jpeg','gif','webp','apng'}.contains(extension) ? 'image' : 'video',
      'mimeType': _mediaContentType(extension).mimeType,
      'sizeBytes': total,
      'sha256': digest,
      'createdAt': now,
      'updatedAt': now,
    };
    _mediaLibrary.add(asset);
    await _persistMediaLibrary();
    await _sendJson(request.response, HttpStatus.created, asset);
  }

  bool _looksLikeMedia(String extension, Uint8List bytes) {
    bool hasPrefix(List<int> signature) {
      if (bytes.length < signature.length) return false;
      for (var i = 0; i < signature.length; i++) {
        if (bytes[i] != signature[i]) return false;
      }
      return true;
    }

    bool hasAsciiAt(int offset, String value) {
      final expected = ascii.encode(value);
      if (bytes.length < offset + expected.length) return false;
      for (var i = 0; i < expected.length; i++) {
        if (bytes[offset + i] != expected[i]) return false;
      }
      return true;
    }

    switch (extension) {
      case 'png':
        return hasPrefix([137, 80, 78, 71, 13, 10, 26, 10]);
      case 'apng':
        if (!hasPrefix([137, 80, 78, 71, 13, 10, 26, 10])) return false;
        for (var i = 8; i + 4 <= bytes.length; i++) {
          if (hasAsciiAt(i, 'acTL')) return true;
        }
        return false;
      case 'jpg':
      case 'jpeg':
        return hasPrefix([255, 216, 255]);
      case 'gif':
        return hasPrefix(ascii.encode('GIF87a')) ||
            hasPrefix(ascii.encode('GIF89a'));
      case 'webp':
        return hasPrefix(ascii.encode('RIFF')) && hasAsciiAt(8, 'WEBP');
      case 'mp4':
        return bytes.length >= 12 && hasAsciiAt(4, 'ftyp');
      case 'webm':
        return hasPrefix([0x1a, 0x45, 0xdf, 0xa3]);
      default:
        return false;
    }
  }

  ContentType _mediaContentType(String extension) => switch (extension) {
        'png' => ContentType('image', 'png'),
        'jpg' || 'jpeg' => ContentType('image', 'jpeg'),
        'gif' => ContentType('image', 'gif'),
        'webp' => ContentType('image', 'webp'),
        'apng' => ContentType('image', 'apng'),
        'mp4' => ContentType('video', 'mp4'),
        'webm' => ContentType('video', 'webm'),
        _ => ContentType.binary,
      };

  Future<void> _serveMedia(HttpRequest request, String path) async {
    final filename = path.substring('/broadcast/media/'.length);
    if (!RegExp(r'^asset_[0-9]+\.(png|jpg|jpeg|gif|webp|apng|mp4|webm)$')
        .hasMatch(filename)) {
      await _sendText(request.response, HttpStatus.notFound, 'Media not found.');
      return;
    }
    final directory = _mediaDirectory;
    if (directory == null) {
      await _sendText(request.response, HttpStatus.notFound, 'Media not found.');
      return;
    }
    final file = File('${directory.path}${Platform.pathSeparator}$filename');
    if (!await file.exists()) {
      await _sendText(request.response, HttpStatus.notFound, 'Media not found.');
      return;
    }
    final dot = filename.lastIndexOf('.');
    final extension = filename.substring(dot + 1);
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = _mediaContentType(extension);
    request.response.headers.set(HttpHeaders.cacheControlHeader, 'public, max-age=31536000, immutable');
    request.response.headers.set('X-Content-Type-Options', 'nosniff');
    await request.response.addStream(file.openRead());
    await request.response.close();
  }

  Future<void> _handleControl(HttpRequest request, Map<String, dynamic> body) async {
    final coordinator = _coordinator!;
    switch (request.uri.path) {
      case '/api/v1/broadcast/layout':
        final rawLayout = body['layout'];
        if (rawLayout is! Map<String, dynamic>) {
          await _sendText(request.response, HttpStatus.badRequest, 'Expected a layout object.');
          return;
        }
        final parsedLayout = <String, Map<String, double>>{};
        for (final entry in rawLayout.entries) {
          if (entry.value is! Map<String, dynamic>) {
            await _sendText(request.response, HttpStatus.badRequest, 'Each layout layer must be an object.');
            return;
          }
          final rawRect = entry.value as Map<String, dynamic>;
          const fields = ['x', 'y', 'width', 'height'];
          if (rawRect.keys.toSet().length != fields.length ||
              !fields.every(rawRect.containsKey) ||
              fields.any((field) => rawRect[field] is! num)) {
            await _sendText(request.response, HttpStatus.badRequest, 'Each layer needs numeric x, y, width, and height.');
            return;
          }
          parsedLayout[entry.key] = {
            for (final field in fields) field: (rawRect[field] as num).toDouble(),
          };
        }
        try {
          coordinator.setLayout(parsedLayout);
        } on ArgumentError catch (error) {
          await _sendText(request.response, HttpStatus.badRequest, error.message?.toString() ?? 'Invalid layout.');
          return;
        }
        break;
      case '/api/v1/broadcast/scorecard-style':
        final name = body['style'];
        if (name is! String) {
          await _sendText(request.response, HttpStatus.badRequest, 'Expected a scorecard style.');
          return;
        }
        final style = BroadcastScorecardStyleJson.fromWireValue(name);
        if (style == null) {
          await _sendText(request.response, HttpStatus.badRequest, 'Unknown scorecard style.');
          return;
        }
        coordinator.setScorecardStyle(style);
        break;
      case '/api/v1/broadcast/overlay':
        final name = body['overlay'];
        final enabled = body['enabled'];
        if (name is! String || enabled is! bool) {
          await _sendText(request.response, HttpStatus.badRequest, 'Expected overlay and enabled.');
          return;
        }
        final overlay = BroadcastOverlayJson.fromWireValue(name);
        if (overlay == null) {
          await _sendText(request.response, HttpStatus.badRequest, 'Unknown overlay.');
          return;
        }
        coordinator.setOverlayEnabled(overlay, enabled);
        break;
      case '/api/v1/broadcast/overlays':
        final enabled = body['enabled'];
        if (enabled is! bool) {
          await _sendText(request.response, HttpStatus.badRequest, 'Expected enabled.');
          return;
        }
        coordinator.setAllOverlaysEnabled(enabled);
        break;
      case '/api/v1/broadcast/ticker':
        final text = body['text'];
        if (text is! String || text.length > 280) {
          await _sendText(request.response, HttpStatus.badRequest, 'Ticker text must be 1-280 characters.');
          return;
        }
        coordinator.showTicker(text, duration: _duration(body['durationSeconds'], fallback: 12));
        break;
      case '/api/v1/broadcast/lower-third':
        final title = body['title'];
        final detail = body['detail'];
        if (title is! String || title.length > 80 ||
            (detail != null && detail is! String) ||
            (detail is String && detail.length > 180)) {
          await _sendText(request.response, HttpStatus.badRequest, 'Invalid lower-third text.');
          return;
        }
        coordinator.showLowerThird(
          title: title,
          detail: detail as String?,
          duration: _duration(body['durationSeconds'], fallback: 8),
        );
        break;
      case '/api/v1/broadcast/media/category':
        await _handleMediaCategory(request, body);
        return;
      case '/api/v1/broadcast/media/delete':
        await _handleMediaDelete(request, body);
        return;
      case '/api/v1/broadcast/event-playback':
        final enabled = body['enabled'];
        if (enabled is! bool) {
          await _sendText(
            request.response,
            HttpStatus.badRequest,
            'Expected enabled to be a boolean.',
          );
          return;
        }
        coordinator.setAutomaticEventPlaybackEnabled(enabled);
        await _persistEventMediaSettings();
        break;
      case '/api/v1/broadcast/event-settings':
        final slot = body['slot'];
        final name = body['name'];
        final mediaId = body['mediaId'];
        final mediaName = body['mediaName'];
        final mediaUrl = body['mediaUrl'];
        final mediaType = body['mediaType'];
        final loop = body['loop'];
        final durationSeconds = body['durationSeconds'];
        if (slot is! String ||
            (name != null && name is! String) ||
            (mediaId != null && mediaId is! String) ||
            (mediaName != null && mediaName is! String) ||
            (mediaUrl != null && mediaUrl is! String) ||
            (mediaType != null && mediaType is! String) ||
            (loop != null && loop is! bool) ||
            (durationSeconds != null && durationSeconds is! num)) {
          await _sendText(request.response, HttpStatus.badRequest, 'Invalid event media assignment.');
          return;
        }
        try {
          coordinator.setEventMediaSettings(
            slot: slot,
            name: name as String?,
            mediaId: mediaId as String?,
            mediaName: mediaName as String?,
            mediaUrl: mediaUrl as String?,
            mediaType: mediaType as String?,
            loop: loop as bool?,
            durationSeconds: durationSeconds is num ? durationSeconds.toInt() : null,
            clearMedia: body['clearMedia'] == true,
          );
          await _persistEventMediaSettings();
        } on ArgumentError catch (error) {
          await _sendText(
            request.response,
            HttpStatus.badRequest,
            error.message?.toString() ?? 'Invalid event media assignment.',
          );
          return;
        }
        break;
      case '/api/v1/broadcast/event':
        final kind = body['kind'];
        final detail = body['detail'];
        final mediaUrl = body['mediaUrl'];
        final mediaType = body['mediaType'];
        final loop = body['loop'];
        if (kind is! String || kind.length > 24 ||
            (detail != null && detail is! String) ||
            (detail is String && detail.length > 180) ||
            (mediaUrl != null && mediaUrl is! String) ||
            (mediaType != null && mediaType is! String) ||
            (loop != null && loop is! bool)) {
          await _sendText(request.response, HttpStatus.badRequest, 'Invalid event graphic.');
          return;
        }
        coordinator.triggerEvent(
          kind: kind,
          detail: detail as String?,
          duration: body['durationSeconds'] is num
              ? _duration(body['durationSeconds'], fallback: 5)
              : null,
          mediaUrl: mediaUrl as String?,
          mediaType: mediaType as String?,
          loop: loop as bool?,
        );
        break;
      case '/api/v1/broadcast/clear':
        final kind = body['kind'] as String? ?? 'messages';
        switch (kind) {
          case 'ticker':
            coordinator.clearTicker();
            break;
          case 'lowerThird':
            coordinator.clearLowerThird();
            break;
          case 'event':
            coordinator.clearEvent();
            break;
          case 'messages':
            coordinator.clearMessages();
            break;
          case 'all':
            coordinator.clearMessages();
            coordinator.setAllOverlaysEnabled(false);
            break;
          default:
            await _sendText(request.response, HttpStatus.badRequest, 'Unknown clear target.');
            return;
        }
        break;
      default:
        await _sendText(request.response, HttpStatus.notFound, 'Not found.');
        return;
    }

    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
  }

  Duration _duration(Object? value, {required int fallback}) {
    final seconds = value is num ? value.round() : fallback;
    return Duration(seconds: seconds.clamp(1, 120).toInt());
  }

  String? _pageForPath(String path) => switch (path) {
        '/' || '/broadcast' || '/broadcast/manage' => broadcastManagerHtml,
        '/broadcast/output' => broadcastCompositeOutputHtml,
        '/broadcast/scorecard' => broadcastScorecardHtml,
        '/broadcast/ticker' => broadcastTickerHtml,
        '/broadcast/lower-third' => broadcastLowerThirdHtml,
        '/broadcast/last-ball' => broadcastLastBallHtml,
        _ => null,
      };

  Future<void> _sendHtml(HttpResponse response, String html) async {
    response.statusCode = HttpStatus.ok;
    response.headers.contentType = ContentType.html;
    response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    response.write(html);
    await response.close();
  }

  Future<void> _sendJson(HttpResponse response, int status, Object? value) async {
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    response.write(jsonEncode(value));
    await response.close();
  }

  Future<void> _sendText(HttpResponse response, int status, String value) async {
    response.statusCode = status;
    response.headers.contentType = ContentType.text;
    response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    response.write(value);
    await response.close();
  }
}

BroadcastHttpServerBase createBroadcastHttpServer({
  String? mediaDirectoryPath,
}) =>
    _IoBroadcastHttpServer(mediaDirectoryPath: mediaDirectoryPath);
)
            .hasMatch(mediaId)) {
      await _sendText(request.response, HttpStatus.badRequest, 'Expected a valid mediaId.');
      return;
    }

    final index = _libraryAssetIndex(mediaId);
    if (index < 0) {
      await _sendText(request.response, HttpStatus.notFound, 'Media asset not found.');
      return;
    }
    final coordinator = _coordinator;
    final directory = _mediaDirectory;
    if (coordinator == null || directory == null) {
      await _sendText(request.response, HttpStatus.serviceUnavailable, 'Media library is unavailable.');
      return;
    }

    List<String> findAssignedSlots() => coordinator.eventMediaSettings.entries
        .where((entry) => entry.value['mediaId'] == mediaId)
        .map((entry) => entry.key)
        .toList()
      ..sort();

    final assignedSlots = findAssignedSlots();
    if (body['confirm'] != true) {
      await _sendJson(request.response, HttpStatus.conflict, {
        'requiresConfirmation': true,
        'mediaId': mediaId,
        'name': _mediaLibrary[index]['name'],
        'assignedSlots': assignedSlots,
        'message': assignedSlots.isEmpty
            ? 'Confirm deletion of this media asset.'
            : 'This media asset is assigned to the listed event slots. Confirming will delete the asset and clear those assignments.',
      });
      return;
    }

    final expectedRaw = body['expectedAssignedSlots'];
    if (expectedRaw is! List || expectedRaw.any((value) => value is! String)) {
      await _sendText(
        request.response,
        HttpStatus.badRequest,
        'Expected the assigned-slot list shown in the confirmation prompt.',
      );
      return;
    }
    final expectedSlots = expectedRaw.cast<String>().toSet();
    if (expectedSlots.length != expectedRaw.length ||
        expectedSlots.difference(assignedSlots.toSet()).isNotEmpty ||
        assignedSlots.toSet().difference(expectedSlots).isNotEmpty) {
      await _sendJson(request.response, HttpStatus.conflict, {
        'requiresConfirmation': true,
        'assignmentsChanged': true,
        'mediaId': mediaId,
        'name': _mediaLibrary[index]['name'],
        'assignedSlots': assignedSlots,
        'message': 'Event assignments changed after the confirmation prompt. Review the current assignments before deleting.',
      });
      return;
    }

    final asset = Map<String, Object?>.from(_mediaLibrary[index]);
    final file = File('${directory.path}${Platform.pathSeparator}$mediaId');
    if (!await file.exists()) {
      await _sendText(request.response, HttpStatus.notFound, 'The media file is missing from local storage.');
      return;
    }
    final pendingFile = File('${file.path}.delete-pending');
    if (await pendingFile.exists()) {
      await _sendText(request.response, HttpStatus.conflict, 'This media asset is already being deleted.');
      return;
    }

    final priorSlotSettings = <String, Map<String, Object?>>{
      for (final slot in assignedSlots)
        slot: Map<String, Object?>.of(coordinator.eventMediaSettings[slot]!),
    };
    await file.rename(pendingFile.path);
    var removedFromLibrary = false;
    try {
      for (final slot in assignedSlots) {
        coordinator.setEventMediaSettings(slot: slot, clearMedia: true);
      }
      _mediaLibrary.removeAt(index);
      removedFromLibrary = true;
      await _persistEventMediaSettings();
      await _persistMediaLibrary();
    } catch (error) {
      if (removedFromLibrary) _mediaLibrary.insert(index, asset);
      for (final entry in priorSlotSettings.entries) {
        final value = entry.value;
        coordinator.setEventMediaSettings(
          slot: entry.key,
          name: value['name'] as String?,
          mediaId: value['mediaId'] as String?,
          mediaName: value['mediaName'] as String?,
          mediaUrl: value['mediaUrl'] as String?,
          mediaType: value['mediaType'] as String?,
          loop: value['loop'] as bool?,
          durationSeconds: (value['durationSeconds'] as num?)?.toInt(),
        );
      }
      try {
        await _persistEventMediaSettings();
        await _persistMediaLibrary();
      } catch (_) {
        // Keep the original failure as the response; local files remain recoverable.
      }
      if (await pendingFile.exists() && !await file.exists()) {
        await pendingFile.rename(file.path);
      }
      await _sendText(
        request.response,
        HttpStatus.internalServerError,
        'Deletion could not be saved. Event assignments were restored; the asset was not intentionally removed.',
      );
      return;
    }

    var cleanupPending = false;
    try {
      await pendingFile.delete();
    } catch (error) {
      cleanupPending = true;
      stderr.writeln('Deleted media asset $mediaId from the library but could not remove its pending file: $error');
    }
    await _sendJson(request.response, HttpStatus.ok, {
      'deleted': true,
      'mediaId': mediaId,
      'name': asset['name'],
      'clearedAssignments': assignedSlots,
      'cleanupPending': cleanupPending,
    });
  }

  Future<void> _handleMediaCategory(HttpRequest request, Map<String, dynamic> body) async {
    final mediaId = body['mediaId'];
    final rawCategory = body['category'];
    if (mediaId is! String || rawCategory is! String) {
      await _sendText(request.response, HttpStatus.badRequest, 'Expected mediaId and category.');
      return;
    }
    final index = _libraryAssetIndex(mediaId);
    if (index < 0) {
      await _sendText(request.response, HttpStatus.notFound, 'Media asset not found.');
      return;
    }
    try {
      _mediaLibrary[index]['category'] =
          _mediaCategory(rawCategory, _mediaLibrary[index]['name'] as String);
    } on ArgumentError catch (error) {
      await _sendText(request.response, HttpStatus.badRequest, error.message?.toString() ?? 'Invalid category.');
      return;
    }
    _mediaLibrary[index]['updatedAt'] = DateTime.now().toIso8601String();
    await _persistMediaLibrary();
    await _sendJson(request.response, HttpStatus.ok, _mediaLibrary[index]);
  }

  Future<void> _handleMediaUpload(HttpRequest request) async {
    final name = request.uri.queryParameters['name'] ?? '';
    final dot = name.lastIndexOf('.');
    final extension = dot >= 0 ? name.substring(dot + 1).toLowerCase() : '';
    const imageExtensions = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'apng'};
    const videoExtensions = {'mp4', 'webm'};
    if (!imageExtensions.contains(extension) &&
        !videoExtensions.contains(extension)) {
      await _sendText(
        request.response,
        HttpStatus.unsupportedMediaType,
        'Unsupported media format. Use PNG, JPG, GIF, WebP, APNG, MP4 or WebM. AVI is not reliably supported by browser sources; convert it to MP4.',
      );
      return;
    }

    final directory = _mediaDirectory;
    if (directory == null) {
      await _sendText(request.response, HttpStatus.serviceUnavailable, 'Media storage is unavailable.');
      return;
    }

    const maxBytes = 50 * 1024 * 1024;
    final builder = BytesBuilder(copy: false);
    var total = 0;
    await for (final chunk in request) {
      total += chunk.length;
      if (total > maxBytes) {
        await _sendText(
          request.response,
          HttpStatus.requestEntityTooLarge,
          'Media files must be 50 MB or smaller.',
        );
        return;
      }
      builder.add(chunk);
    }
    if (total == 0) {
      await _sendText(request.response, HttpStatus.badRequest, 'The selected file is empty.');
      return;
    }

    final bytes = builder.takeBytes();
    if (!_looksLikeMedia(extension, bytes)) {
      await _sendText(
        request.response,
        HttpStatus.badRequest,
        'The selected file does not look like a valid .$extension file. Check the file or convert it to a supported format.',
      );
      return;
    }

    final safeName = name.length > 255 ? name.substring(name.length - 255) : name;
    final digest = sha256.convert(bytes).toString();
    late final String category;
    try {
      category = _mediaCategory(request.uri.queryParameters['category'], safeName);
    } on ArgumentError catch (error) {
      await _sendText(request.response, HttpStatus.badRequest, error.message?.toString() ?? 'Invalid category.');
      return;
    }

    final replaceId = request.uri.queryParameters['replaceMediaId'];
    if (replaceId != null && replaceId.isNotEmpty) {
      final index = _libraryAssetIndex(replaceId);
      if (index < 0) {
        await _sendText(request.response, HttpStatus.notFound, 'The asset selected for replacement no longer exists.');
        return;
      }
      final existing = _mediaLibrary[index];
      final existingId = existing['mediaId'] as String;
      final dotIndex = existingId.lastIndexOf('.');
      final existingExtension = dotIndex >= 0 ? existingId.substring(dotIndex + 1) : '';
      if (existingExtension != extension) {
        await _sendText(
          request.response,
          HttpStatus.badRequest,
          'Replacement must use the same file extension as the existing asset so all assignments keep a valid media URL.',
        );
        return;
      }
      final target = File('${directory.path}${Platform.pathSeparator}$existingId');
      await target.writeAsBytes(bytes, flush: true);
      existing['name'] = safeName;
      existing['category'] = category;
      existing['sizeBytes'] = total;
      existing['sha256'] = digest;
      existing['mimeType'] = _mediaContentType(extension).mimeType;
      existing['updatedAt'] = DateTime.now().toIso8601String();
      await _persistMediaLibrary();
      await _refreshAssignedEventMetadata(existing);
      await _sendJson(request.response, HttpStatus.ok, {...existing, 'replaced': true});
      return;
    }

    final duplicateIndex = _mediaLibrary.indexWhere((asset) => asset['sha256'] == digest);
    if (duplicateIndex >= 0) {
      final existing = _mediaLibrary[duplicateIndex];
      final duplicateAction = request.uri.queryParameters['duplicateAction'];
      if (duplicateAction == 'skip') {
        await _sendJson(request.response, HttpStatus.ok, {
          ...existing,
          'duplicate': true,
          'skipped': true,
        });
        return;
      }
      if (duplicateAction != 'replace' ||
          request.uri.queryParameters['replaceDuplicateId'] != existing['mediaId']) {
        await _sendJson(request.response, HttpStatus.conflict, {
          'duplicate': true,
          'message': 'Identical file content already exists in the media library.',
          'existing': existing,
        });
        return;
      }
      existing['name'] = safeName;
      existing['category'] = category;
      existing['updatedAt'] = DateTime.now().toIso8601String();
      await _persistMediaLibrary();
      await _refreshAssignedEventMetadata(existing);
      await _sendJson(request.response, HttpStatus.ok, {
        ...existing,
        'duplicate': true,
        'replaced': true,
      });
      return;
    }

    final filename = 'asset_${DateTime.now().microsecondsSinceEpoch}.$extension';
    final file = File('${directory.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(bytes, flush: true);
    final now = DateTime.now().toIso8601String();
    final asset = <String, Object?>{
      'mediaId': filename,
      'name': safeName,
      'category': category,
      'url': '/broadcast/media/$filename',
      'mediaType': const {'png','jpg','jpeg','gif','webp','apng'}.contains(extension) ? 'image' : 'video',
      'mimeType': _mediaContentType(extension).mimeType,
      'sizeBytes': total,
      'sha256': digest,
      'createdAt': now,
      'updatedAt': now,
    };
    _mediaLibrary.add(asset);
    await _persistMediaLibrary();
    await _sendJson(request.response, HttpStatus.created, asset);
  }

  bool _looksLikeMedia(String extension, Uint8List bytes) {
    bool hasPrefix(List<int> signature) {
      if (bytes.length < signature.length) return false;
      for (var i = 0; i < signature.length; i++) {
        if (bytes[i] != signature[i]) return false;
      }
      return true;
    }

    bool hasAsciiAt(int offset, String value) {
      final expected = ascii.encode(value);
      if (bytes.length < offset + expected.length) return false;
      for (var i = 0; i < expected.length; i++) {
        if (bytes[offset + i] != expected[i]) return false;
      }
      return true;
    }

    switch (extension) {
      case 'png':
        return hasPrefix([137, 80, 78, 71, 13, 10, 26, 10]);
      case 'apng':
        if (!hasPrefix([137, 80, 78, 71, 13, 10, 26, 10])) return false;
        for (var i = 8; i + 4 <= bytes.length; i++) {
          if (hasAsciiAt(i, 'acTL')) return true;
        }
        return false;
      case 'jpg':
      case 'jpeg':
        return hasPrefix([255, 216, 255]);
      case 'gif':
        return hasPrefix(ascii.encode('GIF87a')) ||
            hasPrefix(ascii.encode('GIF89a'));
      case 'webp':
        return hasPrefix(ascii.encode('RIFF')) && hasAsciiAt(8, 'WEBP');
      case 'mp4':
        return bytes.length >= 12 && hasAsciiAt(4, 'ftyp');
      case 'webm':
        return hasPrefix([0x1a, 0x45, 0xdf, 0xa3]);
      default:
        return false;
    }
  }

  ContentType _mediaContentType(String extension) => switch (extension) {
        'png' => ContentType('image', 'png'),
        'jpg' || 'jpeg' => ContentType('image', 'jpeg'),
        'gif' => ContentType('image', 'gif'),
        'webp' => ContentType('image', 'webp'),
        'apng' => ContentType('image', 'apng'),
        'mp4' => ContentType('video', 'mp4'),
        'webm' => ContentType('video', 'webm'),
        _ => ContentType.binary,
      };

  Future<void> _serveMedia(HttpRequest request, String path) async {
    final filename = path.substring('/broadcast/media/'.length);
    if (!RegExp(r'^asset_[0-9]+\.(png|jpg|jpeg|gif|webp|apng|mp4|webm)$')
        .hasMatch(filename)) {
      await _sendText(request.response, HttpStatus.notFound, 'Media not found.');
      return;
    }
    final directory = _mediaDirectory;
    if (directory == null) {
      await _sendText(request.response, HttpStatus.notFound, 'Media not found.');
      return;
    }
    final file = File('${directory.path}${Platform.pathSeparator}$filename');
    if (!await file.exists()) {
      await _sendText(request.response, HttpStatus.notFound, 'Media not found.');
      return;
    }
    final dot = filename.lastIndexOf('.');
    final extension = filename.substring(dot + 1);
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = _mediaContentType(extension);
    request.response.headers.set(HttpHeaders.cacheControlHeader, 'public, max-age=31536000, immutable');
    request.response.headers.set('X-Content-Type-Options', 'nosniff');
    await request.response.addStream(file.openRead());
    await request.response.close();
  }

  Future<void> _handleControl(HttpRequest request, Map<String, dynamic> body) async {
    final coordinator = _coordinator!;
    switch (request.uri.path) {
      case '/api/v1/broadcast/layout':
        final rawLayout = body['layout'];
        if (rawLayout is! Map<String, dynamic>) {
          await _sendText(request.response, HttpStatus.badRequest, 'Expected a layout object.');
          return;
        }
        final parsedLayout = <String, Map<String, double>>{};
        for (final entry in rawLayout.entries) {
          if (entry.value is! Map<String, dynamic>) {
            await _sendText(request.response, HttpStatus.badRequest, 'Each layout layer must be an object.');
            return;
          }
          final rawRect = entry.value as Map<String, dynamic>;
          const fields = ['x', 'y', 'width', 'height'];
          if (rawRect.keys.toSet().length != fields.length ||
              !fields.every(rawRect.containsKey) ||
              fields.any((field) => rawRect[field] is! num)) {
            await _sendText(request.response, HttpStatus.badRequest, 'Each layer needs numeric x, y, width, and height.');
            return;
          }
          parsedLayout[entry.key] = {
            for (final field in fields) field: (rawRect[field] as num).toDouble(),
          };
        }
        try {
          coordinator.setLayout(parsedLayout);
        } on ArgumentError catch (error) {
          await _sendText(request.response, HttpStatus.badRequest, error.message?.toString() ?? 'Invalid layout.');
          return;
        }
        break;
      case '/api/v1/broadcast/scorecard-style':
        final name = body['style'];
        if (name is! String) {
          await _sendText(request.response, HttpStatus.badRequest, 'Expected a scorecard style.');
          return;
        }
        final style = BroadcastScorecardStyleJson.fromWireValue(name);
        if (style == null) {
          await _sendText(request.response, HttpStatus.badRequest, 'Unknown scorecard style.');
          return;
        }
        coordinator.setScorecardStyle(style);
        break;
      case '/api/v1/broadcast/overlay':
        final name = body['overlay'];
        final enabled = body['enabled'];
        if (name is! String || enabled is! bool) {
          await _sendText(request.response, HttpStatus.badRequest, 'Expected overlay and enabled.');
          return;
        }
        final overlay = BroadcastOverlayJson.fromWireValue(name);
        if (overlay == null) {
          await _sendText(request.response, HttpStatus.badRequest, 'Unknown overlay.');
          return;
        }
        coordinator.setOverlayEnabled(overlay, enabled);
        break;
      case '/api/v1/broadcast/overlays':
        final enabled = body['enabled'];
        if (enabled is! bool) {
          await _sendText(request.response, HttpStatus.badRequest, 'Expected enabled.');
          return;
        }
        coordinator.setAllOverlaysEnabled(enabled);
        break;
      case '/api/v1/broadcast/ticker':
        final text = body['text'];
        if (text is! String || text.length > 280) {
          await _sendText(request.response, HttpStatus.badRequest, 'Ticker text must be 1-280 characters.');
          return;
        }
        coordinator.showTicker(text, duration: _duration(body['durationSeconds'], fallback: 12));
        break;
      case '/api/v1/broadcast/lower-third':
        final title = body['title'];
        final detail = body['detail'];
        if (title is! String || title.length > 80 ||
            (detail != null && detail is! String) ||
            (detail is String && detail.length > 180)) {
          await _sendText(request.response, HttpStatus.badRequest, 'Invalid lower-third text.');
          return;
        }
        coordinator.showLowerThird(
          title: title,
          detail: detail as String?,
          duration: _duration(body['durationSeconds'], fallback: 8),
        );
        break;
      case '/api/v1/broadcast/media/category':
        await _handleMediaCategory(request, body);
        return;
      case '/api/v1/broadcast/event-playback':
        final enabled = body['enabled'];
        if (enabled is! bool) {
          await _sendText(
            request.response,
            HttpStatus.badRequest,
            'Expected enabled to be a boolean.',
          );
          return;
        }
        coordinator.setAutomaticEventPlaybackEnabled(enabled);
        await _persistEventMediaSettings();
        break;
      case '/api/v1/broadcast/event-settings':
        final slot = body['slot'];
        final name = body['name'];
        final mediaId = body['mediaId'];
        final mediaName = body['mediaName'];
        final mediaUrl = body['mediaUrl'];
        final mediaType = body['mediaType'];
        final loop = body['loop'];
        final durationSeconds = body['durationSeconds'];
        if (slot is! String ||
            (name != null && name is! String) ||
            (mediaId != null && mediaId is! String) ||
            (mediaName != null && mediaName is! String) ||
            (mediaUrl != null && mediaUrl is! String) ||
            (mediaType != null && mediaType is! String) ||
            (loop != null && loop is! bool) ||
            (durationSeconds != null && durationSeconds is! num)) {
          await _sendText(request.response, HttpStatus.badRequest, 'Invalid event media assignment.');
          return;
        }
        try {
          coordinator.setEventMediaSettings(
            slot: slot,
            name: name as String?,
            mediaId: mediaId as String?,
            mediaName: mediaName as String?,
            mediaUrl: mediaUrl as String?,
            mediaType: mediaType as String?,
            loop: loop as bool?,
            durationSeconds: durationSeconds is num ? durationSeconds.toInt() : null,
            clearMedia: body['clearMedia'] == true,
          );
          await _persistEventMediaSettings();
        } on ArgumentError catch (error) {
          await _sendText(
            request.response,
            HttpStatus.badRequest,
            error.message?.toString() ?? 'Invalid event media assignment.',
          );
          return;
        }
        break;
      case '/api/v1/broadcast/event':
        final kind = body['kind'];
        final detail = body['detail'];
        final mediaUrl = body['mediaUrl'];
        final mediaType = body['mediaType'];
        final loop = body['loop'];
        if (kind is! String || kind.length > 24 ||
            (detail != null && detail is! String) ||
            (detail is String && detail.length > 180) ||
            (mediaUrl != null && mediaUrl is! String) ||
            (mediaType != null && mediaType is! String) ||
            (loop != null && loop is! bool)) {
          await _sendText(request.response, HttpStatus.badRequest, 'Invalid event graphic.');
          return;
        }
        coordinator.triggerEvent(
          kind: kind,
          detail: detail as String?,
          duration: body['durationSeconds'] is num
              ? _duration(body['durationSeconds'], fallback: 5)
              : null,
          mediaUrl: mediaUrl as String?,
          mediaType: mediaType as String?,
          loop: loop as bool?,
        );
        break;
      case '/api/v1/broadcast/clear':
        final kind = body['kind'] as String? ?? 'messages';
        switch (kind) {
          case 'ticker':
            coordinator.clearTicker();
            break;
          case 'lowerThird':
            coordinator.clearLowerThird();
            break;
          case 'event':
            coordinator.clearEvent();
            break;
          case 'messages':
            coordinator.clearMessages();
            break;
          case 'all':
            coordinator.clearMessages();
            coordinator.setAllOverlaysEnabled(false);
            break;
          default:
            await _sendText(request.response, HttpStatus.badRequest, 'Unknown clear target.');
            return;
        }
        break;
      default:
        await _sendText(request.response, HttpStatus.notFound, 'Not found.');
        return;
    }

    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
  }

  Duration _duration(Object? value, {required int fallback}) {
    final seconds = value is num ? value.round() : fallback;
    return Duration(seconds: seconds.clamp(1, 120).toInt());
  }

  String? _pageForPath(String path) => switch (path) {
        '/' || '/broadcast' || '/broadcast/manage' => broadcastManagerHtml,
        '/broadcast/output' => broadcastCompositeOutputHtml,
        '/broadcast/scorecard' => broadcastScorecardHtml,
        '/broadcast/ticker' => broadcastTickerHtml,
        '/broadcast/lower-third' => broadcastLowerThirdHtml,
        '/broadcast/last-ball' => broadcastLastBallHtml,
        _ => null,
      };

  Future<void> _sendHtml(HttpResponse response, String html) async {
    response.statusCode = HttpStatus.ok;
    response.headers.contentType = ContentType.html;
    response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    response.write(html);
    await response.close();
  }

  Future<void> _sendJson(HttpResponse response, int status, Object? value) async {
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    response.write(jsonEncode(value));
    await response.close();
  }

  Future<void> _sendText(HttpResponse response, int status, String value) async {
    response.statusCode = status;
    response.headers.contentType = ContentType.text;
    response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    response.write(value);
    await response.close();
  }
}

BroadcastHttpServerBase createBroadcastHttpServer({
  String? mediaDirectoryPath,
}) =>
    _IoBroadcastHttpServer(mediaDirectoryPath: mediaDirectoryPath);
