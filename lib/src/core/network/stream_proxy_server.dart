import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

class StreamProxyServer {
  StreamProxyServer({
    required bool Function(Uri uri) shouldProxy,
    HttpClient Function()? httpClientFactory,
  }) : _shouldProxy = shouldProxy,
       _httpClientFactory = httpClientFactory ?? HttpClient.new;

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
  final HttpClient Function() _httpClientFactory;
  final String _secret = _randomSecret();

  HttpClient? _client;
  HttpServer? _server;
  Future<HttpServer>? _starting;

  int? get port => _server?.port;

  Future<Uri> resolve(Uri uri) async {
    if (!_shouldProxy(uri)) return uri;
    final server = await _start();
    return _proxyUri(uri, server.port);
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

  Uri _proxyUri(Uri target, int port) {
    final name = target.pathSegments.isEmpty
        ? 'stream'
        : target.pathSegments.last;
    return Uri(
      scheme: 'http',
      host: InternetAddress.loopbackIPv4.address,
      port: port,
      pathSegments: [_secret, name],
      queryParameters: {'u': base64Url.encode(utf8.encode(target.toString()))},
    );
  }

  Uri? _targetOf(HttpRequest request) {
    final segments = request.uri.pathSegments;
    if (segments.isEmpty || segments.first != _secret) return null;
    final encoded = request.uri.queryParameters['u'];
    if (encoded == null) return null;
    try {
      final target = Uri.parse(utf8.decode(base64Url.decode(encoded)));
      return _shouldProxy(target) ? target : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> _handle(HttpRequest request) async {
    final target = _targetOf(request);
    if (target == null) {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close().catchError((_) {});
      return;
    }

    HttpClientResponse? upstream;
    try {
      final client = _client ??= (_httpClientFactory()..autoUncompress = false);
      final outgoing = await client.openUrl(request.method, target);
      outgoing.followRedirects = true;
      _copyRequestHeaders(request, outgoing);
      upstream = await outgoing.close();

      if (_isPlaylist(upstream, target)) {
        await _servePlaylist(request, upstream, target);
        return;
      }

      request.response.statusCode = upstream.statusCode;
      _copyResponseHeaders(upstream, request.response);
      await request.response.addStream(upstream);
      await request.response.close();
    } on Object {
      unawaited(_abort(upstream));
      try {
        request.response.statusCode = HttpStatus.badGateway;
        await request.response.close();
      } on Object {
        return;
      }
    }
  }

  Future<void> _servePlaylist(
    HttpRequest request,
    HttpClientResponse upstream,
    Uri target,
  ) async {
    final body = await upstream.transform(utf8.decoder).join();
    final bytes = utf8.encode(_rewritePlaylist(body, target));

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

  String _rewritePlaylist(String body, Uri base) {
    final port = _server?.port;
    if (port == null) return body;

    String proxify(String reference) {
      final resolved = base.resolve(reference);
      if (!_shouldProxy(resolved)) return reference;
      return _proxyUri(resolved, port).toString();
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
