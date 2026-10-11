import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';

Future<LibraryItem> rateItem(
  WidgetRef ref,
  LibraryItem item,
  int rating,
) async {
  await ref.read(mediaServerClientProvider).setRating(item.id, rating);
  return item.copyWith(userData: item.userData.copyWith(rating: rating));
}
