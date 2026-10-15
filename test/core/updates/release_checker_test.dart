import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/updates/release_checker.dart';

Map<String, dynamic> release({
  String tag = 'v1.5.0',
  bool draft = false,
  bool prerelease = false,
}) => {
  'tag_name': tag,
  'draft': draft,
  'prerelease': prerelease,
  'html_url': 'https://github.com/avdept/JellyBoxPlayer/releases/tag/$tag',
  'assets': [
    {
      'name': 'jellybox-universal.apk',
      'browser_download_url': 'https://example.com/jellybox-universal.apk',
    },
    {
      'name': 'JellyBox-1.5.0.dmg',
      'browser_download_url': 'https://example.com/JellyBox-1.5.0.dmg',
    },
    {
      'name': 'windows-setup.exe',
      'browser_download_url': 'https://example.com/windows-setup.exe',
    },
  ],
};

AvailableUpdate? parse(
  Map<String, dynamic> data, {
  required DownloadPlatform platform,
  String current = '1.4.2',
}) => ReleaseChecker.parseRelease(
  data,
  currentVersion: current,
  platform: platform,
);

void main() {
  group('compareVersions', () {
    test('orders numerically, not lexically', () {
      expect(ReleaseChecker.compareVersions('1.10.0', '1.9.9'), greaterThan(0));
      expect(ReleaseChecker.compareVersions('1.4.2', '1.4.10'), lessThan(0));
    });

    test('ignores v prefix, build number and missing trailing parts', () {
      expect(ReleaseChecker.compareVersions('v1.4.0+250', '1.4'), 0);
      expect(ReleaseChecker.compareVersions('1.4.1', 'v1.4'), greaterThan(0));
    });
  });

  group('parseRelease', () {
    test('reports a newer release', () {
      final update = parse(release(), platform: DownloadPlatform.linux);
      expect(update?.version, '1.5.0');
    });

    test('ignores the same or an older release', () {
      expect(
        parse(release(tag: 'v1.4.2'), platform: DownloadPlatform.linux),
        isNull,
      );
      expect(
        parse(release(tag: 'v1.4.2+300'), platform: DownloadPlatform.linux),
        isNull,
      );
      expect(
        parse(release(tag: 'v1.3.9'), platform: DownloadPlatform.linux),
        isNull,
      );
    });

    test('ignores drafts and prereleases', () {
      expect(
        parse(release(draft: true), platform: DownloadPlatform.linux),
        isNull,
      );
      expect(
        parse(release(prerelease: true), platform: DownloadPlatform.linux),
        isNull,
      );
    });

    test('links the APK on Android and the DMG on macOS', () {
      expect(
        parse(release(), platform: DownloadPlatform.android)?.url.toString(),
        'https://example.com/jellybox-universal.apk',
      );
      expect(
        parse(release(), platform: DownloadPlatform.macos)?.url.toString(),
        'https://example.com/JellyBox-1.5.0.dmg',
      );
    });

    test('links the release page on Windows and Linux', () {
      const page =
          'https://github.com/avdept/JellyBoxPlayer/releases/tag/v1.5.0';
      expect(
        parse(release(), platform: DownloadPlatform.windows)?.url.toString(),
        page,
      );
      expect(
        parse(release(), platform: DownloadPlatform.linux)?.url.toString(),
        page,
      );
    });

    test('falls back to the release page when the asset is missing', () {
      final data = release()..['assets'] = <Object>[];
      expect(
        parse(data, platform: DownloadPlatform.android)?.url.toString(),
        'https://github.com/avdept/JellyBoxPlayer/releases/tag/v1.5.0',
      );
    });
  });
}
