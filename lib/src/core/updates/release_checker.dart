import 'package:dio/dio.dart';

class AvailableUpdate {
  const AvailableUpdate({required this.version, required this.url});

  final String version;
  final Uri url;
}

enum DownloadPlatform { android, macos, windows, linux }

class ReleaseChecker {
  ReleaseChecker({Dio? dio, this.repository = defaultRepository})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
              sendTimeout: _timeout,
              headers: {'Accept': 'application/vnd.github+json'},
            ),
          );

  static const defaultRepository = 'avdept/JellyBoxPlayer';
  static const _timeout = Duration(seconds: 20);

  final String repository;
  final Dio _dio;

  Future<AvailableUpdate?> check({
    required String currentVersion,
    required DownloadPlatform platform,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.github.com/repos/$repository/releases/latest',
    );
    return parseRelease(
      response.data,
      currentVersion: currentVersion,
      platform: platform,
    );
  }

  static AvailableUpdate? parseRelease(
    Map<String, dynamic>? data, {
    required String currentVersion,
    required DownloadPlatform platform,
  }) {
    if (data == null) return null;
    if (data['draft'] == true || data['prerelease'] == true) return null;
    final tag = data['tag_name'];
    if (tag is! String) return null;
    final latest = normalizeVersion(tag);
    if (compareVersions(latest, currentVersion) <= 0) return null;
    final page = _uri(data['html_url']);
    final url = _assetUrl(data['assets'], platform) ?? page;
    if (url == null) return null;
    return AvailableUpdate(version: latest, url: url);
  }

  static Uri? _assetUrl(Object? assets, DownloadPlatform platform) {
    final extension = switch (platform) {
      DownloadPlatform.android => '.apk',
      DownloadPlatform.macos => '.dmg',
      DownloadPlatform.windows || DownloadPlatform.linux => null,
    };
    if (extension == null || assets is! List) return null;
    for (final asset in assets) {
      if (asset is! Map) continue;
      final name = asset['name'];
      if (name is String && name.toLowerCase().endsWith(extension)) {
        return _uri(asset['browser_download_url']);
      }
    }
    return null;
  }

  static String normalizeVersion(String version) {
    var value = version.trim();
    if (value.startsWith('v') || value.startsWith('V')) {
      value = value.substring(1);
    }
    return value.split('+').first;
  }

  static int compareVersions(String a, String b) {
    final left = _parts(a);
    final right = _parts(b);
    final length = left.length > right.length ? left.length : right.length;
    for (var i = 0; i < length; i++) {
      final l = i < left.length ? left[i] : 0;
      final r = i < right.length ? right[i] : 0;
      if (l != r) return l.compareTo(r);
    }
    return 0;
  }

  static List<int> _parts(String version) => normalizeVersion(
    version,
  ).split('-').first.split('.').map((part) => int.tryParse(part) ?? 0).toList();

  static Uri? _uri(Object? value) {
    if (value is! String || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return null;
    return uri;
  }
}
