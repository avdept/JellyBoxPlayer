import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/services/image_service.dart';

void main() {
  group('ImageService.resize', () {
    test('- rewrites the jellyfin fill params', () {
      final uri = ImageService.resize(
        Uri.parse(
          'http://jelly.local/Items/a/Images/Primary'
          '?fillWidth=420&fillHeight=420&quality=96&tag=t1',
        ),
        1024,
      );

      expect(uri.queryParameters['fillWidth'], '1024');
      expect(uri.queryParameters['fillHeight'], '1024');
      expect(uri.queryParameters['quality'], '96');
      expect(uri.queryParameters['tag'], 't1');
    });

    test('- rewrites the emby max params', () {
      final uri = ImageService.resize(
        Uri.parse(
          'http://emby.local/Items/11/Images/Primary'
          '?MaxWidth=420&MaxHeight=420&Quality=96&Tag=t1',
        ),
        1024,
      );

      expect(uri.queryParameters['MaxWidth'], '1024');
      expect(uri.queryParameters['MaxHeight'], '1024');
      expect(uri.queryParameters['Quality'], '96');
      expect(uri.queryParameters['Tag'], 't1');
    });

    test('- does not add size params to a url that has none', () {
      final uri = ImageService.resize(
        Uri.parse('http://emby.local/Items/11/Images/Primary?Tag=t1'),
        1024,
      );

      expect(uri.queryParameters.keys, ['Tag']);
    });

    test('- leaves a url without a query untouched', () {
      final original = Uri.parse('http://emby.local/Items/11/Images/Primary');

      expect(ImageService.resize(original, 1024), original);
    });
  });
}
