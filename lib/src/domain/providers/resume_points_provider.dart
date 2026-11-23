import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/resume_point_database_provider.dart';
import 'package:jplayer/src/data/storages/resume_point_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/instant_mix_provider.dart';

final resumePointsChangedProvider = StateProvider<int>((ref) => 0);

class ResumePointsNotifier extends StateNotifier<List<ResumePoint>> {
  ResumePointsNotifier(
    this._database, {
    this.libraryId,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const []) {
    restored = reload();
  }

  final ResumePointDatabase _database;
  final String? libraryId;
  final DateTime Function() _now;

  late final Future<void> restored;

  Future<void> reload() async {
    final List<ResumePoint> stored;
    try {
      stored = await _database.recent(
        libraryId: libraryId,
        maxAge: resumePointMaxAge,
        now: _now,
      );
    } on Object {
      return;
    }
    if (mounted) state = stored;
  }
}

final resumePointsProvider =
    StateNotifierProvider<ResumePointsNotifier, List<ResumePoint>>((ref) {
      final notifier = ResumePointsNotifier(
        ref.watch(resumePointDatabaseProvider),
        libraryId: ref.watch(
          currentLibraryProvider.select((library) => library.valueOrNull?.id),
        ),
      );
      ref.listen(resumePointsChangedProvider, (_, _) => notifier.reload());
      return notifier;
    });

final jumpBackInProvider = Provider<List<ResumePoint>>((ref) {
  final mixes = {
    for (final mix in ref.watch(instantMixesProvider)) mix.item.id,
  };
  return [
    for (final point in ref.watch(resumePointsProvider))
      if (!isInstantMixId(point.item.id) || mixes.contains(point.item.id))
        point,
  ];
});

final ProviderFamily<ResumePoint?, String> resumePointProvider =
    Provider.family(
      (ref, sourceId) => ref.watch(
        resumePointsProvider.select(
          (points) => points.firstWhereOrNull((p) => p.item.id == sourceId),
        ),
      ),
    );
