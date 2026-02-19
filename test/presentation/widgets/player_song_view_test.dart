import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/services/download_service.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/download_service_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

class MockDownloadService extends Mock implements DownloadService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DownloadService mockDownloadService;

  final faker = Faker.instance;
  final mockSong = ItemDTO(
    id: faker.datatype.uuid(),
    name: faker.lorem.sentence(),
    runTimeTicks: faker.datatype.number(min: 10000),
    userData: UserData(
      playbackPositionTicks: faker.datatype.number(min: 1000),
      playCount: faker.datatype.number(),
      isFavorite: faker.datatype.boolean(),
      played: faker.datatype.boolean(),
    ),
    type: 'Song',
    albumArtist: faker.name.fullName(),
    albumName: faker.lorem.sentence(),
    albumId: faker.datatype.uuid(),
  );
  const keys = PlayerSongViewKeys(
    downloadedIcon: Key('downloadedIcon'),
    downloadProgressIndicator: Key('downloadProgressIndicator'),
  );

  Widget getWidgetUT({
    required ItemDTO song,
    required int position,
    bool isPlaying = false,
    bool isDownloaded = false,
  }) {
    return createTestApp(
      providerContainer: createProviderContainer(
        overrides: [
          downloadServiceProvider.overrideWith((_) => mockDownloadService),
          isSongDownloadedProvider.overrideWith((_, _) async => isDownloaded),
        ],
      ),
      home: Center(
        child: PlayerSongView(
          song: song,
          position: position,
          isPlaying: isPlaying,
          testKeys: keys,
        ),
      ),
    );
  }

  DownloadTask createDownloadTask({
    String? id,
    DownloadStatus status = DownloadStatus.pending,
    double progress = 0,
  }) {
    return DownloadTask(
        id: id ?? mockSong.id,
        name: faker.lorem.sentence(),
        url: faker.internet.url(),
        destination: '/downloads/${faker.lorem.word()}.mp3',
      )
      ..status.value = status
      ..progress.value = progress;
  }

  setUpAll(() {
    deviceId = faker.datatype.uuid();
  });

  setUp(() {
    mockDownloadService = MockDownloadService();
  });

  group('PlayerSongView', () {
    testWidgets(
      '- displays song details',
      (widgetTester) async {
        final position = faker.datatype.number(min: 1);
        await widgetTester.pumpWidget(
          getWidgetUT(song: mockSong, position: position),
        );
        await widgetTester.pump(Duration.zero);
        expect(find.text(position.toString()), findsOneWidget);
        expect(find.text(mockSong.name), findsOneWidget);
        if (mockSong.albumArtist != null) {
          expect(find.text(mockSong.albumArtist!), findsOneWidget);
        }
        expect(find.byKey(keys.downloadedIcon), findsNothing);
        expect(find.byKey(keys.downloadProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      '- displays downloaded state',
      (widgetTester) async {
        await widgetTester.pumpWidget(
          getWidgetUT(song: mockSong, position: 1, isDownloaded: true),
        );
        await widgetTester.pump(Duration.zero);
        expect(find.byKey(keys.downloadedIcon), findsOneWidget);
        expect(find.byKey(keys.downloadProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      '- displays downloading progress indicator',
      (widgetTester) async {
        final progress = faker.datatype.float(max: 1);
        final mockTask = createDownloadTask(
          status: DownloadStatus.downloading,
          progress: progress,
        );
        when(() => mockDownloadService.getTask(any())).thenReturn(mockTask);
        await widgetTester.pumpWidget(
          getWidgetUT(song: mockSong, position: 1),
        );
        await widgetTester.pump(Duration.zero);
        final downloadProgressFinder = find.byKey(
          keys.downloadProgressIndicator,
        );
        expect(downloadProgressFinder, findsOneWidget);
        expect(
          widgetTester.widget<ProgressIndicator>(downloadProgressFinder).value,
          equals(progress),
        );
        expect(find.byKey(keys.downloadedIcon), findsNothing);
      },
    );
  });
}
