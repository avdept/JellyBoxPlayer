import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/widgets/song_list_sliver.dart';

class SearchSongsSliver extends ConsumerWidget {
  const SearchSongsSliver({this.limit, super.key});

  final int? limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs =
        ref.watch(searchItemsProvider(ItemList.songs)).valueOrNull?.items ??
        const <LibraryItem>[];

    return SongListSliver(
      songs: songs,
      limit: limit,
      onItemUpdated: (updated) => ref
          .read(searchItemsProvider(ItemList.songs).notifier)
          .updateItem(updated),
    );
  }
}
