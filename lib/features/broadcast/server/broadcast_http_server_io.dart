import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../state/broadcast_state_coordinator.dart';
import 'broadcast_http_server_stub.dart' show BroadcastHttpServerBase;
import 'broadcast_output_pages.dart';

export 'broadcast_http_server_stub.dart' show BroadcastHttpServerBase;

class _IoBroadcastHttpServer implements BroadcastHttpServerBase {
  HttpServer? _server;
  BroadcastStateCoordinator? _coordinator;

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

  Future<void> _handleControl(HttpRequest request, Map<String, dynamic> body) async {
    final coordinator = _coordinator!;
    switch (request.uri.path) {
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
      case '/api/v1/broadcast/event':
        final kind = body['kind'];
        final detail = body['detail'];
        if (kind is! String || kind.length > 24 ||
            (detail != null && detail is! String) ||
            (detail is String && detail.length > 180)) {
          await _sendText(request.response, HttpStatus.badRequest, 'Invalid event graphic.');
          return;
        }
        coordinator.triggerEvent(
          kind: kind,
          detail: detail as String?,
          duration: _duration(body['durationSeconds'], fallback: 5),
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

BroadcastHttpServerBase createBroadcastHttpServer() => _IoBroadcastHttpServer();
