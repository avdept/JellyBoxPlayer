import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:jplayer/src/core/network/server_location.dart';

typedef _Upstream = ({String? base, Uri uri});

typedef _Connection = ({String? base, Uri uri, HttpClientResponse response});

class StreamProxyServer {
  StreamProxyServer({
    required bool Function(Uri uri) shouldProxy,
    List<String> Function()? endpoints,
    void Function(String endpoint)? onEndpointSwitched,
    HttpClient Function()? httpClientFactory,
    Duration connectTimeout = const Duration(seconds: 5),
  }) : _shouldProxy = shouldProxy,
       _endpoints = endpoints,
       _onEndpointSwitched = onEndpointSwitched,
       _httpClientFactory = httpClientFactory ?? HttpClient.new,
       _connectTimeout = connectTimeout;

  static const _hopByHopHeaders = {
    'connection',
    'keep-alive',
    'proxy-authenticate',
    'proxy-authorization',
    'te',
    'trailer',
    'transfer-encoding',
    'upgrade',
    'host',
    'content-length',
  };

  static final _uriAttribute = RegExp('URI="([^"]*)"');

  final bool Function(Uri uri) _shouldProxy;
  final List<String> Function()? _endpoints;
  final void Function(String endpoint)? _onEndpointSwitched;
  final HttpClient Function() _httpClientFactory;
  final Duration _connectTimeout;
  final String _secret = _randomSecret();

  HttpClient? _client;
  HttpServer? _server;
  Future<HttpServer>? _starting;

  int? get port => _server?.port;

  Future<Uri> resolve(Uri uri) async {
    if (!_shouldProxy(uri)) return uri;
    final server = await _start();
    return _loopback(server.port, uri, 'u');
  }

  Future<Uri> forLocation(Uri location) async {
    final server = await _start();
    return _loopback(server.port, location, 'l');
  }

  Future<void> close() async {
    _client?.close(force: true);
    _client = null;
    final server = _server;
    _server = null;
    _starting = null;
    await server?.close(force: true);
  }

  Future<HttpServer> _start() {
    final running = _server;
    if (running != null) return Future.value(running);
    return _starting ??= _bind();
  }

  Future<HttpServer> _bind() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen(
      (request) => unawaited(_handle(request)),
      onError: (Object _) {},
    );
    _server = server;
    return server;
  }

  Uri _loopback(int port, Uri target, String key) {
    final name = target.pathSegments.isEmpty
        ? 'stream'
        : target.pathSegments.last;
    return Uri(
      scheme: 'http',
      host: InternetAddress.loopbackIPv4.address,
      port: port,
      pathSegments: [_secret, name],
      queryParameters: {key: base64Url.encode(utf8.encode(target.toString()))},
    );
  }

  List<_Upstream>? _upstreamsOf(HttpRequest request) {
    final segments = request.uri.pathSegments;
    if (segments.isEmpty || segments.first != _secret) return null;
    final absolute = request.uri.queryParameters['u'];
    final relative = request.uri.queryParameters['l'];
    try {
      if (absolute != null) {
        final target = Uri.parse(_decode(absolute));
        return _shouldProxy(target) ? [(base: null, uri: target)] : null;
      }
      if (relative != null) {
        final location = Uri.parse(_decode(relative));
        if (location.hasScheme || location.hasAuthority) return null;
        return [
          for (final base in _endpoints?.call() ?? const <String>[])
            (base: base, uri: joinServerLocation(base, location)),
        ];
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  static String _decode(String encoded) =>
      utf8.decode(base64Url.decode(encoded));

  Future<void> _handle(HttpRequest request) async {
    final upstreams = _upstreamsOf(request);
    if (upstreams == null || upstreams.isEmpty) {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close().catchError((_) {});
      return;
    }

    _Connection? connection;
    try {
      connection = await _connect(request, upstreams);
      final (:base, :uri, :response) = connection;

      if (_isPlaylist(response, uri)) {
        await _servePlaylist(request, response, uri, base);
        return;
      }

      request.response.statusCode = response.statusCode;
      _copyResponseHeaders(response, request.response);
      await request.response.addStream(response);
      await request.response.close();
    } on Object {
      unawaited(_abort(connection?.response));
      try {
        request.response.statusCode = HttpStatus.badGateway;
        await request.response.close();
      } on Object {
        return;
      }
    }
  }

  Future<_Connection> _connect(
    HttpRequest request,
    List<_Upstream> upstreams,
  ) async {
    final client = _client ??= (_httpClientFactory()
      ..autoUncompress = false
      ..connectionTimeout = _connectTimeout);
    Object failure = const HttpException('no upstream answered');
    for (final (index, upstream) in upstreams.indexed) {
      final last = index == upstreams.length - 1;
      try {
        final outgoing = await client.openUrl(request.method, upstream.uri);
        outgoing.followRedirects = true;
        _copyRequestHeaders(request, outgoing);
        final response = await outgoing.close();
        if (!last && _unusable(response.statusCode)) {
          unawaited(_abort(response));
          failure = HttpException(
            'HTTP ${response.statusCode} from ${upstream.uri.host}',
          );
          continue;
        }
        final base = upstream.base;
        if (index > 0 && base != null) _onEndpointSwitched?.call(base);
        return (base: base, uri: upstream.uri, response: response);
      } on Object catch (error) {
        failure = error;
      }
    }
    throw failure;
  }

  static bool _unusable(int status) =>
      status == HttpStatus.unauthorized ||
      status == HttpStatus.forbidden ||
      status == HttpStatus.badGateway ||
      status == HttpStatus.serviceUnavailable ||
      status == HttpStatus.gatewayTimeout;

  Future<void> _servePlaylist(
    HttpRequest request,
    HttpClientResponse upstream,
    Uri target,
    String? base,
  ) async {
    final body = await upstream.transform(utf8.decoder).join();
    final bytes = utf8.encode(_rewritePlaylist(body, target, base));

    request.response.statusCode = upstream.statusCode;
    _copyResponseHeaders(upstream, request.response);
    request.response.headers
      ..contentType =
          upstream.headers.contentType ??
          ContentType('application', 'vnd.apple.mpegurl')
      ..contentLength = bytes.length;
    request.response.add(bytes);
    await request.response.close();
  }

  String _rewritePlaylist(String body, Uri target, String? base) {
    final port = _server?.port;
    if (port == null) return body;

    String proxify(String reference) {
      final resolved = target.resolve(reference);
      final location = base == null ? null : serverLocationOf(resolved, base);
      if (location != null) return _loopback(port, location, 'l').toString();
      if (!_shouldProxy(resolved)) return reference;
      return _loopback(port, resolved, 'u').toString();
    }

    final out = StringBuffer();
    for (final line in const LineSplitter().convert(body)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        out.writeln(line);
      } else if (trimmed.startsWith('#')) {
        out.writeln(
          line.replaceAllMapped(
            _uriAttribute,
            (match) => 'URI="${proxify(match.group(1)!)}"',
          ),
        );
      } else {
        out.writeln(proxify(trimmed));
      }
    }
    return out.toString();
  }

  bool _isPlaylist(HttpClientResponse response, Uri target) {
    final mimeType = response.headers.contentType?.mimeType.toLowerCase() ?? '';
    if (mimeType.contains('mpegurl')) return true;
    return target.path.toLowerCase().endsWith('.m3u8');
  }

  void _copyRequestHeaders(HttpRequest from, HttpClientRequest to) {
    from.headers.forEach((name, values) {
      if (_hopByHopHeaders.contains(name.toLowerCase())) return;
      to.headers.removeAll(name);
      for (final value in values) {
        to.headers.add(name, value);
      }
    });
    to.contentLength = 0;
  }

  void _copyResponseHeaders(HttpClientResponse from, HttpResponse to) {
    from.headers.forEach((name, values) {
      if (_hopByHopHeaders.contains(name.toLowerCase())) return;
      to.headers.removeAll(name);
      for (final value in values) {
        to.headers.add(name, value);
      }
    });
    final length = from.headers.contentLength;
    if (length >= 0) to.headers.contentLength = length;
  }

  Future<void> _abort(HttpClientResponse? upstream) async {
    if (upstream == null) return;
    try {
      final socket = await upstream.detachSocket();
      socket.destroy();
    } on Object {
      return;
    }
  }

  static String _randomSecret() {
    final random = Random.secure();
    return [
      for (var i = 0; i < 16; i++)
        random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }
}
