import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/models/models.dart';

class FilterNotifier extends StateNotifier<Filter> {
  FilterNotifier() : super(const Filter(orderBy: EntityFilter.dateCreated, desc: true));

  void filter(EntityFilter field, bool desc) {
    state = Filter(orderBy: field, desc: desc);
  }
}

final filterProvider = StateNotifierProvider<FilterNotifier, Filter>((ref) => FilterNotifier());
