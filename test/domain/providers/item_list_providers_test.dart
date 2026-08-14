import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/core/exceptions/exceptions.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/item_list_providers.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../provider_container.dart';

class MockMediaServerClient extends Mock implements MediaServerClient {}

void main() {
  late MockMediaServerClient mockApi;

  ProviderContainer containerWith({required bool isOffline}) =>
      createProviderContainer(
        overrides: [
          mediaServerClientProvider.overrideWithValue(mockApi),
          currentUserProvider.overrideWith(
            (_) => const User(userId: 'user-1', token: 'token'),
          ),
          isOfflineProvider.overrideWithValue(isOffline),
        ],
      );

  setUp(() => mockApi = MockMediaServerClient());

  group('itemListProvider', () {
    test('- fails fast offline instead of waiting out the request', () async {
      final container = containerWith(isOffline: true);

      await expectLater(
        container.read(itemListProvider(ItemList.albums).future),
        throwsA(isA<OfflineException>()),
      );
      verifyZeroInteractions(mockApi);
    });

    test('- loadMore is a no-op while there is no page loaded', () async {
      final container = containerWith(isOffline: true);
      final notifier = container.read(
        itemListProvider(ItemList.albums).notifier,
      );

      await expectLater(
        container.read(itemListProvider(ItemList.albums).future),
        throwsA(isA<OfflineException>()),
      );
      await notifier.loadMore();

      verifyZeroInteractions(mockApi);
    });
  });
}
